<?php

namespace App\Support\Moderation;

use App\Models\ModerationAction;
use App\Models\Report;
use App\Models\User;

/**
 * Applique une décision de modération et trace l’action (D-06).
 *
 * Aucune décision n’est prise directement dans une ressource Filament :
 * tout passe par cette classe, de sorte que le journal `moderation_actions`
 * soit complet et testable sans interface.
 */
final class ReportModerator
{
    /**
     * Décision prise sur un signalement : change son statut, masque
     * l’annonce si la décision l’exige, puis enregistre la trace.
     */
    public static function apply(Report $report, Decision $decision, ?string $justification, User $moderator): ModerationAction
    {
        $report->update(['status' => $decision->reportStatus()]);

        if ($decision->hidesListing()) {
            // Le masquage ne s’applique qu’à une annonce publiée : sur une
            // annonce déjà clôturée, il ferait perdre le statut « Clôturée »
            // à l’auteur sans rien changer à la visibilité publique.
            $listing = $report->listing;

            if ($listing !== null && $listing->isLive()) {
                $listing->update(['status' => 'MASQUEE']);
            }
        }

        return self::log($report, $decision, $justification, $moderator);
    }

    /**
     * Trace seule, pour les actions menées hors signalement (masquage ou
     * republiage d’une annonce, suspension ou réactivation d’un compte).
     */
    public static function log(?Report $report, Decision $decision, ?string $justification, User $moderator): ModerationAction
    {
        return ModerationAction::create([
            'report_id' => $report?->id,
            'moderator_id' => $moderator->id,
            'decision' => $decision->value,
            'justification' => $justification,
            'acted_at' => now(),
        ]);
    }
}
