<?php

namespace App\Policies;

use App\Models\Commune;
use App\Models\User;

/**
 * Référentiel des communes : gérable par les modérateurs, suppression
 * interdite (le désactivation suffit : `active = false`).
 */
class CommunePolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isModerator();
    }

    public function view(User $user, Commune $model): bool
    {
        return $user->isModerator();
    }

    public function create(User $user): bool
    {
        return $user->isModerator();
    }

    public function update(User $user, Commune $model): bool
    {
        return $user->isModerator();
    }

    public function delete(User $user, Commune $model): bool
    {
        return false;
    }
}
