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

    /**
     * Centres des communes (7 nov. 2026), en degrés décimaux. Ils servent au
     * tri « Annonces près de vous » et à la confirmation de position. La
     * zone « Plusieurs communes » n'a volontairement pas de centre.
     *
     * @var array<string, array{0: float, 1: float}>
     */
    public const COORDINATES = [
        'Abobo' => [5.4161, -4.0159],
        'Adjamé' => [5.3599, -4.0244],
        'Anyama' => [5.4944, -4.0522],
        'Attécoubé' => [5.3336, -4.0370],
        'Bingerville' => [5.3556, -3.8853],
        'Cocody' => [5.3540, -3.9610],
        'Koumassi' => [5.2952, -3.9509],
        'Marcory' => [5.3010, -3.9870],
        'Plateau' => [5.3240, -4.0190],
        'Port-Bouët' => [5.2530, -3.9300],
        'Songon' => [5.3120, -4.2520],
        'Treichville' => [5.2930, -4.0110],
        'Yopougon' => [5.3390, -4.0730],
    ];

    public function run(): void
    {
        foreach (self::NAMES as $name) {
            [$latitude, $longitude] = self::COORDINATES[$name] ?? [null, null];

            Commune::updateOrCreate(
                ['name' => $name],
                ['active' => true, 'latitude' => $latitude, 'longitude' => $longitude],
            );
        }
    }
}
