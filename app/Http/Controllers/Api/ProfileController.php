<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;

class ProfileController extends Controller
{
    public function show(Request $request)
    {
        $user = $request->user();
        return $this->ok($this->profileData($user), 'Profile retrieved.');
    }

    public function update(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:120',
            'phone' => 'nullable|string|max:30',
        ]);
        $request->user()->update($data);
        return $this->ok($this->profileData($request->user()->fresh()), 'Profile updated.');
    }


    public function photo(Request $request)
    {
        $request->validate(['photo' => 'required|image|max:5120']);
        $user = $request->user();
        $oldPath = $user->photo_path;
        $newPath = $request->file('photo')->store('profiles', 'public');

        abort_if($newPath === false, 500, 'The profile photo could not be saved. Check Laravel storage permissions.');

        $user->update(['photo_path' => $newPath]);
        if ($oldPath) {
            Storage::disk('public')->delete($oldPath);
        }

        return $this->ok($this->profileData($user->fresh()), 'Profile photo updated.');
    }

    public function password(Request $request)
    {
        $data = $request->validate([
            'current_password' => 'required',
            'password' => 'required|string|min:8|confirmed',
        ]);
        abort_unless(Hash::check($data['current_password'], $request->user()->password), 422, 'Current password is incorrect.');
        $request->user()->update(['password' => $data['password']]);
        $request->user()->tokens()->delete();
        return $this->ok(null, 'Password changed. Sign in again.');
    }

    public function destroy(Request $request)
    {
        $request->validate(['password' => 'required']);
        abort_unless(Hash::check($request->password, $request->user()->password), 422, 'Password is incorrect.');
        $request->user()->tokens()->delete();
        $request->user()->delete();
        return $this->ok(null, 'Account deleted.');
    }

    private function profileData($user): array
    {
        return [
            'user' => $user,
            'active_listings' => $user->items()->whereIn('status', ['active', 'available'])->count(),
            'successful_returns' => $user->items()->whereIn('status', ['found', 'returned'])->count(),
        ];
    }

    private function ok($data, string $message, int $status = 200)
    {
        return response()->json(['success' => true, 'message' => $message, 'data' => $data], $status);
    }
}
