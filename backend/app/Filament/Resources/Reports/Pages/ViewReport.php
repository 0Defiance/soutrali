<?php

namespace App\Filament\Resources\Reports\Pages;

use App\Filament\Actions\ReportModerationActions;
use App\Filament\Resources\Reports\ReportResource;
use Filament\Actions\Action;
use Filament\Resources\Pages\ViewRecord;

class ViewReport extends ViewRecord
{
    protected static string $resource = ReportResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Action::make('retour')
                ->label('Retour à la liste')
                ->color('gray')
                ->url(fn (): string => ReportResource::getUrl()),
            ReportModerationActions::claim(),
            ReportModerationActions::treat(),
            ReportModerationActions::reject(),
        ];
    }
}
