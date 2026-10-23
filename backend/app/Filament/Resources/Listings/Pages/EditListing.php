<?php

namespace App\Filament\Resources\Listings\Pages;

use App\Filament\Resources\Listings\ListingResource;
use App\Models\Listing;
use App\Models\User;
use App\Support\Moderation\Decision;
use App\Support\Moderation\ReportModerator;
use Filament\Resources\Pages\EditRecord;

/**
 * Édition d’une annonce : la suppression n’existe pas (masquage à la
 * place) et tout changement de statut relevant de la modération
 * (masquage, republiage) est écrit au journal `moderation_actions`.
 */
class EditListing extends EditRecord
{
    protected static string $resource = ListingResource::class;

    private ?string $statusBeforeSave = null;

    protected function mutateFormDataBeforeSave(array $data): array
    {
        /** @var Listing $record */
        $record = $this->getRecord();
        $this->statusBeforeSave = $record->status;

        return $data;
    }

    protected function afterSave(): void
    {
        /** @var Listing $record */
        $record = $this->getRecord();
        $before = $this->statusBeforeSave;
        $this->statusBeforeSave = null;

        if ($before === null || $before === $record->status) {
            return;
        }

        $decision = match (true) {
            $record->status === 'MASQUEE' => Decision::AnnonceMasquee,
            $record->status === 'PUBLIEE' && $before === 'MASQUEE' => Decision::AnnonceRepubliee,
            default => null,
        };

        if ($decision === null) {
            return;
        }

        $moderator = auth()->user();

        if (! $moderator instanceof User) {
            return;
        }

        ReportModerator::log(null, $decision, 'Changement de statut depuis la fiche annonce.', $moderator);
    }

    protected function getHeaderActions(): array
    {
        return [];
    }
}
