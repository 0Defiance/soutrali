<?php

namespace App\Filament\Resources\Interactions\Pages;

use App\Filament\Resources\Interactions\InteractionResource;
use Filament\Resources\Pages\ListRecords;

/**
 * Aucune action d’en-tête : les fils se créent dans l’application
 * (D-05), le back-office les consulte.
 */
class ListInteractions extends ListRecords
{
    protected static string $resource = InteractionResource::class;

    protected function getHeaderActions(): array
    {
        return [];
    }
}
