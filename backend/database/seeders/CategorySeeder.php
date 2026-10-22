<?php

namespace Database\Seeders;

use App\Models\Category;
use Illuminate\Database\Seeder;

class CategorySeeder extends Seeder
{
    /**
     * Catégories initiales validées par le porteur le 22 octobre 2026 (D-07).
     *
     * @var array<string, string>
     */
    public const NAMES = [
        'Réparations et dépannage' => 'Réparation d’objets, d’électroménager, de téléphones et petits dépannages.',
        'Maison et domestique' => 'Ménage, repassage, petite maintenance et coups de main à la maison.',
        'Couture, beauté et coiffure' => 'Couture, retouches, coiffure et services de mise en beauté.',
        'Éducation et cours' => 'Cours particuliers, soutien scolaire et aide à la formation.',
        'Informatique et numérique' => 'Dépannage informatique, installation, initiation et aide numérique.',
        'Transport léger et déménagement' => 'Transport d’objets, aide au déménagement et petites livraisons.',
        'Petites missions et coups de main' => 'Missions ponctuelles, courses, assistance et coups de main du quotidien.',
        'Autres' => 'Besoins et offres qui ne relèvent d’aucune autre catégorie.',
    ];

    public function run(): void
    {
        foreach (self::NAMES as $name => $description) {
            Category::firstOrCreate(
                ['name' => $name],
                ['description' => $description, 'active' => true],
            );
        }
    }
}
