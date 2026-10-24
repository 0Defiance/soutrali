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
 * @return array{author: User}
 */
function scheduledFixture(): array
{
    test()->seed([CommuneSeeder::class, CategorySeeder::class]);

    return ['author' => User::factory()->create()];
}

/**
 * @return array<string, mixed>
 */
function scheduledPayload(array $overrides = []): array
{
    return array_merge([
        'title' => 'Aide au déménagement samedi matin',
        'description' => 'Je cherche deux personnes pour déplacer des cartons vers le quartier voisin.',
        'type' => 'DEMANDE',
        'nature' => 'BENEVOLE',
        'category_id' => Category::where('name', 'Réparations et dépannage')->value('id'),
        'commune_id' => Commune::where('name', 'Cocody')->value('id'),
    ], $overrides);
}

it('publishes immediately by default and exposes publish_at', function () {
    ['author' => $author] = scheduledFixture();

    $response = $this->actingAs($author)
        ->postJson('/api/v1/listings', scheduledPayload())
        ->assertCreated();

    expect($response->json('status'))->toBe('PUBLIEE')
        ->and($response->json('publish_at'))->not->toBeNull();

    $mine = $this->actingAs($author)->getJson('/api/v1/me/listings')->assertOk();

    expect($mine->json('data.0.publish_at'))->not->toBeNull();
});

it('holds a scheduled listing out of public views until its date', function () {
    ['author' => $author] = scheduledFixture();

    $response = $this->actingAs($author)
        ->postJson('/api/v1/listings', scheduledPayload([
            'publish_at' => now()->addHours(2)->toIso8601String(),
        ]))
        ->assertCreated();

    expect($response->json('status'))->toBe('BROUILLON');

    $listingId = $response->json('id');

    $index = $this->getJson('/api/v1/listings')->assertOk();
    expect(collect($index->json('data'))->pluck('id')->toArray())->not->toContain($listingId);

    $this->getJson("/api/v1/listings/{$listingId}")->assertNotFound();

    $writer = User::factory()->create();

    $this->actingAs($writer)->postJson("/api/v1/listings/{$listingId}/conversations", [
        'message' => 'Bonjour, cette annonce m’intéresse, est-elle toujours d’actualité ?',
    ])->assertNotFound();

    // Le back-office voit le brouillon, comme avant.
    expect(Listing::find($listingId)->status)->toBe('BROUILLON');
});

it('exposes a scheduled listing once its date is reached', function () {
    ['author' => $author] = scheduledFixture();

    $response = $this->actingAs($author)
        ->postJson('/api/v1/listings', scheduledPayload([
            'publish_at' => now()->addHours(2)->toIso8601String(),
        ]))
        ->assertCreated();

    $listingId = $response->json('id');

    $this->travel(3)->hours();

    // Visible sans attendre le cron…
    $index = $this->getJson('/api/v1/listings')->assertOk();
    expect(collect($index->json('data'))->pluck('id')->toArray())->toContain($listingId);

    $this->getJson("/api/v1/listings/{$listingId}")->assertOk();

    $writer = User::factory()->create();

    $this->actingAs($writer)->postJson("/api/v1/listings/{$listingId}/conversations", [
        'message' => 'Bonjour, l’annonce est-elle encore disponible ?',
    ])->assertCreated();

    // …et la commande normalise le statut pour l’auteur et l’administration.
    $this->artisan('soutrali:publish-due')->assertSuccessful();

    expect(Listing::find($listingId)->status)->toBe('PUBLIEE');
});

it('refuses a publication date in the past', function () {
    ['author' => $author] = scheduledFixture();

    $this->actingAs($author)
        ->postJson('/api/v1/listings', scheduledPayload([
            'publish_at' => now()->subMinutes(5)->toIso8601String(),
        ]))
        ->assertStatus(422)
        ->assertJsonValidationErrors('publish_at');
});

it('publishes a scheduled listing immediately on demand', function () {
    ['author' => $author] = scheduledFixture();

    $scheduled = $this->actingAs($author)
        ->postJson('/api/v1/listings', scheduledPayload([
            'publish_at' => now()->addDay()->toIso8601String(),
        ]))
        ->assertCreated();

    $listingId = $scheduled->json('id');

    // Seul l’auteur peut forcer la mise en ligne.
    $other = User::factory()->create();
    $this->actingAs($other)->postJson("/api/v1/listings/{$listingId}/publish")->assertStatus(403);

    $this->actingAs($author)->postJson("/api/v1/listings/{$listingId}/publish")
        ->assertOk()
        ->assertJsonPath('status', 'PUBLIEE');

    $this->getJson("/api/v1/listings/{$listingId}")->assertOk();

    // Rééditer une annonce déjà publiée : accepté (sans nouvelle date).
    $this->actingAs($author)
        ->patchJson("/api/v1/listings/{$listingId}", scheduledPayload([
            'title' => 'Titre modifié après mise en ligne',
        ]))
        ->assertOk()
        ->assertJsonPath('status', 'PUBLIEE');

    // Une seconde mise en ligne n’a pas de sens : 409.
    $this->actingAs($author)->postJson("/api/v1/listings/{$listingId}/publish")
        ->assertStatus(409);
});

it('allows rescheduling before publication but not after', function () {
    ['author' => $author] = scheduledFixture();

    $scheduled = $this->actingAs($author)
        ->postJson('/api/v1/listings', scheduledPayload([
            'publish_at' => now()->addDay()->toIso8601String(),
        ]))
        ->assertCreated();

    expect($scheduled->json('status'))->toBe('BROUILLON');

    // Replanifier avant la mise en ligne : accepté.
    $this->actingAs($author)
        ->patchJson("/api/v1/listings/{$scheduled->json('id')}", scheduledPayload([
            'publish_at' => now()->addDays(3)->toIso8601String(),
        ]))
        ->assertOk()
        ->assertJsonPath('status', 'BROUILLON');

    $this->travel(4)->days();
    $this->artisan('soutrali:publish-due')->assertSuccessful();

    // Après publication : plus de report possible.
    $this->actingAs($author)
        ->patchJson("/api/v1/listings/{$scheduled->json('id')}", scheduledPayload([
            'publish_at' => now()->addDay()->toIso8601String(),
        ]))
        ->assertStatus(422)
        ->assertJsonValidationErrors('publish_at');

    // Une simple modification reste possible.
    $this->actingAs($author)
        ->patchJson("/api/v1/listings/{$scheduled->json('id')}", scheduledPayload([
            'title' => 'Titre corrigé après publication',
        ]))
        ->assertOk()
        ->assertJsonPath('status', 'PUBLIEE');
});
