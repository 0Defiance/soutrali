<?php

namespace App\Filament\Resources\Users\Tables;

use App\Models\User;
use App\Support\Moderation\Decision;
use App\Support\Moderation\ReportModerator;
use Filament\Actions\Action;
use Filament\Actions\EditAction;
use Filament\Forms\Components\Textarea;
use Filament\Notifications\Notification;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Support\Facades\Auth;

class UsersTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('display_name')
                    ->label('Nom affiché')
                    ->searchable()
                    ->limit(28),
                TextColumn::make('email')
                    ->label('E-mail')
                    ->searchable()
                    ->limit(32)
                    ->copyable()
                    ->tooltip('Cliquer pour copier'),
                TextColumn::make('role')
                    ->label('Rôle')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'ADMINISTRATEUR' => 'danger',
                        'MODERATEUR' => 'warning',
                        default => 'gray',
                    })
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'ADMINISTRATEUR' => 'Administrateur',
                        'MODERATEUR' => 'Modérateur',
                        default => 'Utilisateur',
                    }),
                TextColumn::make('status')
                    ->label('Statut')
                    ->badge()
                    ->color(fn (string $state): string => $state === 'ACTIF' ? 'success' : 'danger')
                    ->formatStateUsing(fn (string $state): string => $state === 'ACTIF' ? 'Actif' : 'Suspendu'),
                TextColumn::make('commune.name')
                    ->label('Commune')
                    ->placeholder('—')
                    ->limit(20),
                TextColumn::make('listings_count')
                    ->label('Annonces')
                    ->counts('listings')
                    ->badge()
                    ->color('info')
                    ->placeholder('0'),
                TextColumn::make('created_at')
                    ->label('Inscrit le')
                    ->dateTime('d/m/Y')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                SelectFilter::make('role')
                    ->label('Rôle')
                    ->options([
                        'UTILISATEUR' => 'Utilisateur',
                        'MODERATEUR' => 'Modérateur',
                        'ADMINISTRATEUR' => 'Administrateur',
                    ]),
                SelectFilter::make('status')
                    ->label('Statut')
                    ->options([
                        'ACTIF' => 'Actif',
                        'SUSPENDU' => 'Suspendu',
                    ]),
            ])
            ->recordActions([
                EditAction::make()->label('Modifier'),
                self::suspend(),
                self::reactivate(),
            ]);
    }

    private static function suspend(): Action
    {
        return Action::make('suspendre')
            ->label('Suspendre')
            ->icon(Heroicon::OutlinedNoSymbol)
            ->color('danger')
            ->visible(fn (User $record): bool => $record->status === 'ACTIF' && Auth::id() !== $record->id)
            ->modalHeading('Suspendre le compte')
            ->modalDescription('Le compte ne pourra plus se connecter ni publier. Ses annonces restent en place.')
            ->schema([
                Textarea::make('justification')
                    ->label('Justification')
                    ->rows(3)
                    ->required()
                    ->placeholder('Consignée dans le journal de modération.'),
            ])
            ->action(function (User $record, array $data): void {
                $moderator = Auth::user();

                if (! $moderator instanceof User) {
                    abort(403);
                }

                $record->update(['status' => 'SUSPENDU']);

                ReportModerator::log(null, Decision::CompteSuspendu, $data['justification'], $moderator);

                Notification::make()
                    ->title('Compte suspendu')
                    ->body($record->display_name)
                    ->success()
                    ->send();
            });
    }

    private static function reactivate(): Action
    {
        return Action::make('reactiver')
            ->label('Réactiver')
            ->icon(Heroicon::OutlinedCheckBadge)
            ->color('success')
            ->visible(fn (User $record): bool => $record->status === 'SUSPENDU')
            ->modalHeading('Réactiver le compte')
            ->modalDescription('Le compte retrouve l’accès à l’application.')
            ->schema([
                Textarea::make('justification')
                    ->label('Justification')
                    ->rows(3)
                    ->placeholder('Consignée dans le journal de modération.'),
            ])
            ->action(function (User $record, array $data): void {
                $moderator = Auth::user();

                if (! $moderator instanceof User) {
                    abort(403);
                }

                $record->update(['status' => 'ACTIF']);

                ReportModerator::log(null, Decision::CompteReactive, $data['justification'] ?? null, $moderator);

                Notification::make()
                    ->title('Compte réactivé')
                    ->body($record->display_name)
                    ->success()
                    ->send();
            });
    }
}
