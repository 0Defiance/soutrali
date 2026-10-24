<?php

use App\Models\Category;
use App\Models\Commune;
use App\Models\Listing;
use App\Models\User;
use Database\Seeders\CategorySeeder;
use Database\Seeders\CommuneSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

uses(TestCase::class, RefreshDatabase::class);

/**
 * @return array{author: User, listing: Listing}
 */
function contractFixture(): array
{
    test()->seed([CommuneSeeder::class, CategorySeeder::class]);

    $author = User::factory()->create();

    $listing = Listing::create([
        'user_id' => $author->id,
        'category_id' => Category::where('name', 'Réparations et dépannage')->value('id'),
        'commune_id' => Commune::where('name', 'Cocody')->value('id'),
        'title' => 'Contrat : réparer une chasse d’eau',
        'description' => 'La chasse d’eau de la salle de bain reste ouverte en permanence.',
        'type' => 'DEMANDE',
        'nature' => 'REMUNEREE',
        'status' => 'PUBLIEE',
        'publish_at' => now(),
    ]);

    return ['author' => $author, 'listing' => $listing];
}

it('exposes the public listing index with pagination', function () {
    ['listing' => $listing] = contractFixture();

    $response = $this->getJson('/api/v1/listings')->assertOk();

    $response->assertJsonStructure([
        'data' => [[
            'id',
            'title',
            'description',
            'type',
            'nature',
            'availability',
            'budget',
            'category' => ['name'],
            'commune' => ['name'],
            'author' => ['id', 'display_name'],
            'created_at',
        ]],
        'meta' => ['current_page', 'last_page', 'per_page', 'total'],
        'links',
    ]);

    expect($response->json('data.0.id'))->toBe($listing->id)
        ->and($response->json('meta.total'))->toBe(1);

    // Filtres du référentiel : une commune inconnue ne retourne rien.
    $this->getJson('/api/v1/listings?commune=Inconnue')
        ->assertOk()
        ->assertJsonCount(0, 'data');
});

it('exposes a listing detail and a stable 404 envelope', function () {
    ['listing' => $listing] = contractFixture();

    $this->getJson("/api/v1/listings/{$listing->id}")
        ->assertOk()
        ->assertJsonStructure([
            'data' => [
                'id',
                'title',
                'description',
                'type',
                'nature',
                'availability',
                'budget',
                'category' => ['name'],
                'commune' => ['name'],
                'author' => ['id', 'display_name'],
                'created_at',
            ],
        ])
        ->assertJsonPath('data.id', $listing->id);

    $this->getJson('/api/v1/listings/999999')
        ->assertNotFound()
        ->assertJsonStructure(['message']);
});

it('exposes the reference data used by the filters', function () {
    contractFixture();

    $categories = $this->getJson('/api/v1/categories')->assertOk();
    $categories->assertJsonStructure(['data' => [['id', 'name', 'description']]]);
    expect($categories->json('data'))->not->toBeEmpty();

    $communes = $this->getJson('/api/v1/communes')->assertOk();
    $communes->assertJsonStructure(['data' => [['id', 'name']]]);
    expect($communes->json('data'))->not->toBeEmpty();
});

it('returns a stable user payload on registration, session and login', function () {
    contractFixture();

    // Origine du client (voir AuthTest) : la session n’est ouverte que
    // pour les requêtes venant du front configuré (cors.php).
    $client = ['Origin' => 'http://127.0.0.1:8082'];

    $this->withHeaders($client)->getJson('/api/v1/csrf-token')
        ->assertOk()
        ->assertJsonStructure(['token']);

    $this->withHeaders($client)->postJson('/api/v1/register', [
        'display_name' => 'Awa Koné',
        'email' => 'awa@example.net',
        'password' => 'motdepasse1',
        'password_confirmation' => 'motdepasse1',
        'commune_id' => Commune::first()->id,
    ])
        ->assertCreated()
        ->assertJsonStructure([
            'user' => ['id', 'display_name', 'email', 'role', 'commune' => ['id', 'name']],
        ])
        ->assertJsonPath('user.role', 'UTILISATEUR');

    $this->withHeaders($client)->getJson('/api/v1/me')
        ->assertOk()
        ->assertJsonStructure(['user' => ['id', 'display_name', 'email', 'role', 'commune']]);

    $this->withHeaders($client)->postJson('/api/v1/logout')
        ->assertOk()
        ->assertJsonStructure(['message']);

    // Entre requêtes de test, le garde par défaut bascule sur « sanctum »
    // (voir AuthTest) : on le remet sur « web » pour le login suivant.
    $auth = $this->app->make('auth');
    $auth->forgetGuards();
    $auth->shouldUse('web');

    $this->withHeaders($client)->postJson('/api/v1/login', [
        'email' => 'awa@example.net',
        'password' => 'motdepasse1',
    ])
        ->assertOk()
        ->assertJsonStructure(['user' => ['id', 'display_name', 'email', 'role', 'commune']]);
});

it('keeps the error envelopes stable for clients', function () {
    contractFixture();

    // Non authentifié : 401 JSON, jamais une redirection HTML.
    $this->getJson('/api/v1/me')
        ->assertStatus(401)
        ->assertJsonStructure(['message']);

    // Validation : 422 avec le message global et les champs en erreur.
    $this->postJson('/api/v1/login', ['email' => 'pas-un-email', 'password' => ''])
        ->assertStatus(422)
        ->assertJsonStructure(['message', 'errors' => ['email', 'password']]);

    // Connexion refusée : message unique, quel que soit le compte.
    $this->postJson('/api/v1/login', [
        'email' => 'inconnu@example.net',
        'password' => 'motdepasse1',
    ])
        ->assertStatus(422)
        ->assertJsonPath('errors.email.0', 'E-mail ou mot de passe incorrect.');
});

it('exposes the authenticated collections with a stable shape', function () {
    ['author' => $author] = contractFixture();

    $this->actingAs($author)->getJson('/api/v1/me/listings')
        ->assertOk()
        ->assertJsonStructure([
            'data' => [[
                'id',
                'title',
                'description',
                'type',
                'nature',
                'status',
                'closure_outcome',
                'publish_at',
                'neighborhood',
                'availability',
                'budget',
                'category' => ['id', 'name'],
                'commune' => ['id', 'name'],
                'created_at',
            ]],
        ]);

    $this->actingAs($author)->getJson('/api/v1/conversations')
        ->assertOk()
        ->assertJsonStructure(['data', 'unread_total']);

    $this->actingAs($author)->getJson('/api/v1/me/reports')
        ->assertOk()
        ->assertJsonStructure(['data']);

    $this->actingAs($author)->getJson('/api/v1/me/blocks')
        ->assertOk()
        ->assertJsonStructure(['data']);

    $this->actingAs($author)->getJson('/api/v1/me/channels')
        ->assertOk()
        ->assertJsonStructure(['data']);
});

it('answers cross-origin requests from the configured frontend origin', function () {
    contractFixture();

    $this->getJson('/api/v1/listings', ['Origin' => 'http://127.0.0.1:8082'])
        ->assertOk()
        ->assertHeader('Access-Control-Allow-Origin', 'http://127.0.0.1:8082')
        ->assertHeader('Access-Control-Allow-Credentials', 'true');

    // Une origine hors liste n’est pas autorisée.
    $this->getJson('/api/v1/listings', ['Origin' => 'https://example.org'])
        ->assertOk()
        ->assertHeaderMissing('Access-Control-Allow-Origin');
});
