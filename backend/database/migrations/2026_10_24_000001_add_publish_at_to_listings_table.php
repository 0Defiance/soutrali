<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('listings', function (Blueprint $table) {
            // Publication programmée : annonce créée en BROUILLON avec une
            // date de mise en ligne future (voir `soutrali:publish-due`).
            $table->timestamp('publish_at')->nullable()->after('status');
        });
    }

    public function down(): void
    {
        Schema::table('listings', function (Blueprint $table) {
            $table->dropColumn('publish_at');
        });
    }
};
