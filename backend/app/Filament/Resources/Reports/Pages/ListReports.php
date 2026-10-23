<?php

namespace App\Filament\Resources\Reports\Pages;

use App\Filament\Resources\Reports\ReportResource;
use Filament\Resources\Pages\ListRecords;

/**
 * Aucune action d’en-tête : un signalement ne se crée pas depuis le
 * back-office, il arrive de l’application (D-06).
 */
class ListReports extends ListRecords
{
    protected static string $resource = ReportResource::class;

    protected function getHeaderActions(): array
    {
        return [];
    }
}
