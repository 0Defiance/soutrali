<?php

namespace App\Filament\Resources\Reports\Schemas;

use App\Filament\Resources\Listings\ListingResource;
use App\Models\ModerationAction;
use App\Models\Report;
use App\Support\Moderation\Decision;
use Filament\Infolists\Components\TextEntry;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class ReportInfolist
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Signalement')
                    ->schema([
                        TextEntry::make('status')
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
                        TextEntry::make('reason')
                            ->label('Motif'),
                        TextEntry::make('created_at')
                            ->label('Déposé le')
                            ->dateTime('d/m/Y H:i'),
                        TextEntry::make('details')
                            ->label('Détails fournis')
                            ->placeholder('Aucun détail fourni.')
                            ->markdown()
                            ->columnSpanFull(),
                    ])
                    ->columns(3),
                Section::make('Annonce visée')
                    ->schema([
                        TextEntry::make('listing.title')
                            ->label('Titre')
                            ->limit(60)
                            ->url(fn (Report $record): ?string => $record->listing
                                ? ListingResource::getUrl('edit', ['record' => $record->listing])
                                : null)
                            ->color('primary'),
                        TextEntry::make('listing.status')
                            ->label('Statut de l’annonce')
                            ->badge()
                            ->color(fn (?string $state): string => match ($state) {
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
                        TextEntry::make('listing.commune.name')
                            ->label('Commune')
                            ->placeholder('—'),
                        TextEntry::make('listing.author.display_name')
                            ->label('Auteur')
                            ->placeholder('—'),
                    ])
                    ->columns(2),
                Section::make('Signalant')
                    ->schema([
                        TextEntry::make('reporter.display_name')
                            ->label('Compte')
                            ->placeholder('—'),
                        TextEntry::make('reporter.email')
                            ->label('E-mail')
                            ->placeholder('—'),
                    ])
                    ->columns(2),
                Section::make('Journal de modération')
                    ->schema([
                        TextEntry::make('moderationActions')
                            ->label('Décisions enregistrées')
                            ->placeholder('Aucune décision enregistrée pour l’instant.')
                            ->formatStateUsing(function (?Report $record): string {
                                // Lecture directe depuis l’enregistrement : l’état
                                // résolu par Filament pour une relation n’est pas
                                // garanti d’être une collection.
                                if ($record === null) {
                                    return 'Aucune décision enregistrée pour l’instant.';
                                }

                                $actions = $record->moderationActions()
                                    ->with('moderator')
                                    ->latest('acted_at')
                                    ->get();

                                return $actions->map(function (ModerationAction $action): string {
                                    $line = sprintf(
                                        '%s · %s · %s',
                                        $action->acted_at?->format('d/m/Y H:i') ?? '—',
                                        Decision::tryFrom($action->decision)?->label() ?? $action->decision,
                                        $action->moderator->display_name ?? '—',
                                    );

                                    if (filled($action->justification)) {
                                        $line .= ' — '.$action->justification;
                                    }

                                    return '• '.$line;
                                })->implode("\n");
                            })
                            ->columnSpanFull(),
                    ]),
            ]);
    }
}
