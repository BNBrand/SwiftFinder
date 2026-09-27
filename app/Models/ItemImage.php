<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class ItemImage extends Model { protected $fillable = ['path','sort_order']; public function item() { return $this->belongsTo(Item::class); } }
