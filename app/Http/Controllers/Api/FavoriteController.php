<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use App\Http\Resources\ItemResource;
use App\Models\Item;
use Illuminate\Http\Request;
class FavoriteController extends Controller {
    public function index(Request $request) { return response()->json(['success'=>true,'message'=>'Saved items retrieved.','data'=>ItemResource::collection($request->user()->favorites()->with(['user','category','images'])->latest()->paginate(20))]); }
    public function store(Request $request, Item $item) { $request->user()->favorites()->syncWithoutDetaching([$item->id]); return response()->json(['success'=>true,'message'=>'Saved.','data'=>null], 201); }
    public function destroy(Request $request, Item $item) { $request->user()->favorites()->detach($item->id); return response()->json(['success'=>true,'message'=>'Removed from saved items.','data'=>null]); }
}
