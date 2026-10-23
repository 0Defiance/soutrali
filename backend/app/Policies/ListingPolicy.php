<?php

namespace App\Policies;

use App\Models\Listing;
use App\Models\User;

/**
 * Annonces côté back-office : les modérateurs consultent, masquent et
 * republient ; la création n’a pas lieu depuis l’admin (elle se fait par
 * l’API de l’application) et la suppression est interdite (masquage à la
 * place, pour conserver la trace).
 */
class ListingPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isModerator();
    }

    public function view(User $user, Listing $model): bool
    {
        return $user->isModerator();
    }

    public function create(User $user): bool
    {
        return false;
    }

    public function update(User $user, Listing $model): bool
    {
        return $user->isModerator();
    }

    public function delete(User $user, Listing $model): bool
    {
        return false;
    }
}
