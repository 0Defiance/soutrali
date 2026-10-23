<?php

namespace App\Policies;

use App\Models\User;

/**
 * Gestion des comptes et des rôles (T2) : réservée aux administrateurs.
 * La suppression est interdite à tous : un compte se suspend, il ne se
 * supprime pas (la trace des annonces et des signalements doit rester).
 */
class UserPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isAdministrator();
    }

    public function view(User $user, User $model): bool
    {
        return $user->isAdministrator();
    }

    public function create(User $user): bool
    {
        return $user->isAdministrator();
    }

    public function update(User $user, User $model): bool
    {
        return $user->isAdministrator();
    }

    public function delete(User $user, User $model): bool
    {
        return false;
    }
}
