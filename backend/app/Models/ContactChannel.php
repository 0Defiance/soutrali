<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ContactChannel extends Model
{
    protected $fillable = ['user_id', 'type', 'value', 'visible_to_members'];

    protected function casts(): array
    {
        return ['visible_to_members' => 'boolean'];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
