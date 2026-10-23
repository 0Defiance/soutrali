<?php

namespace App\Policies;

use App\Models\ModerationAction;
use App\Models\User;

/**
 * Journal de modération : strictement consultable. Une trace se crée,
 * ne se modifie ni ne se supprime jamais — c’est la garantie d’audit
 * de la décision D-06.
 */
class ModerationActionPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isModerator();
    }

    public function view(User $user, ModerationAction $model): bool
    {
        return $user->isModerator();
    }

    public function create(User $user): bool
    {
        return false;
    }

    public function update(User $user, ModerationAction $model): bool
    {
        return false;
    }

    public function delete(User $user, ModerationAction $model): bool
    {
        return false;
    }
}
