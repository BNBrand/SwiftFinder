<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
class Item extends Model {
    protected $fillable = ['category_id','type','title','description','identifying_details','location','occurred_on','occurred_at','contact_preference','status'];
    protected function casts(): array { return ['occurred_on' => 'date']; }
    public function user(): BelongsTo { return $this->belongsTo(User::class); }
    public function category(): BelongsTo { return $this->belongsTo(Category::class); }
    public function images(): HasMany { return $this->hasMany(ItemImage::class); }
    public function claims(): HasMany { return $this->hasMany(Claim::class); }
    public function favoritedBy() { return $this->belongsToMany(User::class, 'favorites')->withTimestamps(); }
    public function conversations() { return $this->hasMany(Conversation::class); }
    public function reports() { return $this->morphMany(Report::class, 'reportable'); }
}
