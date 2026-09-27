<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Str;
class AuthController extends Controller {
    public function register(Request $request) { $data = $request->validate(['name'=>'required|string|max:120','email'=>'required|email|unique:users','password'=>'required|string|min:8|confirmed','phone'=>'nullable|string|max:30']); $user = User::create($data); return $this->respond(['user'=>$user,'token'=>$user->createToken('flutter')->plainTextToken], 'Account created.', 201); }
    public function login(Request $request) { $data = $request->validate(['email'=>'required|email','password'=>'required']); $user = User::where('email',$data['email'])->first(); if (!$user || !Hash::check($data['password'],$user->password) || $user->is_suspended) return $this->respond(null, 'Invalid credentials.', 422, false); return $this->respond(['user'=>$user,'token'=>$user->createToken('flutter')->plainTextToken], 'Welcome back.'); }

    public function forgotPassword(Request $request) {
        $data=$request->validate(['email'=>'required|email']);
        $status=Password::sendResetLink(['email'=>$data['email']]);
        return $this->respond(null, 'If that email exists, a password reset link has been sent.');
    }

    public function resetPassword(Request $request) {
        $data=$request->validate(['email'=>'required|email','token'=>'required','password'=>'required|string|min:8|confirmed']);
        $status=Password::reset($data, function($user,$password){ $user->forceFill(['password'=>$password,'remember_token'=>Str::random(60)])->save(); $user->tokens()->delete(); });
        if($status!==Password::PASSWORD_RESET) return $this->respond(null, 'The password reset token is invalid or expired.', 422, false);
        return $this->respond(null, 'Password reset successfully.');
    }

    public function me(Request $request) { return $this->respond($request->user()); }
    public function logout(Request $request) { $request->user()->currentAccessToken()->delete(); return $this->respond(null, 'Signed out.'); }
    private function respond($data, string $message = 'OK', int $status = 200, bool $success = true) { return response()->json(compact('success','message','data'), $status); }
}
