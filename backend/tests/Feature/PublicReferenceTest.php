<?php

use App\Models\Category;
use App\Models\Commune;
use Database\Seeders\CategorySeeder;
use Database\Seeders\CommuneSeeder;
use Database\Seeders\DemoSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

uses(TestCase::class, RefreshDatabase::class);

it('serves the categories seeded by the validated referential', function () {
    $this->seed(CategorySeeder::class);

    $response = $this->getJson('/api/v1/categories');

    $response->assertOk()
        ->assertJsonCount(count(CategorySeeder::NAMES), 'data')
        ->assertJsonStructure(['data' => [['id', 'name', 'description', 'icon']]]);

    $names = collect($response->json('data'))->pluck('name')->all();

    expect($names)->toContain('Réparations et dépannage', 'Autres')
        ->and($names)->toHaveCount(count(CategorySeeder::NAMES));
});

it('serves an icon key known by the application for every service', function () {
    $this->seed(CategorySeeder::class);

    $response = $this->getJson('/api/v1/categories');

    $response->assertOk()->assertJsonStructure(['data' => [['id', 'name', 'icon']]]);

    foreach ($response->json('data') as $category) {
        expect($category['icon'])->toBeString()
            ->and($category['icon'])->not->toBe('')
            ->and(array_key_exists($category['icon'], Category::ICONS))->toBeTrue(
                "Icône inconnue {$category['icon']} pour {$category['name']}",
            );
    }

    // Les services ajoutés le 26 octobre sont bien en base, avec leur icône.
    $icons = collect($response->json('data'))->pluck('icon', 'name');

    expect($icons['Plomberie et sanitaire'])->toBe('plumbing')
        ->and($icons['Garde d’enfants'])->toBe('childcare')
        ->and($icons['Agriculture et élevage'])->toBe('agriculture');
});

it('serves only active categories', function () {
    $this->seed(CategorySeeder::class);
    Category::where('name', 'Autres')->update(['active' => false]);

    $response = $this->getJson('/api/v1/categories');

    $response->assertOk()
        ->assertJsonCount(count(CategorySeeder::NAMES) - 1, 'data');

    $names = collect($response->json('data'))->pluck('name')->all();

    expect($names)->not->toContain('Autres');
});

it('serves the communes of the validated referential', function () {
    $this->seed(CommuneSeeder::class);

    $response = $this->getJson('/api/v1/communes');

    $response->assertOk()
        ->assertJsonCount(count(CommuneSeeder::NAMES), 'data')
        ->assertJsonStructure(['data' => [['id', 'name']]]);

    $names = collect($response->json('data'))->pluck('name')->all();

    expect($names)->toContain('Yopougon', 'Abobo', 'Plusieurs communes');
});

it('publishes demo listings to visitors without any private coordinate', function () {
    $this->seed([CommuneSeeder::class, CategorySeeder::class, DemoSeeder::class]);

    $response = $this->getJson('/api/v1/listings');

    $response->assertOk();

    $rows = $response->json('data');

    expect($rows)->not->toBeEmpty();

    foreach ($rows as $row) {
        expect($row)->not->toHaveKey('email')
            ->and($row)->not->toHaveKey('phone')
            ->and($row)->not->toHaveKey('user_id');
    }
});

it('filters demo listings by commune, category and nature', function () {
    $this->seed([CommuneSeeder::class, CategorySeeder::class, DemoSeeder::class]);

    $yopougon = Commune::where('name', 'Yopougon')->value('id');
    $category = Category::where('name', 'Maison et domestique')->value('id');

    $byCommune = $this->getJson('/api/v1/listings?commune=Yopougon')->assertOk()->json('data');
    expect($byCommune)->toHaveCount(4);

    $byCategory = $this->getJson('/api/v1/listings?category='.$category)->assertOk()->json('data');
    expect($byCategory)->toHaveCount(1)
        ->and($byCategory[0]['title'])->toBe('Ménage et repassage ponctuels');

    $byNature = $this->getJson('/api/v1/listings?nature=BENEVOLE')->assertOk()->json('data');
    expect($byNature)->toHaveCount(6);

    expect($yopougon)->not->toBeNull();
});
