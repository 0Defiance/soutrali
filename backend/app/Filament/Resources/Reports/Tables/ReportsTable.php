<?php

namespace App\Filament\Resources\Reports\Tables;

use App\Filament\Actions\ReportModerationActions;
use App\Models\Report;
use Filament\Actions\ViewAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;

class ReportsTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->defaultSort('created_at', 'desc')
            ->columns([
                TextColumn::make('listing.title')
                    ->label('Annonce')
                    ->searchable()
                    ->limit(40)
                    ->tooltip(fn (Report $record): string => $record->listing->title ?? 'Annonce supprimée'),
                TextColumn::make('reporter.display_name')
                    ->label('Signalant')
                    ->limit(24)
                    ->placeholder('—'),
                TextColumn::make('reason')
                    ->label('Motif')
                    ->searchable()
                    ->limit(30),
                TextColumn::make('status')
                    ->label('Statut')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'NOUVEAU' => 'danger',
                        'EN_COURS' => 'warning',
                        'TRAITE' => 'success',
                        'REJETE' => 'gray',
                        default => 'gray',
                    })
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'NOUVEAU' => 'Nouveau',
                        'EN_COURS' => 'En cours',
                        'TRAITE' => 'Traité',
                        'REJETE' => 'Rejeté',
                        default => $state,
                    }),
                TextColumn::make('created_at')
                    ->label('Déposé le')
                    ->dateTime('d/m/Y H:i')
                    ->sortable(),
            ])
            ->filters([
                SelectFilter::make('status')
                    ->label('Statut')
                    ->options([
                        'NOUVEAU' => 'Nouveau',
                        'EN_COURS' => 'En cours',
                        'TRAITE' => 'Traité',
                        'REJETE' => 'Rejeté',
                    ]),
            ])
            ->recordActions([
                ViewAction::make()->label('Voir'),
                ReportModerationActions::claim(),
                ReportModerationActions::treat(),
                ReportModerationActions::reject(),
            ]);
    }
}
