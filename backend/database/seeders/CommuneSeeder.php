<?php

namespace Database\Seeders;

use App\Models\Commune;
use Illuminate\Database\Seeder;

class CommuneSeeder extends Seeder
{
    /**
     * Communes d'Abidjan validées par le porteur le 22 octobre 2026 (D-03),
     * plus la zone « Plusieurs communes » prévue par le cadrage.
     *
     * @var list<string>
     */
    public const NAMES = [
        'Abobo',
        'Adjamé',
        'Anyama',
        'Attécoubé',
        'Bingerville',
        'Cocody',
        'Koumassi',
        'Marcory',
        'Plateau',
        'Port-Bouët',
        'Plusieurs communes',
        'Songon',
        'Treichville',
        'Yopougon',
    ];

    public function run(): void
    {
        foreach (self::NAMES as $name) {
            Commune::firstOrCreate(['name' => $name], ['active' => true]);
        }
    }
}
