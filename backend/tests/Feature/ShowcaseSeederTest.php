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

it('donne un montant réaliste en FCFA à chaque annonce rémunérée', function () {
    $this->seed([CommuneSeeder::class, CategorySeeder::class, ShowcaseSeeder::class]);

    $paid = Listing::where('nature', 'REMUNEREE')->get();

    expect($paid)->not->toBeEmpty();

    foreach ($paid as $listing) {
        expect($listing->budget)->not->toBeNull("Montant manquant : {$listing->title}")
            ->and((int) $listing->budget)->toBeGreaterThanOrEqual(500)
            ->and((int) $listing->budget)->toBeLessThanOrEqual(5000000);
    }
});

it('affiche des montants alignés sur les tarifs d’Abidjan', function () {
    $this->seed([CommuneSeeder::class, CategorySeeder::class, ShowcaseSeeder::class]);

    $budgets = Listing::pluck('budget', 'title');

    // Un déménagement de studio à Abidjan coûte plusieurs dizaines de
    // milliers de francs, un tableau électrique complet bien davantage : les
    // montants de la vitrine doivent tenir debout face à un Ivoirien.
    expect((int) $budgets['Déménagement d’un studio le samedi'])->toBeGreaterThanOrEqual(40000)
        ->and((int) $budgets['Installation d’un tableau électrique'])->toBeGreaterThanOrEqual(60000)
        ->and((int) $budgets['Repas de fête pour vingt personnes'])->toBeGreaterThanOrEqual(90000)
        ->and((int) $budgets['Garde d’enfants après l’école'])->toBeGreaterThanOrEqual(25000)
        ->and((int) $budgets['Retouches et ourlets rendus en 48 h'])->toBeLessThanOrEqual(3000);
});

it('facture l’express plus cher et le petit budget moins cher', function () {
    $this->seed([CommuneSeeder::class, CategorySeeder::class, ShowcaseSeeder::class]);

    $listings = Listing::all();
    $express = $listings
        ->whereNotNull('budget')
        ->filter(fn (Listing $listing) => str_starts_with($listing->title, 'Express : '));
    $cheap = $listings
        ->whereNotNull('budget')
        ->filter(fn (Listing $listing) => str_starts_with($listing->title, 'Petit budget : '));

    expect($express)->not->toBeEmpty()
        ->and($cheap)->not->toBeEmpty();

    foreach ($express as $listing) {
        $base = $listings->firstWhere('title', substr($listing->title, strlen('Express : ')));

        expect($base)->not->toBeNull()
            ->and((int) $listing->budget)->toBeGreaterThan((int) $base->budget);
    }

    foreach ($cheap as $listing) {
        $base = $listings->firstWhere('title', substr($listing->title, strlen('Petit budget : ')));

        expect($base)->not->toBeNull()
            ->and((int) $listing->budget)->toBeLessThan((int) $base->budget);
    }
});

it('remet les montants de la vitrine au tarif courant', function () {
    $this->seed([CommuneSeeder::class, CategorySeeder::class, ShowcaseSeeder::class]);

    $listing = Listing::where('title', 'Garde d’enfants après l’école')->firstOrFail();
    $listing->update(['budget' => 1000, 'description' => 'Ancien texte.']);

    $this->seed(ShowcaseSeeder::class);

    $listing->refresh();

    expect((int) $listing->budget)->toBe(35000)
        ->and($listing->description)->toContain('35 000 FCFA');
});

it('garde un titre distinct par annonce d’un même service', function () {
    $this->seed([CommuneSeeder::class, CategorySeeder::class, ShowcaseSeeder::class]);

    $titles = Listing::pluck('title');

    expect($titles->count())->toBe($titles->unique()->count());
});
