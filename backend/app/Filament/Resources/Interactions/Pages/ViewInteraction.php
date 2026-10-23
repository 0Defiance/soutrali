<?php

namespace App\Filament\Resources\Interactions\Pages;

use App\Filament\Resources\Interactions\InteractionResource;
use App\Filament\Resources\Interactions\RelationManagers\MessagesRelationManager;
use Filament\Actions\Action;
use Filament\Resources\Pages\ViewRecord;

class ViewInteraction extends ViewRecord
{
    protected static string $resource = InteractionResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Action::make('retour')
                ->label('Retour à la liste')
                ->color('gray')
                ->url(fn (): string => InteractionResource::getUrl()),
        ];
    }

    public function getRelationManagers(): array
    {
        return [
            MessagesRelationManager::class,
        ];
    }
}
