<?php

namespace App\Filament\Resources\Users\Pages;

use App\Filament\Resources\Users\UserResource;
use Filament\Resources\Pages\EditRecord;

/**
 * Édition d’un compte : pas de suppression (décision documentée — un
 * compte se suspend, il ne se supprime pas), le rôle et le statut sont
 * protégés côté formulaire.
 */
class EditUser extends EditRecord
{
    protected static string $resource = UserResource::class;

    protected function getHeaderActions(): array
    {
        return [];
    }
}
