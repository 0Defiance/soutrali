<?php

namespace App\Models;

use Filament\Models\Contracts\FilamentUser;
use Filament\Models\Contracts\HasName;
use Filament\Panel;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable implements FilamentUser, HasName
{
    use HasApiTokens;
    use HasFactory;
    use Notifiable;

    protected $fillable = [
        'display_name',
        'email',
        'phone',
        'password',
        'role',
        'status',
        'commune_id',
        'presentation',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'phone_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    /**
     * @return BelongsTo<Commune, $this>
     */
    public function commune(): BelongsTo
    {
        return $this->belongsTo(Commune::class);
    }

    public function listings(): HasMany
    {
        return $this->hasMany(Listing::class);
    }

    public function contactChannels(): HasMany
    {
        return $this->hasMany(ContactChannel::class);
    }

    public function blocksCreated(): HasMany
    {
        return $this->hasMany(UserBlock::class, 'blocker_id');
    }

    public function blocksReceived(): HasMany
    {
        return $this->hasMany(UserBlock::class, 'blocked_id');
    }

    /**
     * Décisions de modération prises par cet utilisateur.
     *
     * @return HasMany<ModerationAction, $this>
     */
    public function moderationActions(): HasMany
    {
        return $this->hasMany(ModerationAction::class, 'moderator_id');
    }

    /**
     * Signalements déposés par cet utilisateur.
     *
     * @return HasMany<Report, $this>
     */
    public function reports(): HasMany
    {
        return $this->hasMany(Report::class, 'reporter_id');
    }

    public function canAccessPanel(Panel $panel): bool
    {
        return in_array($this->role, ['MODERATEUR', 'ADMINISTRATEUR'], true)
            && $this->status === 'ACTIF';
    }

    /**
     * Nom affiché dans le back-office (le modèle n’a pas de colonne
     * `name` : Filament exige ce contrat pour l’en-tête et le menu).
     */
    public function getFilamentName(): string
    {
        return $this->display_name;
    }

    /**
     * Administrateur du back-office : gestion des comptes et des rôles.
     */
    public function isAdministrator(): bool
    {
        return $this->role === 'ADMINISTRATEUR' && $this->status === 'ACTIF';
    }

    /**
     * Modérateur ou administrateur actif : accès aux actions de modération.
     */
    public function isModerator(): bool
    {
        return in_array($this->role, ['MODERATEUR', 'ADMINISTRATEUR'], true)
            && $this->status === 'ACTIF';
    }
}
