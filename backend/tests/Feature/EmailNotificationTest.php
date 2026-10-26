<?php

use App\Mail\ListingPublishedMail;
use App\Mail\NewMessageMail;
use App\Mail\WelcomeMail;
use App\Models\Category;
use App\Models\Commune;
use App\Models\Interaction;
use App\Models\Listing;
use App\Models\User;
use Database\Seeders\CategorySeeder;
use Database\Seeders\CommuneSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

uses(TestCase::class, RefreshDatabase::class);

const EMAIL_ORIGIN = 'http://127.0.0.1:8082';

/**
 * Annonce publiée de l’auteur, pour les scénarios de publication (F-09).
 *
 * @return array{author: User, listing: Listing}
 */
function publishedFixture(): array
{
    test()->seed([CommuneSeeder::class, CategorySeeder::class]);

    $author = User::factory()->create();

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

    return ['author' => $author, 'listing' => $listing];
}

it('sends a welcome email when a user registers', function () {
    Mail::fake();

    $this->withHeaders(['Origin' => EMAIL_ORIGIN])->postJson('/api/v1/register', [
        'display_name' => 'Aya Test',
        'email' => 'aya@example.test',
        'password' => 'motdepasse123',
        'password_confirmation' => 'motdepasse123',
    ])->assertCreated();

    Mail::assertSent(WelcomeMail::class, function (WelcomeMail $mail) {
        // Le sujet est porté par l’enveloppe : il n’est appliqué au mailable
        // qu’au moment de l’envoi réel, jamais par la fausse boîte.
        return $mail->hasTo('aya@example.test')
            && str_contains($mail->envelope()->subject, 'Bienvenue');
    });
});

it('sends the publication email only when a listing actually goes live', function () {
    ['author' => $author] = publishedFixture();

    Mail::fake();

    // Publication immédiate depuis l’API (F-03).
    $this->withHeaders(['Origin' => EMAIL_ORIGIN])->actingAs($author)->postJson('/api/v1/listings', [
        'title' => 'Installer une prise électrique',
        'description' => 'Je souhaite faire installer une prise dans mon salon.',
        'type' => 'DEMANDE',
        'nature' => 'REMUNEREE',
        'category_id' => Category::where('name', 'Réparations et dépannage')->value('id'),
        'commune_id' => Commune::where('name', 'Cocody')->value('id'),
    ])->assertCreated();

    Mail::assertSent(ListingPublishedMail::class, 1);

    // Annonce programmée : elle reste en brouillon, aucun e-mail.
    $scheduled = $this->withHeaders(['Origin' => EMAIL_ORIGIN])->actingAs($author)->postJson('/api/v1/listings', [
        'title' => 'Ménage hebdomadaire',
        'description' => 'Je recherche une aide au ménage une fois par semaine.',
        'type' => 'DEMANDE',
        'nature' => 'REMUNEREE',
        'category_id' => Category::where('name', 'Maison et domestique')->value('id'),
        'commune_id' => Commune::where('name', 'Cocody')->value('id'),
        'publish_at' => now()->addDay()->toIso8601String(),
    ])->assertCreated();

    expect($scheduled->json('status'))->toBe('BROUILLON');
    Mail::assertSent(ListingPublishedMail::class, 1);

    // Mise en ligne manuelle : l’e-mail part à ce moment-là.
    $scheduledId = $scheduled->json('id');

    $this->withHeaders(['Origin' => EMAIL_ORIGIN])
        ->actingAs($author)
        ->postJson("/api/v1/listings/{$scheduledId}/publish")
        ->assertOk();

    Mail::assertSent(
        ListingPublishedMail::class,
        fn (ListingPublishedMail $mail) => $mail->hasTo($author->email),
    );
    Mail::assertSent(ListingPublishedMail::class, 2);
});

it('notifies the author when the scheduled command publishes a due listing', function () {
    ['author' => $author, 'listing' => $listing] = publishedFixture();

    $listing->update(['status' => 'BROUILLON', 'publish_at' => now()->subDay()]);

    Mail::fake();

    $this->artisan('soutrali:publish-due')->assertExitCode(0);

    expect($listing->fresh()->status)->toBe('PUBLIEE');

    Mail::assertSent(
        ListingPublishedMail::class,
        fn (ListingPublishedMail $mail) => $mail->hasTo($author->email),
    );
});

it('notifies both sides of a conversation when a message arrives', function () {
    ['author' => $author, 'listing' => $listing] = publishedFixture();
    $writer = User::factory()->create();

    Mail::fake();

    $this->withHeaders(['Origin' => EMAIL_ORIGIN])->actingAs($writer)->postJson(
        "/api/v1/listings/{$listing->id}/conversations",
        ['message' => 'Bonjour, votre annonce m’intéresse-t-elle toujours ?'],
    )->assertCreated();

    // L’auteur de l’annonce est le seul destinataire du premier message.
    Mail::assertSent(
        NewMessageMail::class,
        fn (NewMessageMail $mail) => $mail->hasTo($author->email),
    );

    $interaction = Interaction::sole();

    // La réponse revient à l’expéditeur, jamais à l’auteur de nouveau.
    $this->withHeaders(['Origin' => EMAIL_ORIGIN])->actingAs($author)->postJson(
        "/api/v1/conversations/{$interaction->id}/messages",
        ['body' => 'Bonjour, oui elle est toujours disponible.'],
    )->assertCreated();

    Mail::assertSent(
        NewMessageMail::class,
        fn (NewMessageMail $mail) => $mail->hasTo($writer->email),
    );
    Mail::assertSent(NewMessageMail::class, 2);
});

it('keeps the API working when the mail transport fails', function () {
    Mail::shouldReceive('to')->andThrow(new RuntimeException('SMTP injoignable'));

    // L’inscription et la publication restent acquises malgré la panne :
    // Outbox journalise l’échec dans error.log sans remonter l’erreur.
    $this->withHeaders(['Origin' => EMAIL_ORIGIN])->postJson('/api/v1/register', [
        'display_name' => 'Sans Mail',
        'email' => 'sansmail@example.test',
        'password' => 'motdepasse123',
        'password_confirmation' => 'motdepasse123',
    ])->assertCreated();

    expect(User::where('email', 'sansmail@example.test')->exists())->toBeTrue();
});
