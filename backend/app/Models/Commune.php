<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Commune extends Model
{
    /**
     * Choix de saisie pour une annonce qui couvre plusieurs communes (D-03) :
     * ce n’est pas une commune du District d’Abidjan, qui en compte treize.
     */
    public const MULTI_COMMUNE = 'Plusieurs communes';

    protected $fillable = ['name', 'active'];

    protected function casts(): array
    {
        return ['active' => 'boolean'];
    }

    public function listings(): HasMany
    {
        return $this->hasMany(Listing::class);
    }

    /**
     * La ligne « Plusieurs communes » est une zone de saisie, pas une commune :
     * elle ne doit donc pas être comptée comme telle à l’écran.
     */
    public function isZone(): bool
    {
        return $this->name === self::MULTI_COMMUNE;
    }
}
