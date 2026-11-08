<?php

use App\Models\Listing;
use Database\Seeders\CategorySeeder;
use Database\Seeders\CommuneSeeder;
use Database\Seeders\ShowcaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

uses(TestCase::class, RefreshDatabase::class);

it('donne de une à cinq annonces à chaque service', function () {
    $this->seed([CommuneSeeder::class, CategorySeeder::class, ShowcaseSeeder::class]);

    $response = $this->getJson('/api/v1/categories')->assertOk();

    foreach ($response->json('data') as $category) {
        expect($category['listings_count'])
            ->toBeGreaterThanOrEqual(1, $category['name'])
            ->toBeLessThanOrEqual(5, $category['name']);
    }
});

it('varie le nombre d’annonces d’un service à l’autre', function () {
    $this->seed([CommuneSeeder::class, CategorySeeder::class, ShowcaseSeeder::class]);

    $counts = Listing::query()
        ->selectRaw('category_id, count(*) as total')
        ->groupBy('category_id')
        ->pluck('total')
        ->map(fn ($total) => (int) $total)
        ->unique();

    // Une vitrine où tous les services afficheraient « 1 annonce » est
    // exactement ce que le porteur ne voulait plus voir (8 nov. 2026).
    expect($counts->count())->toBeGreaterThan(2);
});

it('reste idempotent quand on le rejoue', function () {
    $this->seed([CommuneSeeder::class, CategorySeeder::class, ShowcaseSeeder::class]);

    $before = Listing::count();
    $titles = Listing::pluck('title')->all();

    $this->seed(ShowcaseSeeder::class);

    expect(Listing::count())->toBe($before)
        ->and(Listing::pluck('title')->all())->toBe($titles);
});

it('garde un titre distinct par annonce d’un même service', function () {
    $this->seed([CommuneSeeder::class, CategorySeeder::class, ShowcaseSeeder::class]);

    $titles = Listing::pluck('title');

    expect($titles->count())->toBe($titles->unique()->count());
});
