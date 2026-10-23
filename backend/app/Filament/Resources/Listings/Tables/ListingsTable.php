<?php

namespace App\Filament\Resources\Listings\Tables;

use App\Models\Listing;
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

class ListingsTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('title')
                    ->label('Titre')
                    ->searchable()
                    ->limit(40)
                    ->tooltip(fn (Listing $record): string => $record->title),
                TextColumn::make('author.display_name')
                    ->label('Auteur')
                    ->limit(24),
                TextColumn::make('category.name')
                    ->label('Catégorie')
                    ->limit(28)
                    ->placeholder('—'),
                TextColumn::make('commune.name')
                    ->label('Commune'),
                TextColumn::make('type')
                    ->label('Type')
                    ->badge()
                    ->color(fn (string $state): string => $state === 'DEMANDE' ? 'info' : 'primary')
                    ->formatStateUsing(fn (string $state): string => $state === 'DEMANDE' ? 'Demande' : 'Offre'),
                TextColumn::make('status')
                    ->label('Statut')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'PUBLIEE' => 'success',
                        'MASQUEE' => 'danger',
                        'CLOTUREE' => 'gray',
                        default => 'warning',
                    })
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'PUBLIEE' => 'Publiée',
                        'MASQUEE' => 'Masquée',
                        'CLOTUREE' => 'Clôturée',
                        'BROUILLON' => 'Brouillon',
                        default => $state,
                    }),
                TextColumn::make('budget')
                    ->label('Budget (FCFA)')
                    ->numeric()
                    ->placeholder('—')
                    ->sortable(),
                TextColumn::make('created_at')
                    ->label('Publiée le')
                    ->dateTime('d/m/Y')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                SelectFilter::make('status')
                    ->label('Statut')
                    ->options([
                        'PUBLIEE' => 'Publiée',
                        'MASQUEE' => 'Masquée',
                        'CLOTUREE' => 'Clôturée',
                        'BROUILLON' => 'Brouillon',
                    ]),
                SelectFilter::make('type')
                    ->label('Type')
                    ->options([
                        'DEMANDE' => 'Demande',
                        'OFFRE' => 'Offre',
                    ]),
                SelectFilter::make('commune')
                    ->label('Commune')
                    ->relationship('commune', 'name'),
                SelectFilter::make('category')
                    ->label('Catégorie')
                    ->relationship('category', 'name'),
            ])
            ->recordActions([
                EditAction::make()->label('Modifier'),
                self::mask(),
                self::publish(),
            ]);
    }

    /**
     * Masquage d’une annonce : décision tracée dans le journal de
     * modération, justification requise.
     */
    private static function mask(): Action
    {
        return Action::make('masquer')
            ->label('Masquer')
            ->icon(Heroicon::OutlinedEyeSlash)
            ->color('danger')
            ->visible(fn (Listing $record): bool => in_array($record->status, ['PUBLIEE', 'BROUILLON'], true))
            ->modalHeading('Masquer l’annonce')
            ->modalDescription('Elle disparaîtra de l’application pour tous les utilisateurs ; son auteur la verra comme « Masquée ».')
            ->schema([
                Textarea::make('justification')
                    ->label('Justification')
                    ->rows(3)
                    ->required()
                    ->placeholder('Consignée dans le journal de modération.'),
            ])
            ->action(function (Listing $record, array $data): void {
                $moderator = auth()->user();

                if (! $moderator instanceof User) {
                    abort(403);
                }

                $record->update(['status' => 'MASQUEE']);

                ReportModerator::log(null, Decision::AnnonceMasquee, $data['justification'], $moderator);

                Notification::make()
                    ->title('Annonce masquée')
                    ->success()
                    ->send();
            });
    }

    /**
     * Republiation d’une annonce masquée : décision tracée également.
     */
    private static function publish(): Action
    {
        return Action::make('republier')
            ->label('Republier')
            ->icon(Heroicon::OutlinedNewspaper)
            ->color('success')
            ->visible(fn (Listing $record): bool => $record->status === 'MASQUEE')
            ->modalHeading('Republier l’annonce')
            ->modalDescription('Elle redevient visible pour tous les utilisateurs de l’application.')
            ->schema([
                Textarea::make('justification')
                    ->label('Justification')
                    ->rows(3)
                    ->placeholder('Consignée dans le journal de modération.'),
            ])
            ->action(function (Listing $record, array $data): void {
                $moderator = auth()->user();

                if (! $moderator instanceof User) {
                    abort(403);
                }

                $record->update(['status' => 'PUBLIEE']);

                ReportModerator::log(null, Decision::AnnonceRepubliee, $data['justification'] ?? null, $moderator);

                Notification::make()
                    ->title('Annonce republiée')
                    ->success()
                    ->send();
            });
    }
}
