<?php

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

uses(TestCase::class, RefreshDatabase::class);

it('creates an active administrator account for a fresh deployment', function () {
    $this->artisan('soutrali:create-admin', [
        'email' => 'Premier.Admin@soutrali.ci',
        '--password' => 'secret123',
        '--name' => 'Premier administrateur',
    ])->assertExitCode(0);

    $admin = User::query()->where('email', 'Premier.Admin@soutrali.ci')->first();

    expect($admin)->not->toBeNull()
        ->and($admin->role)->toBe('ADMINISTRATEUR')
        ->and($admin->status)->toBe('ACTIF')
        ->and($admin->display_name)->toBe('Premier administrateur')
        ->and(Hash::check('secret123', $admin->password))->toBeTrue();
});

it('promotes an existing user instead of failing', function () {
    $existing = User::factory()->create([
        'email' => 'deja.inscrit@soutrali.ci',
        'display_name' => 'Existante',
        'role' => 'UTILISATEUR',
        'status' => 'ACTIF',
    ]);

    $this->artisan('soutrali:create-admin', [
        'email' => 'deja.inscrit@soutrali.ci',
        '--password' => 'nouveaumotdepasse',
    ])->assertExitCode(0);

    $existing->refresh();

    expect($existing->role)->toBe('ADMINISTRATEUR')
        ->and($existing->display_name)->toBe('Existante')
        ->and(Hash::check('nouveaumotdepasse', $existing->password))->toBeTrue()
        ->and(User::query()->count())->toBe(1);
});

it('rejects an invalid email or a short password', function () {
    $this->artisan('soutrali:create-admin', [
        'email' => 'pas-un-email',
        '--password' => 'secret123',
    ])->assertExitCode(1);

    $this->artisan('soutrali:create-admin', [
        'email' => 'cour@soutrali.ci',
        '--password' => 'court',
    ])->assertExitCode(1);

    expect(User::query()->count())->toBe(0);
});
