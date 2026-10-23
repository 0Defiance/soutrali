<?php

namespace App\Policies;

use App\Models\Report;
use App\Models\User;

/**
 * Signalements (D-06) : consultation et traitement réservés aux
 * modérateurs. Les signalements sont déposés par l’API de l’application,
 * jamais depuis le back-office, et ne sont jamais supprimés (le journal
 * de modération doit rester complet).
 */
class ReportPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isModerator();
    }

    public function view(User $user, Report $model): bool
    {
        return $user->isModerator();
    }

    public function create(User $user): bool
    {
        return false;
    }

    public function update(User $user, Report $model): bool
    {
        return $user->isModerator();
    }

    public function delete(User $user, Report $model): bool
    {
        return false;
    }
}
