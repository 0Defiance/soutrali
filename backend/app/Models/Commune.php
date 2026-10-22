<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Commune extends Model
{
    protected $fillable = ['name', 'active'];

    protected function casts(): array
    {
        return ['active' => 'boolean'];
    }

    public function listings(): HasMany
    {
        return $this->hasMany(Listing::class);
    }
}