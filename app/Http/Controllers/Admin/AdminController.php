<?php
namespace App\Http\Controllers\Admin;
use App\Http\Controllers\Controller;
use App\Models\Category; use App\Models\Claim; use App\Models\Item; use App\Models\Report; use App\Models\User; use Illuminate\Http\Request; use Illuminate\Support\Facades\Auth;
class AdminController extends Controller {
  public function loginForm(){return view('admin.login');}
  public function login(Request $r){$data=$r->validate(['email'=>'required|email','password'=>'required']);if(!Auth::attempt($data,$r->boolean('remember'))||Auth::user()->role!=='admin'){Auth::logout();return back()->withErrors(['email'=>'Invalid administrator credentials.'])->onlyInput('email');}$r->session()->regenerate();return redirect()->route('admin.dashboard');}
  public function logout(Request $r){Auth::logout();$r->session()->invalidate();$r->session()->regenerateToken();return redirect()->route('admin.login');}
  public function dashboard(){return view('admin.dashboard',['users'=>User::count(),'lost'=>Item::where('type','lost')->where('status','active')->count(),'found'=>Item::where('type','found')->where('status','available')->count(),'recoveries'=>Item::whereIn('status',['found','returned'])->count(),'claims'=>Claim::where('status','pending')->count(),'reports'=>Report::where('status','pending')->count(),'recent'=>Item::with('user')->latest()->take(8)->get()]);}
  public function users(Request $r){return view('admin.users.index',['users'=>User::when($r->q,fn($q,$v)=>$q->where(fn($x)=>$x->where('name','like',"%$v%")->orWhere('email','like',"%$v%")))->latest()->paginate(20)]);}
  public function suspend(User $user){abort_if($user->role==='admin',422);$user->update(['is_suspended'=>!$user->is_suspended]);return back()->with('success','User status updated.');}
  public function items(Request $r){return view('admin.items.index',['items'=>Item::with(['user','category'])->when($r->type,fn($q,$v)=>$q->where('type',$v))->when($r->status,fn($q,$v)=>$q->where('status',$v))->latest()->paginate(20)]);}
  public function updateItem(Request $r,Item $item){$data=$r->validate(['status'=>'required|string|max:30']);$item->update($data);return back()->with('success','Listing status updated.');}
  public function claims(Request $r){return view('admin.claims',['claims'=>Claim::with(['item','claimant'])->when($r->status,fn($q,$v)=>$q->where('status',$v))->latest()->paginate(20)->withQueryString()]);}
  public function updateClaim(Request $r, Claim $claim){$status=$r->validate(['status'=>'required|in:accepted,rejected,cancelled'])['status']; if($claim->status!=='pending') return back()->withErrors(['claim'=>'This claim has already been reviewed.']); $claim->update(['status'=>$status]); if($status==='accepted') $claim->item->update(['status'=>$claim->item->type==='lost'?'found':'returned']); return back()->with('success','Claim reviewed.');}
  public function reports(){return view('admin.reports',['reports'=>Report::with(['reporter','reportable'])->latest()->paginate(20)]);}
  public function resolveReport(Request $r,Report $report){$report->update(['status'=>$r->validate(['status'=>'required|in:resolved,dismissed'])['status'],'resolved_by'=>Auth::id(),'resolved_at'=>now()]);return back()->with('success','Report reviewed.');}
  public function categories(){return view('admin.categories.index',['categories'=>Category::orderBy('name')->get()]);}
  public function saveCategory(Request $r,Category $category=null){$data=$r->validate(['name'=>'required|string|max:80','is_active'=>'nullable|boolean']);$data['slug']=str($data['name'])->slug();$data['is_active']=$r->boolean('is_active');($category??new Category)->fill($data)->save();return back()->with('success','Category saved.');}
}
