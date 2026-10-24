<?php

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

uses(TestCase::class, RefreshDatabase::class);

/**
 * Les onze tables du modèle conceptuel (SUIVI_DEVELOPPEMENT) plus
 * `messages` de la messagerie interne (22 oct.) : toute migration qui
 * en casse une est bloquée ici.
 *
 * @return array<int, string>
 */
function conceptualTables(): array
{
    return [
        'communes',
        'users',
        'categories',
        'listings',
        'sessions',
        'personal_access_tokens',
        'contact_channels',
        'user_blocks',
        'interactions',
        'reports',
        'moderation_actions',
        'messages',
    ];
}

it('creates the conceptual tables of the model', function () {
    foreach (conceptualTables() as $table) {
        expect(Schema::hasTable($table))->toBeTrue("Table manquante : {$table}");
    }
});

it('keeps the safety, scheduling and trace columns', function () {
    expect(Schema::hasColumn('user_blocks', 'blocker_id'))->toBeTrue()
        ->and(Schema::hasColumn('user_blocks', 'blocked_id'))->toBeTrue()
        ->and(Schema::hasColumn('contact_channels', 'visible_to_members'))->toBeTrue()
        ->and(Schema::hasColumn('contact_channels', 'type'))->toBeTrue()
        ->and(Schema::hasColumn('listings', 'publish_at'))->toBeTrue()
        ->and(Schema::hasColumn('listings', 'closure_outcome'))->toBeTrue()
        ->and(Schema::hasColumn('reports', 'status'))->toBeTrue()
        ->and(Schema::hasColumn('moderation_actions', 'decision'))->toBeTrue()
        ->and(Schema::hasColumn('moderation_actions', 'acted_at'))->toBeTrue()
        ->and(Schema::hasColumn('messages', 'read_at'))->toBeTrue();
});

it('replays every migration down and up again', function () {
    $this->artisan('migrate:reset')->assertSuccessful();

    foreach (conceptualTables() as $table) {
        expect(Schema::hasTable($table))->toBeFalse("Table résiduelle : {$table}");
    }

    $this->artisan('migrate')->assertSuccessful();

    foreach (conceptualTables() as $table) {
        expect(Schema::hasTable($table))->toBeTrue("Table manquante après rejouage : {$table}");
    }

    expect(Schema::hasColumn('listings', 'publish_at'))->toBeTrue();
});
