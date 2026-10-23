<?php

use App\Filament\Resources\Reports\Pages\ListReports;
use App\Filament\Resources\Users\Pages\EditUser;
use App\Filament\Resources\Users\Pages\ListUsers;
use App\Models\Category;
use App\Models\Commune;
use App\Models\Listing;
use App\Models\ModerationAction;
use App\Models\Report;
use App\Models\User;
use App\Support\Moderation\Decision;
use App\Support\Moderation\ReportModerator;
use Database\Seeders\CategorySeeder;
use Database\Seeders\CommuneSeeder;
use Filament\Facades\Filament;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Livewire\Livewire;
use Tests\TestCase;

uses(TestCase::class, RefreshDatabase::class);

/**
 * Comptes de test + annonce publiée + signalement « Nouveau » : le point
 * de départ de tout scénario de modération du back-office.
 *
 * @return array{author: User, reporter: User, moderator: User, administrator: User, listing: Listing, report: Report}
 */
function adminFixture(): array
{
    test()->seed([CommuneSeeder::class, CategorySeeder::class]);

    $author = User::factory()->create();
    $reporter = User::factory()->create();
    $moderator = User::factory()->create(['role' => 'MODERATEUR']);
    $administrator = User::factory()->create(['role' => 'ADMINISTRATEUR']);

    $listing = Listing::create([
        'user_id' => $author->id,
        'category_id' => Category::where('name', 'Autres')->value('id'),
        'commune_id' => Commune::where('name', 'Abobo')->value('id'),
        'title' => 'Annonce à modérer',
        'description' => 'Une annonce publiée qui va être signalée puis traitée par un modérateur.',
        'type' => 'OFFRE',
        'nature' => 'REMUNEREE',
        'status' => 'PUBLIEE',
    ]);

    $report = Report::create([
        'listing_id' => $listing->id,
        'reporter_id' => $reporter->id,
        'reason' => 'Fausse annonce',
        'details' => 'Le contact demandé semble frauduleux.',
        'status' => 'NOUVEAU',
    ]);

    return [
        'author' => $author,
        'reporter' => $reporter,
        'moderator' => $moderator,
        'administrator' => $administrator,
        'listing' => $listing,
        'report' => $report,
    ];
}

it('opens the panel only for active moderators and administrators', function () {
    $panel = Filament::getPanel('admin');

    $user = User::factory()->create();
    $suspendedModerator = User::factory()->create(['role' => 'MODERATEUR', 'status' => 'SUSPENDU']);
    $moderator = User::factory()->create(['role' => 'MODERATEUR']);
    $administrator = User::factory()->create(['role' => 'ADMINISTRATEUR']);

    expect($user->canAccessPanel($panel))->toBeFalse()
        ->and($suspendedModerator->canAccessPanel($panel))->toBeFalse()
        ->and($moderator->canAccessPanel($panel))->toBeTrue()
        ->and($administrator->canAccessPanel($panel))->toBeTrue();
});

it('redirects anonymous visitors to login and refuses ordinary accounts', function () {
    $this->get('/admin')->assertRedirect();

    $user = User::factory()->create();
    $this->actingAs($user)->get('/admin')->assertForbidden();

    $suspendedModerator = User::factory()->create(['role' => 'MODERATEUR', 'status' => 'SUSPENDU']);
    $this->actingAs($suspendedModerator)->get('/admin')->assertForbidden();

    $moderator = User::factory()->create(['role' => 'MODERATEUR']);
    $this->actingAs($moderator)->get('/admin')->assertOk();
});

it('treats a report from the moderation table, hiding the listing and tracing the decision (D-06)', function () {
    ['moderator' => $moderator, 'listing' => $listing, 'report' => $report] = adminFixture();

    $this->actingAs($moderator);

    Livewire::test(ListReports::class)
        ->callTableAction('prendre_en_charge', $report)
        ->assertNotified();

    expect($report->fresh()->status)->toBe('EN_COURS')
        ->and(ModerationAction::latest('id')->value('decision'))->toBe('PRISE_EN_CHARGE');

    Livewire::test(ListReports::class)
        ->callTableAction('traiter', $report, data: [
            'decision' => 'ANNONCE_MASQUEE',
            'justification' => 'Coordonnées bancaires demandées à l’avance.',
        ])
        ->assertNotified();

    $report->refresh();
    $listing->refresh();

    expect($report->status)->toBe('TRAITE')
        ->and($listing->status)->toBe('MASQUEE');

    $action = ModerationAction::latest('id')->first();

    expect($action->report_id)->toBe($report->id)
        ->and($action->moderator_id)->toBe($moderator->id)
        ->and($action->decision)->toBe('ANNONCE_MASQUEE')
        ->and($action->justification)->toBe('Coordonnées bancaires demandées à l’avance.')
        ->and($action->acted_at)->not->toBeNull();
});

it('classifies a report without suit, leaving the listing visible', function () {
    ['moderator' => $moderator, 'listing' => $listing, 'report' => $report] = adminFixture();

    $this->actingAs($moderator);

    Livewire::test(ListReports::class)
        ->callTableAction('traiter', $report, data: [
            'decision' => 'SANS_SUITE',
        ]);

    expect($report->fresh()->status)->toBe('TRAITE')
        ->and($listing->fresh()->status)->toBe('PUBLIEE')
        ->and(ModerationAction::latest('id')->value('decision'))->toBe('SANS_SUITE');
});

it('refuses to hide an already closed listing when treating a report', function () {
    ['moderator' => $moderator, 'listing' => $listing, 'report' => $report] = adminFixture();

    $listing->update(['status' => 'CLOTUREE']);

    $this->actingAs($moderator);

    Livewire::test(ListReports::class)
        ->callTableAction('traiter', $report, data: [
            'decision' => 'ANNONCE_MASQUEE',
            'justification' => 'Masquage demandé après clôture.',
        ]);

    expect($report->fresh()->status)->toBe('TRAITE')
        ->and($listing->fresh()->status)->toBe('CLOTUREE')
        ->and(ModerationAction::count())->toBe(1);
});

it('rejects a report with its justification, leaving the listing visible', function () {
    ['moderator' => $moderator, 'listing' => $listing, 'report' => $report] = adminFixture();

    $this->actingAs($moderator);

    Livewire::test(ListReports::class)
        ->callTableAction('rejeter', $report, data: [
            'justification' => 'Aucune violation du règlement constatée.',
        ]);

    expect($report->fresh()->status)->toBe('REJETE')
        ->and($listing->fresh()->status)->toBe('PUBLIEE')
        ->and(ModerationAction::latest('id')->value('decision'))->toBe('SIGNALEMENT_REJETE');
});

it('suspends and reactivates an account, tracing both decisions and locking self-suspension', function () {
    ['administrator' => $administrator, 'author' => $author] = adminFixture();

    $this->actingAs($administrator);

    Livewire::test(ListUsers::class)
        ->callTableAction('suspendre', $author, data: [
            'justification' => 'Plusieurs signalements pour contenus trompeurs.',
        ])
        ->assertNotified();

    expect($author->fresh()->status)->toBe('SUSPENDU')
        ->and(ModerationAction::latest('id')->value('decision'))->toBe('COMPTE_SUSPENDU')
        ->and(ModerationAction::latest('id')->value('moderator_id'))->toBe($administrator->id);

    Livewire::test(ListUsers::class)
        ->callTableAction('reactiver', $author, data: [
            'justification' => 'Le compte a régularisé ses annonces.',
        ]);

    expect($author->fresh()->status)->toBe('ACTIF')
        ->and(ModerationAction::latest('id')->value('decision'))->toBe('COMPTE_REACTIVE');

    // Un administrateur ne peut pas se suspendre lui-même : la trace et
    // la porte de sortie doivent rester entre de bonnes mains.
    Livewire::test(ListUsers::class)
        ->assertTableActionHidden('suspendre', $administrator);
});

it('reserves account management and its role fields to administrators', function () {
    ['moderator' => $moderator, 'administrator' => $administrator, 'author' => $author] = adminFixture();

    // Un modérateur n’accède ni à la liste ni à la fiche d’un compte.
    $this->actingAs($moderator)->get('/admin/users')->assertForbidden();
    $this->actingAs($moderator)->get("/admin/users/{$author->id}/edit")->assertForbidden();

    // L’administrateur, lui, voit les champs de rôle et de statut.
    $this->actingAs($administrator);

    Livewire::test(EditUser::class, ['record' => $author->id])
        ->assertFormFieldVisible('role')
        ->assertFormFieldVisible('status');
});

it('keeps deletion forbidden and read-only models locked down for everyone', function () {
    ['moderator' => $moderator, 'administrator' => $administrator, 'report' => $report, 'listing' => $listing] = adminFixture();

    $journal = ReportModerator::log($report, Decision::PriseEnCharge, null, $moderator);

    foreach ([$moderator, $administrator] as $staff) {
        expect($staff->can('delete', $report))->toBeFalse()
            ->and($staff->can('delete', $listing))->toBeFalse()
            ->and($staff->can('delete', $journal))->toBeFalse()
            ->and($staff->can('create', Report::class))->toBeFalse()
            ->and($staff->can('create', ModerationAction::class))->toBeFalse()
            ->and($staff->can('update', $journal))->toBeFalse();
    }

    // La gestion des comptes reste réservée à l’administrateur.
    expect($moderator->can('viewAny', User::class))->toBeFalse()
        ->and($administrator->can('viewAny', User::class))->toBeTrue();
});
