<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('contact_channels', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('type', 24);
            $table->string('value', 190);
            $table->boolean('visible_to_members')->default(false);
            $table->timestamps();
            $table->unique(['user_id', 'type']);
        });

        Schema::create('user_blocks', function (Blueprint $table) {
            $table->id();
            $table->foreignId('blocker_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('blocked_id')->constrained('users')->cascadeOnDelete();
            $table->timestamps();
            $table->unique(['blocker_id', 'blocked_id']);
            $table->index(['blocked_id', 'blocker_id']);
        });

        Schema::create('interactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('listing_id')->constrained()->restrictOnDelete();
            $table->foreignId('initiator_id')->constrained('users')->restrictOnDelete();
            $table->string('status', 20)->default('OUVERTE')->index();
            $table->timestamps();
            $table->unique(['listing_id', 'initiator_id']);
        });

        Schema::create('reports', function (Blueprint $table) {
            $table->id();
            $table->foreignId('listing_id')->constrained()->restrictOnDelete();
            $table->foreignId('reporter_id')->constrained('users')->restrictOnDelete();
            $table->string('reason', 60);
            $table->text('details')->nullable();
            $table->string('status', 24)->default('NOUVEAU')->index();
            $table->timestamps();
        });

        Schema::create('moderation_actions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('report_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('moderator_id')->constrained('users')->restrictOnDelete();
            $table->string('decision', 40);
            $table->text('justification')->nullable();
            $table->timestamp('acted_at')->useCurrent();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('moderation_actions');
        Schema::dropIfExists('reports');
        Schema::dropIfExists('interactions');
        Schema::dropIfExists('user_blocks');
        Schema::dropIfExists('contact_channels');
    }
};
