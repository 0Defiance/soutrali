<?php

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Route;
use Tests\TestCase;

uses(TestCase::class, RefreshDatabase::class);

beforeEach(function () {
    // Journaux dédiés aux tests : les fichiers de production (access.log,
    // error.log) ne sont ni lus ni remplis par la suite.
    config()->set('logging.channels.access.path', storage_path('logs/testing-access.log'));
    config()->set('logging.channels.errors.path', storage_path('logs/testing-error.log'));
    File::delete(File::glob(storage_path('logs/testing-*.log')) ?: []);
});

/**
 * Contenu cumulé des fichiers d’un canal journalisé (chaîne vide si absent).
 *
 * @param  string  $channel  « access » ou « errors » : lit `testing-access*.log` / `testing-error*.log`.
 */
function accessLogTestContents(string $channel): string
{
    $files = File::glob(storage_path('logs/testing-'.$channel.'*.log')) ?: [];

    sort($files);

    return implode("\n", array_map(
        static fn (string $file): string => File::get($file) ?: '',
        $files,
    ));
}

it('traces every API request in the access log', function () {
    Route::middleware('api')->get('/api/v1/__access-probe', fn () => response()->json(['ok' => true]));

    $this->getJson('/api/v1/__access-probe')->assertOk();

    expect(accessLogTestContents('access'))
        ->toContain('GET /api/v1/__access-probe 200')
        ->toContain('ip=');
});

it('records the authenticated user and rejected statuses in the access log', function () {
    $user = User::factory()->create();

    $this->getJson('/api/v1/me')->assertUnauthorized();

    $this->actingAs($user)->getJson('/api/v1/me')->assertOk();

    $log = accessLogTestContents('access');

    expect($log)
        ->toContain('GET /api/v1/me 401 user=-')
        ->toContain("GET /api/v1/me 200 user={$user->id}");
});

it('leaves pages and assets out of the access log', function () {
    $this->get('/')->assertOk();

    expect(accessLogTestContents('access'))->not->toContain('GET / 200');
});

it('routes exceptions to the dedicated error log', function () {
    Route::middleware('api')->get('/api/v1/__error-probe', function (): void {
        throw new RuntimeException('panne simulée pour le test');
    });

    $this->getJson('/api/v1/__error-probe')->assertServerError();

    expect(accessLogTestContents('error'))
        ->toContain('panne simulée pour le test')
        ->toContain('ERROR');
});
