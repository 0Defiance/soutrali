<?php

namespace App\Filament\Resources\Categories\Tables;

use App\Models\Category;
use Filament\Actions\EditAction;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\TernaryFilter;
use Filament\Tables\Table;

class CategoriesTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('name')
                    ->label('Nom')
                    ->searchable(),
                TextColumn::make('icon')
                    ->label('Icône')
                    ->badge()
                    ->color('gray')
                    ->formatStateUsing(fn (string $state): string => Category::ICONS[$state] ?? $state),
                TextColumn::make('description')
                    ->label('Description')
                    ->limit(48)
                    ->placeholder('—'),
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
                    ->label('Créée le')
                    ->dateTime('d/m/Y')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                TernaryFilter::make('active')
                    ->label('Catégorie active'),
            ])
            ->recordActions([
                EditAction::make()->label('Modifier'),
            ]);
    }
}
