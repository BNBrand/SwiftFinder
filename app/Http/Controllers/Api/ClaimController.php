<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use App\Models\Claim;
use App\Models\Item;
use App\Http\Resources\ItemResource;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use App\Notifications\SwiftFinderNotification;
class ClaimController extends Controller {
    public function mine(Request $request) { $claims=Claim::where('claimant_id', $request->user()->id)->with(['item.user','item.category','item.images'])->latest()->get()->map(fn($claim)=>['id'=>$claim->id,'item_id'=>$claim->item_id,'message'=>$claim->message,'supporting_information'=>$claim->supporting_information,'status'=>$claim->status,'supporting_file_url'=>$claim->supporting_file_path?asset('storage/'.$claim->supporting_file_path):null,'created_at'=>$claim->created_at?->toISOString(),'claimant'=>$claim->claimant?->only(['id','name','email','phone','photo_path']),'item'=>ItemResource::make($claim->item)->resolve($request)]); return $this->respond($claims, 'Your claims retrieved.'); }
    public function store(Request $request, Item $item) {
        $userId = $request->user()->id;

        abort_if($item->user_id === $userId, 422, 'You cannot claim your own report.');
        abort_if(in_array($item->status, ['found', 'returned', 'closed'], true), 422, 'This report is no longer accepting claims.');
        abort_if($item->claims()->where('claimant_id', $userId)->exists(), 422, 'You have already submitted a claim for this report.');

        $data = $request->validate([
            'message' => 'required|string|max:3000',
            'supporting_information' => 'nullable|string|max:3000',
            'supporting_file' => 'nullable|file|mimes:jpg,jpeg,png,pdf,doc,docx|max:10240',
        ]);

        if ($request->hasFile('supporting_file')) {
            $data['supporting_file_path'] = $request->file('supporting_file')->store('claims', 'public');
        }

        unset($data['supporting_file']);
        $claim = $item->claims()->create($data + ['claimant_id' => $userId]);

        try {
            $item->user->notify(new SwiftFinderNotification(
                'claim_submitted',
                'New claim on your report',
                $request->user()->name.' submitted a claim on “'.$item->title.'”.',
                ['item_id' => $item->id, 'claim_id' => $claim->id],
            ));
        } catch (\Throwable $e) {
            report($e);
        }

        return $this->respond($claim, 'Claim submitted.', 201);
    }
    public function index(Request $request, Item $item) { abort_unless($item->user_id === $request->user()->id,403); return $this->respond($item->claims()->with('claimant:id,name,photo_path')->latest()->get()); }
    public function review(Request $request, Claim $claim) { abort_unless($claim->item->user_id === $request->user()->id,403); $data=$request->validate(['status'=>'required|in:accepted,rejected']); abort_unless($claim->status === 'pending',422,'Claim has already been reviewed.'); $claim->update($data); if ($data['status']==='accepted') $claim->item->update(['status'=>$claim->item->type==='lost'?'found':'returned']);
        $claim->claimant->notify(new SwiftFinderNotification('claim_'.$data['status'],'Claim '.$data['status'],$claim->item->title.' claim was '.$data['status'].'.',['item_id'=>$claim->item_id,'claim_id'=>$claim->id]));
        return $this->respond($claim->fresh(), 'Claim '.$data['status'].'.'); }
    private function respond($data,string $message,int $status=200) { return response()->json(['success'=>true,'message'=>$message,'data'=>$data],$status); }
}
