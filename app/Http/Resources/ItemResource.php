<?php
namespace App\Http\Resources;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
class ItemResource extends JsonResource {
    public function toArray(Request $request): array { return [
        'id' => $this->id, 'type' => $this->type, 'title' => $this->title, 'description' => $this->description,
        'identifying_details' => $this->when($request->user()?->id === $this->user_id, $this->identifying_details),
        'location' => $this->location, 'occurred_on' => $this->occurred_on?->toDateString(), 'occurred_at' => $this->occurred_at ? substr((string)$this->occurred_at,0,5) : null, 'status' => $this->status,
        'contact_preference' => $this->contact_preference, 'category' => $this->category?->only(['id','name','slug']),
        'poster' => $this->user ? ['id'=>$this->user->id,'name'=>$this->user->name,'photo_path'=>$this->user->photo_path,'photo_url'=>$this->user->photo_url] : null, 'images' => $this->images->map(fn ($image) => ['id' => $image->id, 'url' => asset('storage/'.$image->path)]),
        'is_favorited' => (bool) ($this->is_favorited ?? false), 'created_at' => $this->created_at?->toISOString(),
    ]; }
}
