<?php

namespace App\Support;

/**
 * Référentiel géographique local d’Abidjan (7 nov. 2026).
 *
 * Le site n’appelle aucun service de géocodage externe : la position GPS du
 * navigateur est confrontée à ce référentiel pour retrouver la commune et le
 * quartier les plus proches. Les coordonnées sont celles du centre de chaque
 * quartier (précision de l’ordre du kilomètre) ; elles servent à **situer**
 * l’utilisateur, pas à l’adresser au numéro de rue près — l’écart réel est
 * renvoyé à l’application (`distance_km`) pour rester honnête.
 */
final class AbidjanGeolocation
{
    public const COUNTRY = 'Côte d’Ivoire';

    public const CITY = 'Abidjan';

    /** Au-delà, la position n’est plus considérée comme desservie. */
    public const SERVICE_RADIUS_KM = 60.0;

    /** Emprise approximative de la Côte d’Ivoire (latitudes/longitudes). */
    public const COUNTRY_BOUNDS = [
        'latitude' => [4.3, 10.75],
        'longitude' => [-8.6, -2.4],
    ];

    /**
     * Zone d’Abidjan par commune, telle qu’on la nomme localement.
     *
     * @var array<string, string>
     */
    public const ZONES = [
        'Abobo' => 'Abidjan Nord',
        'Anyama' => 'Abidjan Nord',
        'Attécoubé' => 'Abidjan Ouest',
        'Songon' => 'Abidjan Ouest',
        'Yopougon' => 'Abidjan Ouest',
        'Adjamé' => 'Abidjan Centre',
        'Plateau' => 'Abidjan Centre',
        'Bingerville' => 'Abidjan Est',
        'Cocody' => 'Abidjan Est',
        'Koumassi' => 'Abidjan Sud',
        'Marcory' => 'Abidjan Sud',
        'Port-Bouët' => 'Abidjan Sud',
        'Treichville' => 'Abidjan Sud',
    ];

    /**
     * Centres des quartiers couverts, par commune.
     *
     * @var list<array{name: string, commune: string, latitude: float, longitude: float}>
     */
    public const QUARTIERS = [
        ['name' => 'Abobo Centre', 'commune' => 'Abobo', 'latitude' => 5.4161, 'longitude' => -4.0159],
        ['name' => 'Abobo Baoulé', 'commune' => 'Abobo', 'latitude' => 5.4250, 'longitude' => -4.0070],
        ['name' => 'Gbagba', 'commune' => 'Abobo', 'latitude' => 5.4060, 'longitude' => -4.0210],
        ['name' => 'PK18', 'commune' => 'Abobo', 'latitude' => 5.4350, 'longitude' => -4.0330],
        ['name' => 'Adjamé Centre', 'commune' => 'Adjamé', 'latitude' => 5.3599, 'longitude' => -4.0244],
        ['name' => 'Bracodi', 'commune' => 'Adjamé', 'latitude' => 5.3690, 'longitude' => -4.0200],
        ['name' => 'Liberté', 'commune' => 'Adjamé', 'latitude' => 5.3500, 'longitude' => -4.0230],
        ['name' => 'Williamsville', 'commune' => 'Adjamé', 'latitude' => 5.3640, 'longitude' => -4.0320],
        ['name' => 'Anyama Centre', 'commune' => 'Anyama', 'latitude' => 5.4944, 'longitude' => -4.0522],
        ['name' => 'Attécoubé Centre', 'commune' => 'Attécoubé', 'latitude' => 5.3350, 'longitude' => -4.0370],
        ['name' => 'Agban', 'commune' => 'Attécoubé', 'latitude' => 5.3380, 'longitude' => -4.0280],
        ['name' => 'Locodjro', 'commune' => 'Attécoubé', 'latitude' => 5.3270, 'longitude' => -4.0450],
        ['name' => 'Bingerville Centre', 'commune' => 'Bingerville', 'latitude' => 5.3556, 'longitude' => -3.8853],
        ['name' => 'Cocody Centre', 'commune' => 'Cocody', 'latitude' => 5.3470, 'longitude' => -3.9870],
        ['name' => 'Angré', 'commune' => 'Cocody', 'latitude' => 5.3970, 'longitude' => -3.9730],
        ['name' => 'Deux-Plateaux', 'commune' => 'Cocody', 'latitude' => 5.3760, 'longitude' => -3.9950],
        ['name' => 'Riviera 1', 'commune' => 'Cocody', 'latitude' => 5.3600, 'longitude' => -3.9560],
        ['name' => 'Riviera 3', 'commune' => 'Cocody', 'latitude' => 5.3480, 'longitude' => -3.9430],
        ['name' => 'Riviera 4', 'commune' => 'Cocody', 'latitude' => 5.3560, 'longitude' => -3.9330],
        ['name' => 'Blockhaus', 'commune' => 'Cocody', 'latitude' => 5.3400, 'longitude' => -3.9930],
        ['name' => 'Abatta', 'commune' => 'Cocody', 'latitude' => 5.3740, 'longitude' => -3.9660],
        ['name' => 'Koumassi Centre', 'commune' => 'Koumassi', 'latitude' => 5.2952, 'longitude' => -3.9509],
        ['name' => 'Remblais', 'commune' => 'Koumassi', 'latitude' => 5.2990, 'longitude' => -3.9440],
        ['name' => 'Zone industrielle', 'commune' => 'Koumassi', 'latitude' => 5.2870, 'longitude' => -3.9590],
        ['name' => 'Marcory Centre', 'commune' => 'Marcory', 'latitude' => 5.3010, 'longitude' => -3.9870],
        ['name' => 'Anoumabo', 'commune' => 'Marcory', 'latitude' => 5.3050, 'longitude' => -3.9920],
        ['name' => 'Zone 4', 'commune' => 'Marcory', 'latitude' => 5.2920, 'longitude' => -3.9980],
        ['name' => 'Remblais', 'commune' => 'Marcory', 'latitude' => 5.2940, 'longitude' => -3.9930],
        ['name' => 'Plateau Centre', 'commune' => 'Plateau', 'latitude' => 5.3240, 'longitude' => -4.0190],
        ['name' => 'Cité Administrative', 'commune' => 'Plateau', 'latitude' => 5.3300, 'longitude' => -4.0150],
        ['name' => 'Port-Bouët Centre', 'commune' => 'Port-Bouët', 'latitude' => 5.2530, 'longitude' => -3.9300],
        ['name' => 'Vridi', 'commune' => 'Port-Bouët', 'latitude' => 5.2760, 'longitude' => -3.9400],
        ['name' => 'Gonzagueville', 'commune' => 'Port-Bouët', 'latitude' => 5.2460, 'longitude' => -3.9200],
        ['name' => 'Songon Centre', 'commune' => 'Songon', 'latitude' => 5.3120, 'longitude' => -4.2520],
        ['name' => 'Adiapodoumé', 'commune' => 'Songon', 'latitude' => 5.3400, 'longitude' => -4.2200],
        ['name' => 'Treichville Centre', 'commune' => 'Treichville', 'latitude' => 5.2930, 'longitude' => -4.0110],
        ['name' => 'Arras', 'commune' => 'Treichville', 'latitude' => 5.2880, 'longitude' => -4.0060],
        ['name' => 'Marché de Treichville', 'commune' => 'Treichville', 'latitude' => 5.2960, 'longitude' => -4.0140],
        ['name' => 'Yopougon Centre', 'commune' => 'Yopougon', 'latitude' => 5.3390, 'longitude' => -4.0730],
        ['name' => 'Niangon', 'commune' => 'Yopougon', 'latitude' => 5.3240, 'longitude' => -4.0880],
        ['name' => 'Sicogi', 'commune' => 'Yopougon', 'latitude' => 5.3510, 'longitude' => -4.0800],
        ['name' => 'Toits Rouges', 'commune' => 'Yopougon', 'latitude' => 5.3350, 'longitude' => -4.0660],
        ['name' => 'Selmer', 'commune' => 'Yopougon', 'latitude' => 5.3280, 'longitude' => -4.0770],
        ['name' => 'Wassa', 'commune' => 'Yopougon', 'latitude' => 5.3180, 'longitude' => -4.0870],
    ];

    /**
     * Quartier le plus proche d’une position, avec sa commune et l’écart.
     *
     * @return array{quartier: string, commune: string, distance_km: float}
     */
    public static function nearestQuartier(float $latitude, float $longitude): array
    {
        $nearest = self::QUARTIERS[0];
        $smallest = self::distanceKm($latitude, $longitude, $nearest['latitude'], $nearest['longitude']);

        foreach (self::QUARTIERS as $quartier) {
            $distance = self::distanceKm($latitude, $longitude, $quartier['latitude'], $quartier['longitude']);

            if ($distance < $smallest) {
                $nearest = $quartier;
                $smallest = $distance;
            }
        }

        return [
            'quartier' => $nearest['name'],
            'commune' => $nearest['commune'],
            'distance_km' => round($smallest, 3),
        ];
    }

    /**
     * Distance orthodromique (formule de haversine), en kilomètres.
     */
    public static function distanceKm(float $fromLatitude, float $fromLongitude, float $toLatitude, float $toLongitude): float
    {
        $earthRadiusKm = 6371.0;
        $dLatitude = deg2rad($toLatitude - $fromLatitude);
        $dLongitude = deg2rad($toLongitude - $fromLongitude);

        $a = sin($dLatitude / 2) ** 2
            + cos(deg2rad($fromLatitude)) * cos(deg2rad($toLatitude)) * sin($dLongitude / 2) ** 2;

        return $earthRadiusKm * 2 * atan2(sqrt($a), sqrt(1 - $a));
    }

    /**
     * La position est-elle dans l’emprise du pays ?
     */
    public static function isInCountry(float $latitude, float $longitude): bool
    {
        [$minLatitude, $maxLatitude] = self::COUNTRY_BOUNDS['latitude'];
        [$minLongitude, $maxLongitude] = self::COUNTRY_BOUNDS['longitude'];

        return $latitude >= $minLatitude && $latitude <= $maxLatitude
            && $longitude >= $minLongitude && $longitude <= $maxLongitude;
    }

    /**
     * Zone d’Abidjan (« Nord », « Sud »…) associée à une commune.
     */
    public static function zoneFor(string $commune): string
    {
        return self::ZONES[$commune] ?? self::CITY;
    }
}
