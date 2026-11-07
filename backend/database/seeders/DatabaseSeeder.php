<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $this->call([
            CommuneSeeder::class,
            CategorySeeder::class,
        ]);

        // Les données de démonstration ne sont chargées qu'en local.
        if (app()->environment('local')) {
            $this->call(DemoSeeder::class);
        }

        // Vitrine : au moins une annonce visible par service, en local
        // comme en ligne (7 nov. 2026). Rejouable, ne touche jamais aux
        // annonces existantes.
        $this->call(ShowcaseSeeder::class);
    }
}
