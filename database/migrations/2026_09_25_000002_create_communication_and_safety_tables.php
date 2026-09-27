<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
  public function up(): void {
    Schema::create('conversations', function(Blueprint $t){$t->id();$t->foreignId('item_id')->nullable()->constrained()->nullOnDelete();$t->foreignId('starter_id')->constrained('users')->cascadeOnDelete();$t->foreignId('recipient_id')->constrained('users')->cascadeOnDelete();$t->timestamps();$t->unique(['item_id','starter_id','recipient_id']);});
    Schema::create('messages', function(Blueprint $t){$t->id();$t->foreignId('conversation_id')->constrained()->cascadeOnDelete();$t->foreignId('sender_id')->constrained('users')->cascadeOnDelete();$t->text('body');$t->timestamp('read_at')->nullable();$t->softDeletes();$t->timestamps();});
    Schema::create('notifications', function(Blueprint $t){$t->uuid('id')->primary();$t->string('type');$t->morphs('notifiable');$t->text('data');$t->timestamp('read_at')->nullable();$t->timestamps();});
    Schema::create('reports', function(Blueprint $t){$t->id();$t->foreignId('reporter_id')->constrained('users')->cascadeOnDelete();$t->morphs('reportable');$t->string('reason');$t->text('details')->nullable();$t->string('status')->default('pending')->index();$t->foreignId('resolved_by')->nullable()->constrained('users')->nullOnDelete();$t->timestamp('resolved_at')->nullable();$t->timestamps();$t->unique(['reporter_id','reportable_type','reportable_id']);});
    Schema::create('user_blocks', function(Blueprint $t){$t->id();$t->foreignId('user_id')->constrained()->cascadeOnDelete();$t->foreignId('blocked_user_id')->constrained('users')->cascadeOnDelete();$t->timestamps();$t->unique(['user_id','blocked_user_id']);});
  }
  public function down(): void {Schema::dropIfExists('user_blocks');Schema::dropIfExists('reports');Schema::dropIfExists('notifications');Schema::dropIfExists('messages');Schema::dropIfExists('conversations');}
};
