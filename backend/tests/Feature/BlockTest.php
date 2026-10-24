<?php

use App\Models\Category;
use App\Models\Commune;
use App\Models\Interaction;
use App\Models\Listing;
use App\Models\User;
use App\Models\UserBlock;
use Database\Seeders\CategorySeeder;
use Database\Seeders\CommuneSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

uses(TestCase::class, RefreshDatabase::class);

/**
 * @return array{author: User, writer: User, listing: Listing}
 */
function blockFixture(): array
{
    test()->seed([CommuneSeeder::class, CategorySeeder::class]);

    $author = User::factory()->create();
    $writer = User::factory()->create();

    $listing = Listing::create([
        'user_id' => $author->id,
        'category_id' => Category::where('name', 'Réparations et dépannage')->value('id'),
        'commune_id' => Commune::where('name', 'Cocody')->value('id'),
        'title' => 'Réparer une porte qui grince',
        'description' => 'Ma porte de cour grince fort, je cherche quelqu’un pour la régler.',
        'type' => 'DEMANDE',
        'nature' => 'BENEVOLE',
        'status' => 'PUBLIEE',
    ]);

    return ['author' => $author, 'writer' => $writer, 'listing' => $listing];
}

it('requires an authenticated account to manage blocks', function () {
    ['author' => $author] = blockFixture();

    $this->getJson('/api/v1/me/blocks')->assertStatus(401);
    $this->postJson("/api/v1/users/{$author->id}/block")->assertStatus(401);
    $this->deleteJson("/api/v1/users/{$author->id}/block")->assertStatus(401);
});

it('refuses self-blocking and unknown accounts', function () {
    ['author' => $author] = blockFixture();

    $this->actingAs($author)->postJson("/api/v1/users/{$author->id}/block")
        ->assertStatus(403);

    $this->actingAs($author)->postJson('/api/v1/users/9999/block')
        ->assertStatus(404);

    expect(UserBlock::count())->toBe(0);
});

it('blocks and unblocks an account idempotently', function () {
    ['author' => $author, 'writer' => $writer] = blockFixture();

    $this->actingAs($writer)->postJson("/api/v1/users/{$author->id}/block")
        ->assertOk()
        ->assertJsonPath('blocked', true);

    // Re-bloquer n’est pas une erreur : le blocage est idempotent.
    $this->actingAs($writer)->postJson("/api/v1/users/{$author->id}/block")
        ->assertOk()
        ->assertJsonPath('blocked', true);

    expect(UserBlock::count())->toBe(1);

    $index = $this->actingAs($writer)->getJson('/api/v1/me/blocks')->assertOk();

    expect($index->json('data'))->toHaveCount(1)
        ->and($index->json('data.0.id'))->toBe($author->id)
        ->and($index->json('data.0.display_name'))->toBe($author->display_name)
        ->and($index->json('data.0.blocked_at'))->not->toBeNull();

    // L’autre compte ne voit rien apparaître : il n’est pas le bloqueur.
    $this->actingAs($author)->getJson('/api/v1/me/blocks')
        ->assertOk()
        ->assertJsonCount(0, 'data');

    $this->actingAs($writer)->deleteJson("/api/v1/users/{$author->id}/block")
        ->assertOk()
        ->assertJsonPath('blocked', false);

    // Débloquer deux fois reste un succès.
    $this->actingAs($writer)->deleteJson("/api/v1/users/{$author->id}/block")->assertOk();

    expect(UserBlock::count())->toBe(0);
});

it('disables messaging in both directions while a block exists', function () {
    ['author' => $author, 'writer' => $writer, 'listing' => $listing] = blockFixture();

    $this->actingAs($writer)->postJson("/api/v1/listings/{$listing->id}/conversations", [
        'message' => 'Bonjour, votre annonce m’intéresse.',
    ])->assertCreated();

    $interaction = Interaction::sole();

    // L’auteur bloque l’initiateur : plus d’écriture dans les deux sens.
    $this->actingAs($author)->postJson("/api/v1/users/{$writer->id}/block")->assertOk();

    $this->actingAs($writer)->postJson("/api/v1/conversations/{$interaction->id}/messages", [
        'body' => 'Toujours disponible ?',
    ])->assertStatus(403);

    $this->actingAs($author)->postJson("/api/v1/conversations/{$interaction->id}/messages", [
        'body' => 'Non merci.',
    ])->assertStatus(403);

    $this->actingAs($writer)->postJson("/api/v1/listings/{$listing->id}/conversations", [
        'message' => 'Rebonjour.',
    ])->assertStatus(403);

    // Le déblocage rétablit la messagerie.
    $this->actingAs($author)->deleteJson("/api/v1/users/{$writer->id}/block")->assertOk();

    $this->actingAs($writer)->postJson("/api/v1/conversations/{$interaction->id}/messages", [
        'body' => 'Toujours disponible ?',
    ])->assertCreated();
});

it('blocks messaging when the blocked account initiates the contact', function () {
    ['author' => $author, 'writer' => $writer, 'listing' => $listing] = blockFixture();

    $this->actingAs($author)->postJson("/api/v1/users/{$writer->id}/block")->assertOk();

    $this->actingAs($writer)->postJson("/api/v1/listings/{$listing->id}/conversations", [
        'message' => 'Bonjour, une question sur votre annonce.',
    ])->assertStatus(403);

    expect(Interaction::count())->toBe(0);
});
