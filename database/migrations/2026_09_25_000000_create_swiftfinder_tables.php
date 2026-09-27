<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('categories', function (Blueprint $table) {
            $table->id(); $table->string('name')->unique(); $table->string('slug')->unique();
            $table->boolean('is_active')->default(true); $table->timestamps();
        });
        Schema::create('items', function (Blueprint $table) {
            $table->id(); $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('category_id')->nullable()->constrained()->nullOnDelete();
            $table->enum('type', ['lost', 'found'])->index(); $table->string('title')->index();
            $table->text('description'); $table->text('identifying_details')->nullable();
            $table->string('location')->index(); $table->date('occurred_on')->index();
            $table->time('occurred_at')->nullable(); $table->string('contact_preference')->default('in_app');
            $table->string('status')->index(); $table->timestamps();
            $table->index(['type', 'status', 'created_at']);
        });
        Schema::create('item_images', function (Blueprint $table) {
            $table->id(); $table->foreignId('item_id')->constrained()->cascadeOnDelete();
            $table->string('path'); $table->unsignedSmallInteger('sort_order')->default(0); $table->timestamps();
        });
        Schema::create('favorites', function (Blueprint $table) {
            $table->id(); $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('item_id')->constrained()->cascadeOnDelete(); $table->timestamps();
            $table->unique(['user_id', 'item_id']);
        });
        Schema::create('claims', function (Blueprint $table) {
            $table->id(); $table->foreignId('item_id')->constrained()->cascadeOnDelete();
            $table->foreignId('claimant_id')->constrained('users')->cascadeOnDelete();
            $table->text('message'); $table->text('supporting_information')->nullable();
            $table->string('supporting_file_path')->nullable(); $table->string('status')->default('pending')->index(); $table->timestamps();
            $table->unique(['item_id', 'claimant_id']);
        });
    }
    public function down(): void { Schema::dropIfExists('claims'); Schema::dropIfExists('favorites'); Schema::dropIfExists('item_images'); Schema::dropIfExists('items'); Schema::dropIfExists('categories'); }
};
