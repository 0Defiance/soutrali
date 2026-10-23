<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Carbon;

/**
 * Trace d’une décision de modération (D-06) : qui a décidé, quoi, quand et
 * pourquoi. Chaque décision prise depuis le back-office crée une ligne, y
 * c. les actions menées hors signalement (masquage d’une annonce,
 * suspension d’un compte) qui portent `report_id` nul.
 *
 * @property Carbon|null $acted_at
 */
class ModerationAction extends Model
{
    protected $fillable = ['report_id', 'moderator_id', 'decision', 'justification', 'acted_at'];

    protected function casts(): array
    {
        return [
            'acted_at' => 'datetime',
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }

    /**
     * @return BelongsTo<Report, $this>
     */
    public function report(): BelongsTo
    {
        return $this->belongsTo(Report::class);
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function moderator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'moderator_id');
    }
}
