<?php

use App\Models\Category;
use App\Models\Commune;
use App\Models\Listing;
use App\Models\User;
use Database\Seeders\CategorySeeder;
use Database\Seeders\CommuneSeeder;
use Database\Seeders\ShowcaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

uses(TestCase::class, RefreshDatabase::class);

beforeEach(function () {
    $this->seed([CommuneSeeder::class, CategorySeeder::class]);
});

it('sits a GPS position on the Abidjan referential', function () {
    // Angré, Cocody : le quartier doit être reconnu, avec sa commune et sa zone.
    $response = $this->getJson('/api/v1/geolocation?latitude=5.3971&longitude=-3.9729&accuracy=25');

    $response->assertOk()
        ->assertJsonPath('data.in_service_area', true)
        ->assertJsonPath('data.country', 'Côte d’Ivoire')
        ->assertJsonPath('data.city', 'Abidjan')
        ->assertJsonPath('data.commune.name', 'Cocody')
        ->assertJsonPath('data.quartier', 'Angré')
        ->assertJsonPath('data.zone', 'Abidjan Est')
        ->assertJsonPath('data.accuracy_m', 25)
        ->assertJsonPath('data.coordinates.latitude', 5.3971);

    expect($response->json('data.distance_m'))->toBeLessThan(1000);
    expect($response->json('data.label'))->toContain('Abidjan')->toContain('Cocody');
});

it('returns the commune id of the resolved quartier', function () {
    $response = $this->getJson('/api/v1/geolocation?latitude=5.3010&longitude=-3.9870');

    $cocody = Commune::where('name', 'Marcory')->firstOrFail();

    $response->assertOk()
        ->assertJsonPath('data.commune.id', $cocody->id)
        ->assertJsonPath('data.quartier', 'Marcory Centre')
        ->assertJsonPath('data.zone', 'Abidjan Sud');
});

it('refuses to invent a location outside the covered area', function () {
    // Paris : hors de Côte d’Ivoire, aucune commune, aucun quartier.
    $response = $this->getJson('/api/v1/geolocation?latitude=48.8566&longitude=2.3522');

    $response->assertOk()
        ->assertJsonPath('data.in_service_area', false)
        ->assertJsonPath('data.country', null)
        ->assertJsonPath('data.city', null)
        ->assertJsonPath('data.commune', null)
        ->assertJsonPath('data.quartier', null)
        ->assertJsonPath('data.label', null);
});

it('validates the coordinates it receives', function () {
    $this->getJson('/api/v1/geolocation')->assertStatus(422);
    $this->getJson('/api/v1/geolocation?latitude=120&longitude=-4')->assertStatus(422);
    $this->getJson('/api/v1/geolocation?latitude=5.35')->assertStatus(422);
});

it('publishes commune coordinates for the application', function () {
    $response = $this->getJson('/api/v1/communes');

    $response->assertOk()->assertJsonStructure(['data' => [['id', 'name', 'latitude', 'longitude']]]);

    $cocody = collect($response->json('data'))->firstWhere('name', 'Cocody');

    expect((float) $cocody['latitude'])->toBe(5.354)
        ->and((float) $cocody['longitude'])->toBe(-3.961);
});

it('sorts listings by distance when a position is given', function () {
    $this->seed(ShowcaseSeeder::class);

    // Position au centre d’Abobo : les annonces d’Abobo passent devant.
    $response = $this->getJson('/api/v1/listings?latitude=5.4161&longitude=-4.0159&per_page=24');

    $response->assertOk();

    $rows = $response->json('data');

    expect($rows)->not->toBeEmpty();

    $distances = array_column($rows, 'distance_km');

    // La position est le centre exact d’Abobo : son annonce est à 0 km.
    expect((float) $distances[0])->toBeLessThan(1.0)
        ->and((float) $distances[0])->toBeLessThan((float) $distances[count($distances) - 1]);

    $sorted = $distances;
    sort($sorted);

    expect($distances)->toBe($sorted);
    expect($rows[0]['commune']['name'])->toBe('Abobo');
});

it('keeps the usual order without a position', function () {
    $this->seed(ShowcaseSeeder::class);

    $response = $this->getJson('/api/v1/listings');

    $response->assertOk();

    expect($response->json('data.0.distance_km'))->toBeNull();
    expect($response->json('data.0.commune.name'))->toBeString();
});

it('counts the available listings of each service', function () {
    $this->seed(ShowcaseSeeder::class);

    $response = $this->getJson('/api/v1/categories');

    $response->assertOk()->assertJsonStructure(['data' => [['id', 'name', 'icon', 'listings_count']]]);

    $counts = collect($response->json('data'))->pluck('listings_count', 'name');

    expect($counts)->toHaveCount(count(CategorySeeder::NAMES));

    foreach ($counts as $name => $count) {
        expect($count)->toBeGreaterThanOrEqual(1, "Aucune annonce disponible pour {$name}");
    }
});

it('gives every service at least one published listing', function () {
    $this->seed(ShowcaseSeeder::class);

    $services = Category::query()->where('active', true)->get();

    expect($services)->toHaveCount(count(CategorySeeder::NAMES));

    foreach ($services as $service) {
        expect(Listing::query()->where('category_id', $service->id)->published()->count())
            ->toBeGreaterThanOrEqual(1, "Le service {$service->name} n’a aucune annonce visible");
    }

    // Une annonce de la vitrine est bien rattachée à son auteur.
    $listing = Listing::query()->published()->firstOrFail();

    expect($listing->author->email)->toBe(ShowcaseSeeder::AUTHOR_EMAIL);
});

it('can be replayed without duplicating the showcase', function () {
    $this->seed(ShowcaseSeeder::class);

    $count = Listing::query()->count();

    $this->seed(ShowcaseSeeder::class);

    expect(Listing::query()->count())->toBe($count)
        ->and(User::where('email', ShowcaseSeeder::AUTHOR_EMAIL)->count())->toBe(1);
});

it('only completes services that have no visible listing', function () {
    $author = User::factory()->create();
    $category = Category::where('name', 'Plomberie et sanitaire')->firstOrFail();

    Listing::create([
        'user_id' => $author->id,
        'category_id' => $category->id,
        'commune_id' => Commune::where('name', 'Cocody')->value('id'),
        'title' => 'Annonce réelle du service plomberie',
        'description' => 'Une annonce réelle qui ne doit pas être complétée par la vitrine.',
        'type' => 'OFFRE',
        'nature' => 'REMUNEREE',
        'status' => 'PUBLIEE',
    ]);

    $this->seed(ShowcaseSeeder::class);

    expect(Listing::where('category_id', $category->id)->count())->toBe(1)
        ->and(Listing::where('category_id', $category->id)->first()->title)
        ->toBe('Annonce réelle du service plomberie');
});
