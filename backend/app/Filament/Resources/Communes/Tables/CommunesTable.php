<?php

namespace App\Filament\Resources\Communes\Tables;

use Filament\Actions\EditAction;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\TernaryFilter;
use Filament\Tables\Table;

class CommunesTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('name')
                    ->label('Nom')
                    ->searchable(),
                TextColumn::make('listings_count')
                    ->label('Annonces')
                    ->counts('listings')
                    ->badge()
                    ->color('info')
                    ->placeholder('0'),
                IconColumn::make('active')
                    ->label('Active')
                    ->boolean(),
                TextColumn::make('created_at')
                    ->label('Ajoutée le')
                    ->dateTime('d/m/Y')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                TernaryFilter::make('active')
                    ->label('Commune active'),
            ])
            ->recordActions([
                EditAction::make()->label('Modifier'),
            ]);
    }
}
