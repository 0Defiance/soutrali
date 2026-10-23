<?php

namespace App\Filament\Widgets;

use App\Filament\Resources\Reports\ReportResource;
use App\Models\Report;
use Filament\Actions\ViewAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget;

/**
 * File des signalements les plus récents, avec lien direct vers leur
 * page de traitement : c’est la porte d’entrée quotidienne du
 * modérateur.
 */
class LatestReportsWidget extends TableWidget
{
    protected static ?int $sort = 2;

    public function table(Table $table): Table
    {
        return $table
            ->heading('Signalements récents')
            ->query(Report::query()->latest()->limit(6))
            ->columns([
                TextColumn::make('listing.title')
                    ->label('Annonce')
                    ->limit(34)
                    ->placeholder('—'),
                TextColumn::make('reason')
                    ->label('Motif')
                    ->limit(24),
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
                    ->dateTime('d/m/Y H:i'),
            ])
            ->recordActions([
                ViewAction::make()
                    ->label('Traiter')
                    ->url(fn (Report $record): string => ReportResource::getUrl('view', ['record' => $record])),
            ]);
    }
}
