<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Clé d'icône du service (26 oct. 2026) : chaque catégorie porte une
     * clé lisible par l'application, qui la traduit en icône de charte.
     * Les catégories existantes prennent la valeur par défaut, puis le
     * CategorySeeder applique l'icône correspondante.
     */
    public function up(): void
    {
        Schema::table('categories', function (Blueprint $table) {
            $table->string('icon', 40)->default('misc')->after('description');
        });
    }

    public function down(): void
    {
        Schema::table('categories', function (Blueprint $table) {
            $table->dropColumn('icon');
        });
    }
};
