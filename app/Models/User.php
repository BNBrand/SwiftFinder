<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'phone',
        'photo_path',
        'role',
        'is_suspended',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    protected $appends = ['photo_url'];

    public function getPhotoUrlAttribute(): ?string
    {
        return $this->photo_path ? asset('storage/'.$this->photo_path) : null;
    }

    public function items() { return $this->hasMany(Item::class); }
    public function favorites() { return $this->belongsToMany(Item::class, 'favorites')->withTimestamps(); }
    public function startedConversations() { return $this->hasMany(Conversation::class, 'starter_id'); }
    public function receivedConversations() { return $this->hasMany(Conversation::class, 'recipient_id'); }
    public function reports() { return $this->morphMany(Report::class, 'reportable'); }
    public function blockedUsers() { return $this->belongsToMany(User::class, 'user_blocks', 'user_id', 'blocked_user_id')->withTimestamps(); }
}
