<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\Commune;
use App\Support\AbidjanGeolocation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class GeolocationController
{
    /**
     * Situe une position GPS sur le référentiel d'Abidjan (7 nov. 2026).
     *
     * Appelé par l'application après l'accord explicite de l'utilisateur.
     * Aucun service de géocodage externe n'intervient : la réponse vient du
     * référentiel local (quartiers et communes), ce qui garde la position
     * dans le périmètre du site. Hors zone desservie, la réponse le dit
     * franchement (`in_service_area: false`) au lieu d'inventer un quartier.
     */
    public function show(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
            'accuracy' => ['nullable', 'numeric', 'min:0', 'max:100000'],
        ]);

        $latitude = (float) $validated['latitude'];
        $longitude = (float) $validated['longitude'];
        $accuracy = isset($validated['accuracy']) ? (int) round((float) $validated['accuracy']) : null;

        $nearest = AbidjanGeolocation::nearestQuartier($latitude, $longitude);
        $inServiceArea = $nearest['distance_km'] <= AbidjanGeolocation::SERVICE_RADIUS_KM;
        $inCountry = AbidjanGeolocation::isInCountry($latitude, $longitude);

        $commune = $inServiceArea
            ? Commune::query()->where('name', $nearest['commune'])->first(['id', 'name'])
            : null;

        $quartier = $inServiceArea ? $nearest['quartier'] : null;
        $zone = $inServiceArea ? AbidjanGeolocation::zoneFor($nearest['commune']) : null;

        return response()->json([
            'data' => [
                'in_service_area' => $inServiceArea,
                'country' => $inServiceArea ? AbidjanGeolocation::COUNTRY : ($inCountry ? AbidjanGeolocation::COUNTRY : null),
                'city' => $inServiceArea ? AbidjanGeolocation::CITY : null,
                'commune' => $commune ? ['id' => $commune->id, 'name' => $commune->name] : null,
                'quartier' => $quartier,
                'zone' => $zone,
                'distance_m' => (int) round($nearest['distance_km'] * 1000),
                'accuracy_m' => $accuracy,
                'coordinates' => [
                    'latitude' => round($latitude, 6),
                    'longitude' => round($longitude, 6),
                ],
                'label' => $inServiceArea
                    ? AbidjanGeolocation::COUNTRY.' · '.AbidjanGeolocation::CITY.' · '.$nearest['commune'].' — '.$quartier
                    : null,
            ],
        ]);
    }
}
