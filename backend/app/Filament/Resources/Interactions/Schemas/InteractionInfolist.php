<?php

namespace App\Filament\Resources\Interactions\Schemas;

use Filament\Infolists\Components\TextEntry;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class InteractionInfolist
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Conversation')
                    ->schema([
                        TextEntry::make('status')
                            ->label('Statut')
                            ->badge()
                            ->color(fn (string $state): string => $state === 'OUVERTE' ? 'success' : 'gray')
                            ->formatStateUsing(fn (string $state): string => $state === 'OUVERTE' ? 'Ouverte' : $state),
                        TextEntry::make('created_at')
                            ->label('Ouvert le')
                            ->dateTime('d/m/Y H:i'),
                        TextEntry::make('messages_count')
                            ->label('Messages échangés')
                            ->counts('messages'),
                        TextEntry::make('updated_at')
                            ->label('Dernière activité')
                            ->dateTime('d/m/Y H:i'),
                    ])
                    ->columns(2),
                Section::make('Annonce concernée')
                    ->schema([
                        TextEntry::make('listing.title')
                            ->label('Titre'),
                        TextEntry::make('listing.status')
                            ->label('Statut de l’annonce')
                            ->badge()
                            ->color(fn (?string $state): string => match ($state) {
                                'PUBLIEE' => 'success',
                                'MASQUEE' => 'danger',
                                'CLOTUREE' => 'gray',
                                default => 'warning',
                            }),
                        TextEntry::make('listing.author.display_name')
                            ->label('Auteur'),
                        TextEntry::make('initiator.display_name')
                            ->label('Initiateur du fil'),
                    ])
                    ->columns(2),
            ]);
    }
}
