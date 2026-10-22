<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

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
    ];

    protected function casts(): array
    {
        return ['budget' => 'decimal:2'];
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function commune(): BelongsTo
    {
        return $this->belongsTo(Commune::class);
    }

    public function author(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function scopePublished(Builder $query): Builder
    {
        return $query->where('status', 'PUBLIEE');
    }
}