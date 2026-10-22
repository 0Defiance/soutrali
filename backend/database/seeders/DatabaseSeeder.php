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

        // Les données de démonstration ne sont chargées qu'en local :
        // aucun compte ni contenu fictif en préproduction ou en production.
        if (app()->environment('local')) {
            $this->call(DemoSeeder::class);
        }
    }
}
