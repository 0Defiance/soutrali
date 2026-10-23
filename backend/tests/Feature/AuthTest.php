<?php

use App\Models\Commune;
use App\Models\User;
use Database\Seeders\CommuneSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

uses(TestCase::class, RefreshDatabase::class);

const FRONT_ORIGIN = 'http://127.0.0.1:8082';

it('registers a user and opens a session', function () {
    $this->seed(CommuneSeeder::class);
    $commune = Commune::where('name', 'Cocody')->value('id');

    $response = $this->withHeaders(['Origin' => FRONT_ORIGIN])->postJson('/api/v1/register', [
        'display_name' => 'Aya Test',
        'email' => 'aya@example.test',
        'password' => 'motdepasse123',
        'password_confirmation' => 'motdepasse123',
        'commune_id' => $commune,
    ]);

    $response->assertCreated()
        ->assertJsonPath('user.display_name', 'Aya Test')
        ->assertJsonPath('user.email', 'aya@example.test')
        ->assertJsonPath('user.commune.name', 'Cocody')
        ->assertJsonPath('user.role', 'UTILISATEUR');

    $this->assertAuthenticated();

    expect(User::where('email', 'aya@example.test')->exists())->toBeTrue();
});

it('rejects a registration with a duplicate email or a weak password', function () {
    User::factory()->create(['email' => 'deja@example.test']);

    $this->withHeaders(['Origin' => FRONT_ORIGIN])->postJson('/api/v1/register', [
        'display_name' => 'Doublon',
        'email' => 'deja@example.test',
        'password' => 'motdepasse123',
        'password_confirmation' => 'motdepasse123',
    ])->assertStatus(422)->assertJsonValidationErrors(['email']);

    $this->withHeaders(['Origin' => FRONT_ORIGIN])->postJson('/api/v1/register', [
        'display_name' => 'Court',
        'email' => 'court@example.test',
        'password' => 'court',
        'password_confirmation' => 'court',
    ])->assertStatus(422)->assertJsonValidationErrors(['password']);
});

it('logs in with valid credentials and refuses wrong ones', function () {
    $user = User::factory()->create();

    $this->withHeaders(['Origin' => FRONT_ORIGIN])->postJson('/api/v1/login', [
        'email' => $user->email,
        'password' => 'password',
    ])->assertOk()->assertJsonPath('user.id', $user->id);

    $this->assertAuthenticated();

    $this->withHeaders(['Origin' => FRONT_ORIGIN])->postJson('/api/v1/logout')->assertOk();

    // Les tests partagent une instance d'application entre requêtes : le garde
    // « sanctum » conserve en mémoire l'utilisateur de la requête précédente
    // et devient garde par défaut, alors qu'en production chaque requête
    // reconstruit l'application. On réinitialise les gardes pour observer
    // l'état réel de la session.
    $auth = $this->app->make('auth');
    $auth->forgetGuards();
    $auth->shouldUse('web');

    $this->withHeaders(['Origin' => FRONT_ORIGIN])->getJson('/api/v1/me')->assertStatus(401);

    $this->withHeaders(['Origin' => FRONT_ORIGIN])->postJson('/api/v1/login', [
        'email' => $user->email,
        'password' => 'mauvais-mdp',
    ])->assertStatus(422)->assertJsonValidationErrors(['email']);

    $this->withHeaders(['Origin' => FRONT_ORIGIN])->getJson('/api/v1/me')->assertStatus(401);
});

it('serves the current session and refuses anonymous access', function () {
    $user = User::factory()->create();

    $this->withHeaders(['Origin' => FRONT_ORIGIN])->getJson('/api/v1/me')
        ->assertStatus(401);

    // Sans en-tête Accept, la requête doit rester en 401 JSON et ne jamais
    // tenter une redirection vers une route de connexion web inexistante.
    $this->get('/api/v1/me')->assertStatus(401);

    $this->withHeaders(['Origin' => FRONT_ORIGIN])->actingAs($user)->getJson('/api/v1/me')
        ->assertOk()
        ->assertJsonPath('user.id', $user->id)
        ->assertJsonPath('user.display_name', $user->display_name);
});

it('issues a CSRF token for JSON mutations', function () {
    $response = $this->withHeaders(['Origin' => FRONT_ORIGIN])->getJson('/api/v1/csrf-token');

    $response->assertOk()->assertJsonStructure(['token']);

    expect($response->json('token'))->not->toBeNull()
        ->and(strlen((string) $response->json('token')))->toBeGreaterThan(10);

    // Le jeton accepte la mutation qui suit (en-tête X-CSRF-TOKEN).
    $this->withHeaders([
        'Origin' => FRONT_ORIGIN,
        'X-CSRF-TOKEN' => (string) $response->json('token'),
    ])->postJson('/api/v1/login', [
        'email' => 'inconnu@example.test',
        'password' => 'mauvais-mdp',
    ])->assertStatus(422);
});
