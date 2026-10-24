<?php

namespace App\Console\Commands;

use App\Models\Listing;
use Illuminate\Console\Command;

/**
 * Publication programmée : les annonces dont `publish_at` est atteinte
 * passent en statut PUBLIEE. La visibilité publique ne dépend pas de
 * cette commande (le scope `published` inclut les programmées échues) ;
 * elle sert à garder les statuts justes côté auteur et back-office.
 */
class PublishDueListings extends Command
{
    protected $signature = 'soutrali:publish-due';

    protected $description = 'Passe en statut PUBLIEE les annonces programmées dont la date de publication est atteinte.';

    public function handle(): int
    {
        $count = Listing::query()
            ->where('status', 'BROUILLON')
            ->whereNotNull('publish_at')
            ->where('publish_at', '<=', now())
            ->update([
                'status' => 'PUBLIEE',
                'updated_at' => now(),
            ]);

        $this->info("Annonces programmées publiées : {$count}.");

        return self::SUCCESS;
    }
}
