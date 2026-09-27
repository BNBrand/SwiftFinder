<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class Conversation extends Model { protected $fillable=['item_id','starter_id','recipient_id']; public function item(){return $this->belongsTo(Item::class);} public function starter(){return $this->belongsTo(User::class,'starter_id');} public function recipient(){return $this->belongsTo(User::class,'recipient_id');} public function messages(){return $this->hasMany(Message::class);} }
