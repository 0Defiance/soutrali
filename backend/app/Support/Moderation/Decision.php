<?php

namespace App\Support\Moderation;

/**
 * Décisions de modération tracées dans `moderation_actions` (D-06).
 * Les libellés servent aux badges du back-office ; les valeurs sont
 * stockées en base et ne doivent pas changer sans migration.
 */
enum Decision: string
{
    case PriseEnCharge = 'PRISE_EN_CHARGE';
    case AnnonceMasquee = 'ANNONCE_MASQUEE';
    case AnnonceRepubliee = 'ANNONCE_REPUBLIEE';
    case SignalementRejete = 'SIGNALEMENT_REJETE';
    case SansSuite = 'SANS_SUITE';
    case Transmis = 'TRANSMIS';
    case CompteSuspendu = 'COMPTE_SUSPENDU';
    case CompteReactive = 'COMPTE_REACTIVE';

    public function label(): string
    {
        return match ($this) {
            self::PriseEnCharge => 'Prise en charge',
            self::AnnonceMasquee => 'Annonce masquée',
            self::AnnonceRepubliee => 'Annonce republiée',
            self::SignalementRejete => 'Signalement rejeté',
            self::SansSuite => 'Classé sans suite',
            self::Transmis => 'Transmis à l’administrateur',
            self::CompteSuspendu => 'Compte suspendu',
            self::CompteReactive => 'Compte réactivé',
        };
    }

    /**
     * Nouveau statut du signalement traité par cette décision.
     */
    public function reportStatus(): string
    {
        return match ($this) {
            self::PriseEnCharge, self::Transmis => 'EN_COURS',
            self::AnnonceMasquee, self::SansSuite => 'TRAITE',
            self::SignalementRejete => 'REJETE',
            default => 'TRAITE',
        };
    }

    /**
     * Si la décision masque l’annonce visée.
     */
    public function hidesListing(): bool
    {
        return $this === self::AnnonceMasquee;
    }
}
