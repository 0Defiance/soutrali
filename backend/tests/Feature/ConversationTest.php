<?php

use App\Models\Category;
use App\Models\Commune;
use App\Models\Interaction;
use App\Models\Listing;
use App\Models\User;
use Database\Seeders\CategorySeeder;
use Database\Seeders\CommuneSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

uses(TestCase::class, RefreshDatabase::class);

/**
 * @return array{author: User, writer: User, listing: Listing}
 */
function conversationFixture(): array
{
    test()->seed([CommuneSeeder::class, CategorySeeder::class]);

    $author = User::factory()->create();
    $writer = User::factory()->create();

    $listing = Listing::create([
        'user_id' => $author->id,
        'category_id' => Category::where('name', 'Réparations et dépannage')->value('id'),
        'commune_id' => Commune::where('name', 'Cocody')->value('id'),
        'title' => 'Réparer un robinet qui goutte',
        'description' => 'Mon robinet de cuisine goutte en permanence, je cherche un coup de main.',
        'type' => 'DEMANDE',
        'nature' => 'REMUNEREE',
        'status' => 'PUBLIEE',
    ]);

    return ['author' => $author, 'writer' => $writer, 'listing' => $listing];
}

it('refuses anonymous contact and reading', function () {
    ['listing' => $listing] = conversationFixture();

    $this->postJson("/api/v1/listings/{$listing->id}/conversations", ['message' => 'Bonjour !'])
        ->assertStatus(401);

    $this->getJson('/api/v1/conversations')->assertStatus(401);
});

it('opens a conversation on someone else’s listing but not on its own', function () {
    ['author' => $author, 'listing' => $listing] = conversationFixture();

    $this->actingAs($author)->postJson("/api/v1/listings/{$listing->id}/conversations", [
        'message' => 'Bonjour, je me contate moi-même ?',
    ])->assertStatus(403);

    $writer = User::factory()->create();

    $this->actingAs($writer)->postJson("/api/v1/listings/{$listing->id}/conversations", [
        'message' => 'Bonjour, votre annonce m’intéresse, êtes-vous disponible cette semaine ?',
    ])->assertCreated()->assertJsonPath('listing.title', 'Réparer un robinet qui goutte');
});

it('threads messages, counts unread and marks them read on opening', function () {
    ['author' => $author, 'writer' => $writer, 'listing' => $listing] = conversationFixture();

    $this->actingAs($writer)->postJson("/api/v1/listings/{$listing->id}/conversations", [
        'message' => 'Bonjour, votre annonce m’intéresse.',
    ])->assertCreated();

    $interaction = Interaction::sole();

    $this->actingAs($author)->postJson("/api/v1/conversations/{$interaction->id}/messages", [
        'body' => 'Bonjour, oui je suis disponible jeudi après-midi.',
    ])->assertCreated();

    $index = $this->actingAs($writer)->getJson('/api/v1/conversations')->assertOk();

    expect($index->json('data'))->toHaveCount(1)
        ->and($index->json('unread_total'))->toBe(1)
        ->and($index->json('data.0.participant.display_name'))->toBe($author->display_name);

    $authorIndex = $this->actingAs($author)->getJson('/api/v1/conversations')->assertOk();

    expect($authorIndex->json('unread_total'))->toBe(1)
        ->and($authorIndex->json('data.0.participant.display_name'))->toBe($writer->display_name);

    $thread = $this->actingAs($writer)->getJson("/api/v1/conversations/{$interaction->id}")->assertOk();

    expect($thread->json('messages'))->toHaveCount(2)
        ->and($thread->json('messages.0.is_mine'))->toBeTrue()
        ->and($thread->json('messages.1.is_mine'))->toBeFalse();

    expect($this->actingAs($writer)->getJson('/api/v1/conversations')->json('unread_total'))->toBe(0)
        ->and($this->actingAs($author)->getJson('/api/v1/conversations')->json('unread_total'))->toBe(1);
});

it('locks a conversation to its two participants', function () {
    ['writer' => $writer, 'listing' => $listing] = conversationFixture();

    $this->actingAs($writer)->postJson("/api/v1/listings/{$listing->id}/conversations", [
        'message' => 'Bonjour, une question sur votre annonce.',
    ])->assertCreated();

    $interaction = Interaction::sole();
    $stranger = User::factory()->create();

    $this->actingAs($stranger)->getJson("/api/v1/conversations/{$interaction->id}")
        ->assertStatus(403);

    $this->actingAs($stranger)->postJson("/api/v1/conversations/{$interaction->id}/messages", [
        'body' => 'Moi aussi je veux écrire ici.',
    ])->assertStatus(403);

    $this->actingAs($stranger)->getJson('/api/v1/conversations')
        ->assertOk()
        ->assertJsonCount(0, 'data');
});
