<?php

namespace App\Filament\Resources\Interactions\RelationManagers;

use Filament\Resources\RelationManagers\RelationManager;
use Filament\Schemas\Schema;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

/**
 * Messages d’un fil : strictement consultables. L’envoi de messages
 * appartient à l’application (D-05), jamais au back-office.
 */
class MessagesRelationManager extends RelationManager
{
    protected static string $relationship = 'messages';

    public function form(Schema $schema): Schema
    {
        return $schema->components([]);
    }

    public function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('body')
            ->columns([
                TextColumn::make('sender.display_name')
                    ->label('Expéditeur')
                    ->limit(24),
                TextColumn::make('body')
                    ->label('Message')
                    ->limit(80)
                    ->tooltip(fn (string $state): string => $state)
                    ->wrap(),
                TextColumn::make('read_at')
                    ->label('Lu le')
                    ->dateTime('d/m/Y H:i')
                    ->badge()
                    ->color(fn ($state): string => $state === null ? 'warning' : 'success')
                    ->formatStateUsing(fn ($state): string => $state === null ? 'Non lu' : 'Lu')
                    ->placeholder('Non lu'),
                TextColumn::make('created_at')
                    ->label('Envoyé le')
                    ->dateTime('d/m/Y H:i')
                    ->sortable(),
            ]);
    }
}
