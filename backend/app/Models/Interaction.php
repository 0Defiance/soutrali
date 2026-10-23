<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * Trace de prise de contact (T-14) : un fil par (annonce, initiateur).
 * Le fil contient les messages internes échangés entre l'initiateur et l'auteur.
 */
class Interaction extends Model
{
    protected $fillable = ['listing_id', 'initiator_id', 'status'];

    /**
     * @return BelongsTo<Listing, $this>
     */
    public function listing(): BelongsTo
    {
        return $this->belongsTo(Listing::class);
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function initiator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'initiator_id');
    }

    /**
     * @return HasMany<Message, $this>
     */
    public function messages(): HasMany
    {
        return $this->hasMany(Message::class)->orderBy('created_at');
    }

    /**
     * Les deux participants au fil : l'initiateur et l'auteur de l'annonce.
     *
     * @return array<int, User>
     */
    public function participants(): array
    {
        $author = $this->listing?->author;
        $initiator = $this->initiator;

        return array_values(array_filter([$initiator, $author]));
    }

    public function involves(User $user): bool
    {
        return $this->initiator_id === $user->id || $this->listing?->user_id === $user->id;
    }
}
