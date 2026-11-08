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
 * @return array{category_id: int, commune_id: int}
 */
function seededReferences(): array
{
    test()->seed([CommuneSeeder::class, CategorySeeder::class]);

    return [
        'category_id' => (int) Category::where('name', 'Maison et domestique')->value('id'),
        'commune_id' => (int) Commune::where('name', 'Yopougon')->value('id'),
    ];
}

/**
 * @param  array<string, mixed>  $overrides
 * @return array<string, mixed>
 */
function listingPayload(array $overrides = []): array
{
    return array_merge([
        'title' => 'Aide au montage de meuble',
        'description' => 'J’ai besoin d’aide pour monter une étagère ce week-end, quelques heures suffisent.',
        'type' => 'DEMANDE',
        'nature' => 'BENEVOLE',
        'category_id' => 0,
        'commune_id' => 0,
    ], $overrides);
}

it('refuses publication without a session', function () {
    $this->postJson('/api/v1/listings', listingPayload())->assertStatus(401);
});

it('publishes a listing with immediate visibility (D-06)', function () {
    $refs = seededReferences();
    $user = User::factory()->create();

    $response = $this->actingAs($user)->postJson('/api/v1/listings', listingPayload($refs));

    $response->assertCreated()
        ->assertJsonPath('status', 'PUBLIEE')
        ->assertJsonPath('title', 'Aide au montage de meuble');

    $listing = Listing::where('user_id', $user->id)->first();

    expect($listing)->not->toBeNull()
        ->and($listing->status)->toBe('PUBLIEE');

    $this->getJson('/api/v1/listings')->assertOk()->assertJsonPath('meta.total', 1);
});

it('rejects an invalid listing with comprehensible errors (CA-04)', function () {
    $refs = seededReferences();
    $user = User::factory()->create();

    $this->actingAs($user)->postJson('/api/v1/listings', listingPayload([
        ...$refs,
        'description' => 'court',
    ]))->assertStatus(422)->assertJsonValidationErrors(['description']);

    $this->actingAs($user)->postJson('/api/v1/listings', listingPayload([
        'commune_id' => $refs['commune_id'],
    ]))->assertStatus(422)->assertJsonValidationErrors(['category_id']);

    expect(Listing::count())->toBe(0);
});

it('exige un montant en FCFA pour une annonce rémunérée', function () {
    $refs = seededReferences();
    $user = User::factory()->create();

    // Sans montant : refus explicite, en français.
    $this->actingAs($user)->postJson('/api/v1/listings', listingPayload([
        ...$refs,
        'nature' => 'REMUNEREE',
    ]))->assertStatus(422)
        ->assertJsonValidationErrors(['budget'])
        ->assertJsonPath('errors.budget.0', 'Indiquez la rémunération en FCFA pour un service rémunéré.');

    // Sous le plancher réaliste d’Abidjan (500 FCFA) : refusé.
    $this->actingAs($user)->postJson('/api/v1/listings', listingPayload([
        ...$refs,
        'nature' => 'REMUNEREE',
        'budget' => 200,
    ]))->assertStatus(422)->assertJsonValidationErrors(['budget']);

    expect(Listing::count())->toBe(0);

    // Montant accepté : 5 000 FCFA, entier.
    $this->actingAs($user)->postJson('/api/v1/listings', listingPayload([
        ...$refs,
        'nature' => 'REMUNEREE',
        'budget' => 5000,
    ]))->assertCreated()->assertJsonPath('budget', 5000);

    $listing = Listing::where('user_id', $user->id)->firstOrFail();

    expect((int) $listing->budget)->toBe(5000)
        ->and($listing->nature)->toBe('REMUNEREE');
});

it('ignore un montant envoyé pour une annonce bénévole', function () {
    $refs = seededReferences();
    $user = User::factory()->create();

    $this->actingAs($user)->postJson('/api/v1/listings', listingPayload([
        ...$refs,
        'nature' => 'BENEVOLE',
        'budget' => 7000,
    ]))->assertCreated();

    expect(Listing::where('user_id', $user->id)->firstOrFail()->budget)->toBeNull();
});

it('lets an owner update but never another user (CA-05)', function () {
    $refs = seededReferences();
    $owner = User::factory()->create();
    $other = User::factory()->create();

    $listing = Listing::create([
        ...listingPayload($refs),
        'user_id' => $owner->id,
        'status' => 'PUBLIEE',
    ]);

    $this->actingAs($other)->patchJson("/api/v1/listings/{$listing->id}", [
        'title' => 'Titre indésirable',
    ])->assertStatus(403);

    expect($listing->fresh()->title)->toBe('Aide au montage de meuble');

    $this->actingAs($owner)->patchJson("/api/v1/listings/{$listing->id}", [
        ...listingPayload($refs),
        'title' => 'Titre corrigé',
    ])->assertOk()->assertJsonPath('title', 'Titre corrigé');
});

it('lists only my listings and closes mine only (CA-05)', function () {
    $refs = seededReferences();
    $owner = User::factory()->create();
    $other = User::factory()->create();

    $mine = Listing::create([...listingPayload($refs), 'user_id' => $owner->id, 'status' => 'PUBLIEE']);
    Listing::create([...listingPayload($refs, ['title' => 'Annonce d’un autre compte']), 'user_id' => $other->id, 'status' => 'PUBLIEE']);

    $this->actingAs($owner)->getJson('/api/v1/me/listings')
        ->assertOk()
        ->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.id', $mine->id);

    $this->actingAs($other)->postJson("/api/v1/listings/{$mine->id}/close", [
        'closure_outcome' => 'BESOIN_SATISFAIT',
    ])->assertStatus(403);

    $this->actingAs($owner)->postJson("/api/v1/listings/{$mine->id}/close", [
        'closure_outcome' => 'BESOIN_SATISFAIT',
    ])->assertOk()
        ->assertJsonPath('status', 'CLOTUREE')
        ->assertJsonPath('closure_outcome', 'BESOIN_SATISFAIT');

    $this->actingAs($owner)->postJson("/api/v1/listings/{$mine->id}/close", [
        'closure_outcome' => 'BESOIN_SATISFAIT',
    ])->assertStatus(409);

    expect($mine->fresh()->status)->toBe('CLOTUREE');

    $this->getJson('/api/v1/listings')->assertOk()->assertJsonPath('meta.total', 1);
});
