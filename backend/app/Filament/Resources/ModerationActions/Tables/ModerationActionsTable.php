<?php

namespace App\Filament\Resources\ModerationActions\Tables;

use App\Support\Moderation\Decision;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;

class ModerationActionsTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->defaultSort('acted_at', 'desc')
            ->columns([
                TextColumn::make('acted_at')
                    ->label('Horodatage')
                    ->dateTime('d/m/Y H:i')
                    ->sortable(),
                TextColumn::make('moderator.display_name')
                    ->label('Modérateur')
                    ->limit(24),
                TextColumn::make('decision')
                    ->label('Décision')
                    ->badge()
                    ->color(fn (string $state): string => match (Decision::tryFrom($state)) {
                        Decision::AnnonceMasquee, Decision::CompteSuspendu => 'danger',
                        Decision::AnnonceRepubliee, Decision::CompteReactive, Decision::SansSuite => 'success',
                        Decision::PriseEnCharge => 'warning',
                        default => 'gray',
                    })
                    ->formatStateUsing(fn (string $state): string => Decision::tryFrom($state)?->label() ?? $state),
                TextColumn::make('report.listing.title')
                    ->label('Annonce concernée')
                    ->limit(36)
                    ->placeholder('— Hors signalement —'),
                TextColumn::make('justification')
                    ->label('Justification')
                    ->limit(48)
                    ->placeholder('—')
                    ->wrap(),
                TextColumn::make('report.reason')
                    ->label('Motif du signalement')
                    ->limit(28)
                    ->placeholder('—'),
            ])
            ->filters([
                SelectFilter::make('decision')
                    ->label('Décision')
                    ->options(collect(Decision::cases())
                        ->mapWithKeys(function (Decision $decision): array {
                            return [$decision->value => $decision->label()];
                        })
                        ->all()),
            ]);
    }
}
