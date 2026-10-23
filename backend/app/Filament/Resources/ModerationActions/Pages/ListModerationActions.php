<?php

namespace App\Filament\Resources\ModerationActions\Pages;

use App\Filament\Resources\ModerationActions\ModerationActionResource;
use Filament\Resources\Pages\ListRecords;

/**
 * Liste du journal : aucune action d’en-tête — le journal ne se crée
 * pas à la main, il se remplit tout seul.
 */
class ListModerationActions extends ListRecords
{
    protected static string $resource = ModerationActionResource::class;

    protected function getHeaderActions(): array
    {
        return [];
    }
}
