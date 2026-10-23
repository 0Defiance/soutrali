<?php

namespace App\Filament\Resources\Users\Schemas;

use App\Models\User;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Schema;
use Illuminate\Support\Facades\Auth;

class UserForm
{
    public static function configure(Schema $schema): Schema
    {
        $isAdministrator = fn (): bool => Auth::user()?->role === 'ADMINISTRATEUR';
        $isSelf = fn (?User $record): bool => $record !== null && Auth::id() === $record->id;

        return $schema
            ->components([
                TextInput::make('display_name')
                    ->label('Nom affiché')
                    ->required()
                    ->maxLength(80),
                TextInput::make('email')
                    ->label('E-mail')
                    ->email()
                    ->maxLength(190)
                    ->unique(ignoreRecord: true),
                TextInput::make('phone')
                    ->label('Téléphone')
                    ->tel()
                    ->maxLength(30)
                    ->unique(ignoreRecord: true),
                Select::make('role')
                    ->label('Rôle')
                    ->options([
                        'UTILISATEUR' => 'Utilisateur',
                        'MODERATEUR' => 'Modérateur',
                        'ADMINISTRATEUR' => 'Administrateur',
                    ])
                    ->helperText('Seul un administrateur peut modifier un rôle.')
                    ->hidden(fn (): bool => ! $isAdministrator())
                    ->disabled(fn (?User $record): bool => $isSelf($record))
                    ->required(),
                Select::make('status')
                    ->label('Statut du compte')
                    ->options([
                        'ACTIF' => 'Actif',
                        'SUSPENDU' => 'Suspendu',
                    ])
                    ->hidden(fn (): bool => ! $isAdministrator())
                    ->disabled(fn (?User $record): bool => $isSelf($record))
                    ->required(),
                Select::make('commune_id')
                    ->label('Commune')
                    ->relationship('commune', 'name')
                    ->searchable()
                    ->preload()
                    ->nullable(),
                Textarea::make('presentation')
                    ->label('Présentation')
                    ->rows(3)
                    ->columnSpanFull(),
                TextInput::make('password')
                    ->label('Mot de passe')
                    ->password()
                    ->revealable()
                    ->required(fn (string $operation): bool => $operation === 'create')
                    ->dehydrated(fn ($state): bool => filled($state))
                    ->minLength(8)
                    ->helperText('Laisser vide pour conserver le mot de passe actuel.'),
            ])
            ->columns(2);
    }
}
