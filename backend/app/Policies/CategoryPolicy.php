<?php

namespace App\Policies;

use App\Models\Category;
use App\Models\User;

/**
 * Référentiel des catégories : gérable par les modérateurs, suppression
 * interdite (le désactivation suffit : `active = false`).
 */
class CategoryPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isModerator();
    }

    public function view(User $user, Category $model): bool
    {
        return $user->isModerator();
    }

    public function create(User $user): bool
    {
        return $user->isModerator();
    }

    public function update(User $user, Category $model): bool
    {
        return $user->isModerator();
    }

    public function delete(User $user, Category $model): bool
    {
        return false;
    }
}
