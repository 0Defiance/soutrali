<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Carbon;

/**
 * @property Carbon|null $created_at
 * @property Carbon|null $updated_at
 */
class UserBlock extends Model
{
    protected $fillable = ['blocker_id', 'blocked_id'];

    /**
     * Un blocage existe-t-il dans l’un ou l’autre sens entre deux comptes ?
     * La messagerie (T-14) est désactivée dans les deux sens dès qu’un
     * des deux a bloqué l’autre.
     */
    public static function existsBetween(int $a, int $b): bool
    {
        return self::query()
            ->where(function ($query) use ($a, $b) {
                $query->where('blocker_id', $a)->where('blocked_id', $b);
            })
            ->orWhere(function ($query) use ($a, $b) {
                $query->where('blocker_id', $b)->where('blocked_id', $a);
            })
            ->exists();
    }

    public function blocker(): BelongsTo
    {
        return $this->belongsTo(User::class, 'blocker_id');
    }

    /**
     * Compte bloqué.
     *
     * @return BelongsTo<User, $this>
     */
    public function blocked(): BelongsTo
    {
        return $this->belongsTo(User::class, 'blocked_id');
    }
}
