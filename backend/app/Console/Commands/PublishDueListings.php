<?php

namespace App\Console\Commands;

use App\Mail\ListingPublishedMail;
use App\Models\Listing;
use App\Support\Mail\Outbox;
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
        $due = Listing::query()
            ->where('status', 'BROUILLON')
            ->whereNotNull('publish_at')
            ->where('publish_at', '<=', now())
            ->with('author:id,display_name,email')
            ->get();

        foreach ($due as $listing) {
            $listing->update([
                'status' => 'PUBLIEE',
                'updated_at' => now(),
            ]);

            // Confirmation d’annonce publiée (F-09), identique aux deux
            // autres chemins de publication. Le mail part dès la bascule.
            if ($listing->author !== null) {
                Outbox::send($listing->author->email, new ListingPublishedMail($listing));
            }
        }

        $count = $due->count();

        $this->info("Annonces programmées publiées : {$count}.");

        return self::SUCCESS;
    }
}
