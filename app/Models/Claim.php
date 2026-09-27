<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class Claim extends Model { protected $fillable = ['message','supporting_information','supporting_file_path','status']; public function item() { return $this->belongsTo(Item::class); } public function claimant() { return $this->belongsTo(User::class, 'claimant_id'); } }
