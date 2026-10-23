<?php

use App\Models\Category;
use App\Models\Commune;
use App\Models\Listing;
use App\Models\Report;
use App\Models\User;
use Database\Seeders\CategorySeeder;
use Database\Seeders\CommuneSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

uses(TestCase::class, RefreshDatabase::class);

/**
 * @return array{author: User, reporter: User, listing: Listing}
 */
function reportFixture(): array
{
    test()->seed([CommuneSeeder::class, CategorySeeder::class]);

    $author = User::factory()->create();
    $reporter = User::factory()->create();

    $listing = Listing::create([
        'user_id' => $author->id,
        'category_id' => Category::where('name', 'Autres')->value('id'),
        'commune_id' => Commune::where('name', 'Abobo')->value('id'),
        'title' => 'Annonce à signaler',
        'description' => 'Une annonce de test qui va être signalée par un autre compte.',
        'type' => 'OFFRE',
        'nature' => 'REMUNEREE',
        'status' => 'PUBLIEE',
    ]);

    return ['author' => $author, 'reporter' => $reporter, 'listing' => $listing];
}

it('refuses anonymous reporting', function () {
    ['listing' => $listing] = reportFixture();

    $this->postJson("/api/v1/listings/{$listing->id}/reports", ['reason' => 'Fausse annonce'])
        ->assertStatus(401);
});

it('records a report with its status and lists it for its author (F-07)', function () {
    ['reporter' => $reporter, 'listing' => $listing] = reportFixture();

    $this->actingAs($reporter)->postJson("/api/v1/listings/{$listing->id}/reports", [
        'reason' => 'Fausse annonce',
        'details' => 'Le contact demandé semble frauduleux.',
    ])->assertCreated()->assertJsonPath('status', 'NOUVEAU');

    expect(Report::count())->toBe(1);

    $mine = $this->actingAs($reporter)->getJson('/api/v1/me/reports')->assertOk();

    expect($mine->json('data'))->toHaveCount(1)
        ->and($mine->json('data.0.reason'))->toBe('Fausse annonce')
        ->and($mine->json('data.0.listing.title'))->toBe('Annonce à signaler')
        ->and($mine->json('data.0.status'))->toBe('NOUVEAU');

    $other = User::factory()->create();

    $this->actingAs($other)->getJson('/api/v1/me/reports')
        ->assertOk()
        ->assertJsonCount(0, 'data');
});

it('requires a reason and refuses self-reporting', function () {
    ['author' => $author, 'listing' => $listing] = reportFixture();

    $this->actingAs($author)->postJson("/api/v1/listings/{$listing->id}/reports", [])
        ->assertStatus(422)
        ->assertJsonValidationErrors(['reason']);

    $this->actingAs($author)->postJson("/api/v1/listings/{$listing->id}/reports", [
        'reason' => 'Contenu inapproprié',
    ])->assertStatus(422)->assertJsonValidationErrors(['reason']);

    expect(Report::count())->toBe(0);
});
