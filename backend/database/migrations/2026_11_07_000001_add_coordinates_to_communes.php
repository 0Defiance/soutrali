<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Coordonnées du centre de chaque commune (7 nov. 2026) : elles servent
     * à situer une position GPS sur le référentiel d’Abidjan et à trier les
     * annonces par distance réelle (« Annonces près de vous »).
     *
     * Nullable : la zone « Plusieurs communes » n’a pas de centre, et une
     * commune ajoutée par le back-office peut rester sans coordonnées.
     */
    public function up(): void
    {
        Schema::table('communes', function (Blueprint $table) {
            $table->decimal('latitude', 10, 7)->nullable()->after('name');
            $table->decimal('longitude', 10, 7)->nullable()->after('latitude');
        });
    }

    public function down(): void
    {
        Schema::table('communes', function (Blueprint $table) {
            $table->dropColumn(['latitude', 'longitude']);
        });
    }
};
