<?php

namespace App\Policies;

use App\Models\Message;
use App\Models\User;

/**
 * Messages internes : consultation seule, attachée à celle du fil.
 */
class MessagePolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isModerator();
    }

    public function view(User $user, Message $model): bool
    {
        return $user->isModerator();
    }

    public function create(User $user): bool
    {
        return false;
    }

    public function update(User $user, Message $model): bool
    {
        return false;
    }

    public function delete(User $user, Message $model): bool
    {
        return false;
    }
}
