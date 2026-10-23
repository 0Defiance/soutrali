<?php

namespace App\Policies;

use App\Models\Interaction;
use App\Models\User;

/**
 * Fils de discussion (D-05) : consultation seule par les modérateurs,
 * pour traiter un litige. Les fils ne se créent, ne se modifient ni ne
 * se suppriment depuis le back-office : ils vivent dans l’application.
 */
class InteractionPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isModerator();
    }

    public function view(User $user, Interaction $model): bool
    {
        return $user->isModerator();
    }

    public function create(User $user): bool
    {
        return false;
    }

    public function update(User $user, Interaction $model): bool
    {
        return false;
    }

    public function delete(User $user, Interaction $model): bool
    {
        return false;
    }
}
