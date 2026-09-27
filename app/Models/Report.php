<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class Report extends Model { protected $fillable=['reason','details','status','resolved_by','resolved_at']; protected function casts():array{return['resolved_at'=>'datetime'];} public function reporter(){return $this->belongsTo(User::class,'reporter_id');} public function reportable(){return $this->morphTo();} }
