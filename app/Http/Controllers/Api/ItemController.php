<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use App\Http\Requests\StoreItemRequest;
use App\Http\Resources\ItemResource;
use App\Models\Item;
use App\Services\ItemMatchingService;
use Illuminate\Http\Request;
use App\Notifications\SwiftFinderNotification;
class ItemController extends Controller {
    public function mine(Request $request) { return $this->respond(ItemResource::collection($request->user()->items()->with(['user','category','images'])->latest()->paginate(20)), 'Your reports retrieved.'); }
    public function index(Request $request) { $items = Item::with(['user','category','images'])->withExists(['favoritedBy as is_favorited' => fn ($q) => $q->whereKey($request->user()?->id)])->when($request->type, fn($q,$v)=>$q->where('type',$v))->when($request->category_id, fn($q,$v)=>$q->where('category_id',$v))->when($request->location, fn($q,$v)=>$q->where('location','like',"%$v%"))->when($request->q, fn($q,$v)=>$q->where(fn($x)=>$x->where('title','like',"%$v%")->orWhere('description','like',"%$v%")))->latest()->paginate(12); return $this->respond(ItemResource::collection($items), 'Items retrieved.'); }
    public function store(StoreItemRequest $request, ItemMatchingService $matching) { $data = $request->safe()->except('images'); $data['status'] = $data['type'] === 'lost' ? 'active' : 'available'; $item = $request->user()->items()->create($data);
        foreach ($matching->for($item) as $match) { if ($match->user_id !== $item->user_id) $match->user->notify(new SwiftFinderNotification('potential_match','Potential match found','Your report “'.$match->title.'” may match a new SwiftFinder report.',['item_id'=>$match->id,'match_id'=>$item->id])); }
        foreach($request->file('images',[]) as $i=>$image) $item->images()->create(['path'=>$image->store('items','public'),'sort_order'=>$i]); return $this->respond(new ItemResource($item->load(['user','category','images'])), 'Report published.', 201); }
    public function show(Request $request, Item $item) { return $this->respond(new ItemResource($item->load(['user','category','images']))); }
    public function update(StoreItemRequest $request, Item $item) { abort_unless($item->user_id === $request->user()->id, 403); $item->update($request->safe()->except('images','type')); foreach($request->file('images',[]) as $i=>$image) $item->images()->create(['path'=>$image->store('items','public'),'sort_order'=>$item->images()->count()+$i]); return $this->respond(new ItemResource($item->fresh()->load(['user','category','images'])), 'Report updated.'); }
    public function destroy(Request $request, Item $item) { abort_unless($item->user_id === $request->user()->id, 403); $item->delete(); return $this->respond(null, 'Report deleted.'); }
    public function changeStatus(Request $request, Item $item) { abort_unless($item->user_id === $request->user()->id, 403); $status=$request->validate(['status'=>'required|in:active,found,closed,available,returned'])['status']; $allowed=$item->type==='lost'?['active','found','closed']:['available','returned','closed']; abort_unless(in_array($status,$allowed),422,'Invalid status for item type.'); $item->update(compact('status')); return $this->respond(new ItemResource($item->fresh()->load(['user','category','images'])),'Status updated.'); }
    public function matches(Request $request, Item $item, ItemMatchingService $matching) { return $this->respond(ItemResource::collection($matching->for($item)->load(['user','category','images'])), 'Potential matches retrieved.'); }
    private function respond($data, string $message = 'OK', int $status = 200) { return response()->json(['success'=>true,'message'=>$message,'data'=>$data], $status); }
}
