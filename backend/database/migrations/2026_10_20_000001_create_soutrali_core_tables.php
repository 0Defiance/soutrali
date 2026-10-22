<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('communes', function (Blueprint $table) {
            $table->id();
            $table->string('name', 80)->unique();
            $table->boolean('active')->default(true)->index();
            $table->timestamps();
        });

        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('display_name', 80);
            $table->string('email')->nullable()->unique();
            $table->string('phone', 30)->nullable()->unique();
            $table->timestamp('email_verified_at')->nullable();
            $table->timestamp('phone_verified_at')->nullable();
            $table->string('password');
            $table->string('role', 24)->default('UTILISATEUR')->index();
            $table->string('status', 24)->default('ACTIF')->index();
            $table->foreignId('commune_id')->nullable()->constrained()->nullOnDelete();
            $table->text('presentation')->nullable();
            $table->rememberToken();
            $table->timestamps();
        });

        Schema::create('categories', function (Blueprint $table) {
            $table->id();
            $table->string('name', 100)->unique();
            $table->text('description')->nullable();
            $table->boolean('active')->default(true)->index();
            $table->timestamps();
        });

        Schema::create('listings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->restrictOnDelete();
            $table->foreignId('category_id')->constrained()->restrictOnDelete();
            $table->foreignId('commune_id')->constrained()->restrictOnDelete();
            $table->string('title', 140);
            $table->text('description');
            $table->string('type', 16)->index();
            $table->string('nature', 16)->index();
            $table->string('neighborhood', 100)->nullable();
            $table->string('availability', 160)->nullable();
            $table->decimal('budget', 12, 2)->nullable();
            $table->string('status', 20)->default('BROUILLON')->index();
            $table->string('closure_outcome', 24)->nullable();
            $table->timestamps();
            $table->index(['status', 'commune_id', 'created_at']);
            $table->index(['status', 'category_id', 'type', 'nature']);
        });

        Schema::create('sessions', function (Blueprint $table) {
            $table->string('id')->primary();
            $table->foreignId('user_id')->nullable()->index();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->longText('payload');
            $table->unsignedInteger('last_activity')->index();
        });

        Schema::create('personal_access_tokens', function (Blueprint $table) {
            $table->id();
            $table->morphs('tokenable');
            $table->text('name');
            $table->string('token', 64)->unique();
            $table->text('abilities')->nullable();
            $table->timestamp('last_used_at')->nullable();
            $table->timestamp('expires_at')->nullable()->index();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('personal_access_tokens');
        Schema::dropIfExists('sessions');
        Schema::dropIfExists('listings');
        Schema::dropIfExists('categories');
        Schema::dropIfExists('users');
        Schema::dropIfExists('communes');
    }
};