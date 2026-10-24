<?php

use App\Models\Category;
use App\Models\Commune;
use App\Models\ContactChannel;
use App\Models\Listing;
use App\Models\User;
use Database\Seeders\CategorySeeder;
use Database\Seeders\CommuneSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

uses(TestCase::class, RefreshDatabase::class);

/**
 * @return array{author: User, viewer: User, listing: Listing}
 */
function channelFixture(): array
{
    test()->seed([CommuneSeeder::class, CategorySeeder::class]);

    $author = User::factory()->create();
    $viewer = User::factory()->create();

    $listing = Listing::create([
        'user_id' => $author->id,
        'category_id' => Category::where('name', 'Réparations et dépannage')->value('id'),
        'commune_id' => Commune::where('name', 'Cocody')->value('id'),
        'title' => 'Besoin d’un coup de main au marché',
        'description' => 'Je cherche une aide pour porter mes courses du samedi matin.',
        'type' => 'DEMANDE',
        'nature' => 'BENEVOLE',
        'status' => 'PUBLIEE',
    ]);

    return ['author' => $author, 'viewer' => $viewer, 'listing' => $listing];
}

it('requires an authenticated account to manage contact channels', function () {
    ['listing' => $listing] = channelFixture();

    $this->getJson('/api/v1/me/channels')->assertStatus(401);

    $this->postJson('/api/v1/me/channels', [
        'type' => 'TELEPHONE',
        'value' => '+225 07 00 00 00 00',
        'visible_to_members' => true,
    ])->assertStatus(401);

    $this->getJson("/api/v1/listings/{$listing->id}/contact-channels")->assertStatus(401);
});

it('creates, updates and deletes one’s own channels', function () {
    ['author' => $author] = channelFixture();

    $this->actingAs($author)->postJson('/api/v1/me/channels', [
        'type' => 'TELEPHONE',
        'value' => '+225 07 00 00 00 00',
        'visible_to_members' => true,
    ])->assertOk()->assertJsonPath('data.label', 'Téléphone');

    // Un second type coexiste ; le même type est mis à jour, pas dupliqué.
    $this->actingAs($author)->postJson('/api/v1/me/channels', [
        'type' => 'EMAIL',
        'value' => 'contact@example.net',
        'visible_to_members' => false,
    ])->assertOk();

    $this->actingAs($author)->postJson('/api/v1/me/channels', [
        'type' => 'TELEPHONE',
        'value' => '+225 05 11 11 11 11',
        'visible_to_members' => false,
    ])->assertOk();

    expect(ContactChannel::where('user_id', $author->id)->count())->toBe(2);

    $index = $this->actingAs($author)->getJson('/api/v1/me/channels')->assertOk();

    expect($index->json('data'))->toHaveCount(2)
        ->and($index->json('data.0.type'))->toBe('EMAIL')
        ->and($index->json('data.0.value'))->toBe('contact@example.net')
        ->and($index->json('data.1.value'))->toBe('+225 05 11 11 11 11')
        ->and($index->json('data.1.visible_to_members'))->toBeFalse();

    $channel = ContactChannel::where('user_id', $author->id)->where('type', 'TELEPHONE')->sole();

    $this->actingAs($author)->deleteJson("/api/v1/me/channels/{$channel->id}")
        ->assertOk()
        ->assertJsonPath('deleted', true);

    expect(ContactChannel::where('user_id', $author->id)->count())->toBe(1);
});

it('validates channel types and values', function () {
    ['author' => $author] = channelFixture();

    $this->actingAs($author)->postJson('/api/v1/me/channels', [
        'type' => 'FACEBOOK',
        'value' => 'quelqu.un',
        'visible_to_members' => true,
    ])->assertStatus(422)->assertJsonValidationErrors('type');

    $this->actingAs($author)->postJson('/api/v1/me/channels', [
        'type' => 'EMAIL',
        'value' => 'pas-un-email',
        'visible_to_members' => true,
    ])->assertStatus(422)->assertJsonValidationErrors('value');

    $this->actingAs($author)->postJson('/api/v1/me/channels', [
        'type' => 'WHATSAPP',
        'value' => 'abc123',
        'visible_to_members' => true,
    ])->assertStatus(422)->assertJsonValidationErrors('value');

    $this->actingAs($author)->postJson('/api/v1/me/channels', [
        'type' => 'TELEPHONE',
        'value' => '+225 07 00 00 00 00',
    ])->assertStatus(422)->assertJsonValidationErrors('visible_to_members');

    expect(ContactChannel::count())->toBe(0);
});

it('refuses to delete another account’s channel', function () {
    ['author' => $author, 'viewer' => $viewer] = channelFixture();

    $channel = ContactChannel::create([
        'user_id' => $author->id,
        'type' => 'TELEPHONE',
        'value' => '+225 07 00 00 00 00',
        'visible_to_members' => true,
    ]);

    $this->actingAs($viewer)->deleteJson("/api/v1/me/channels/{$channel->id}")
        ->assertStatus(404);

    expect(ContactChannel::count())->toBe(1);
});

it('exposes only channels marked visible, to other members only', function () {
    ['author' => $author, 'viewer' => $viewer, 'listing' => $listing] = channelFixture();

    ContactChannel::create([
        'user_id' => $author->id,
        'type' => 'TELEPHONE',
        'value' => '+225 07 00 00 00 00',
        'visible_to_members' => true,
    ]);
    ContactChannel::create([
        'user_id' => $author->id,
        'type' => 'EMAIL',
        'value' => 'auteur@example.net',
        'visible_to_members' => false,
    ]);

    $exposed = $this->actingAs($viewer)
        ->getJson("/api/v1/listings/{$listing->id}/contact-channels")
        ->assertOk();

    expect($exposed->json('data'))->toHaveCount(1)
        ->and($exposed->json('data.0.type'))->toBe('TELEPHONE')
        ->and($exposed->json('data.0.label'))->toBe('Téléphone')
        ->and($exposed->json('data.0.value'))->toBe('+225 07 00 00 00 00');

    // L’auteur ne reçoit pas ses propres canaux par cette route…
    $this->actingAs($author)
        ->getJson("/api/v1/listings/{$listing->id}/contact-channels")
        ->assertStatus(403);

    // …et un compte bloqué ne les reçoit pas non plus.
    $this->actingAs($author)->postJson("/api/v1/users/{$viewer->id}/block")->assertOk();

    $this->actingAs($viewer)
        ->getJson("/api/v1/listings/{$listing->id}/contact-channels")
        ->assertStatus(403);
});

it('returns no channels for a listing that is not published', function () {
    ['author' => $author, 'viewer' => $viewer, 'listing' => $listing] = channelFixture();

    ContactChannel::create([
        'user_id' => $author->id,
        'type' => 'TELEPHONE',
        'value' => '+225 07 00 00 00 00',
        'visible_to_members' => true,
    ]);

    $listing->update(['status' => 'MASQUEE']);

    $this->actingAs($viewer)
        ->getJson("/api/v1/listings/{$listing->id}/contact-channels")
        ->assertStatus(404);
});
