<?php

namespace App\Filament\Resources\Interactions\Tables;

use Filament\Actions\ViewAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;

class InteractionsTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('listing.title')
                    ->label('Annonce')
                    ->searchable()
                    ->limit(36),
                TextColumn::make('initiator.display_name')
                    ->label('Initiateur')
                    ->limit(24),
                TextColumn::make('listing.author.display_name')
                    ->label('Auteur de l’annonce')
                    ->limit(24),
                TextColumn::make('status')
                    ->label('Statut')
                    ->badge()
                    ->color(fn (string $state): string => $state === 'OUVERTE' ? 'success' : 'gray')
                    ->formatStateUsing(fn (string $state): string => $state === 'OUVERTE' ? 'Ouverte' : $state),
                TextColumn::make('messages_count')
                    ->label('Messages')
                    ->counts('messages')
                    ->badge()
                    ->color('info'),
                TextColumn::make('created_at')
                    ->label('Ouvert le')
                    ->dateTime('d/m/Y H:i')
                    ->sortable(),
            ])
            ->filters([
                SelectFilter::make('status')
                    ->label('Statut')
                    ->options([
                        'OUVERTE' => 'Ouverte',
                    ]),
            ])
            ->recordActions([
                ViewAction::make()->label('Consulter'),
            ]);
    }
}
