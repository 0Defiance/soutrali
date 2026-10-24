<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Carbon;

/**
 * @property Carbon|null $publish_at
 */
class Listing extends Model
{
    protected $fillable = [
        'user_id',
        'category_id',
        'commune_id',
        'title',
        'description',
        'type',
        'nature',
        'neighborhood',
        'availability',
        'budget',
        'status',
        'closure_outcome',
        'publish_at',
    ];

    protected function casts(): array
    {
        return [
            'budget' => 'decimal:2',
            'publish_at' => 'datetime',
        ];
    }

    /**
     * @return BelongsTo<Category, $this>
     */
    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    /**
     * @return BelongsTo<Commune, $this>
     */
    public function commune(): BelongsTo
    {
        return $this->belongsTo(Commune::class);
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function author(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    /**
     * @return HasMany<Report, $this>
     */
    public function reports(): HasMany
    {
        return $this->hasMany(Report::class);
    }

    /**
     * @return HasMany<Interaction, $this>
     */
    public function interactions(): HasMany
    {
        return $this->hasMany(Interaction::class);
    }

    /**
     * Annonces réellement visibles publiquement : publiées, ou
     * programmées dont la date de publication est atteinte (la
     * normalisation `soutrali:publish-due` vient juste après, mais la
     * visibilité ne dépend jamais d’un cron).
     */
    public function scopePublished(Builder $query): Builder
    {
        return $query->where(function (Builder $query) {
            $query->where('status', 'PUBLIEE')
                ->orWhere(function (Builder $scheduled) {
                    $scheduled->where('status', 'BROUILLON')
                        ->whereNotNull('publish_at')
                        ->where('publish_at', '<=', now());
                });
        });
    }

    /**
     * L’annonce est-elle visible (et contactable) à l’instant T ?
     */
    public function isLive(): bool
    {
        if ($this->status === 'PUBLIEE') {
            return true;
        }

        return $this->status === 'BROUILLON'
            && $this->publish_at !== null
            && ! $this->publish_at->isFuture();
    }
}
