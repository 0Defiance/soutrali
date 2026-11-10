<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\Category;
use App\Models\Commune;
use Illuminate\Http\JsonResponse;

class PublicReferenceController
{
    /**
     * Catégories actives, telles qu'administrées par la MOA (D-07), avec
     * la clé d'icône du service (26 oct. 2026) et le nombre d'annonces
     * publiées (7 nov. 2026) : le bloc « Tous les services » montre ainsi
     * à l'utilisateur quels services ont déjà des annonces disponibles.
     */
    public function categories(): JsonResponse
    {
        $categories = Category::query()
            ->where('active', true)
            ->withCount(['listings' => fn ($query) => $query->published()])
            ->orderBy('name')
            ->get(['id', 'name', 'description', 'icon'])
            ->map(fn (Category $category) => [
                'id' => $category->id,
                'name' => $category->name,
                'description' => $category->description,
                'icon' => $category->icon,
                'listings_count' => $category->listings_count,
            ]);

        return response()->json(['data' => $categories]);
    }

    /**
     * Communes actives du référentiel d'Abidjan (D-03), avec leurs
     * coordonnées depuis le 7 nov. 2026. `is_zone` distingue le choix
     * « Plusieurs communes », qui n'est pas une commune du District : le site
     * compte ainsi treize communes, pas quatorze.
     */
    public function communes(): JsonResponse
    {
        $communes = Commune::query()
            ->where('active', true)
            ->orderBy('name')
            ->get(['id', 'name', 'latitude', 'longitude'])
            ->map(fn (Commune $commune) => [
                'id' => $commune->id,
                'name' => $commune->name,
                'latitude' => $commune->latitude,
                'longitude' => $commune->longitude,
                'is_zone' => $commune->isZone(),
            ]);

        return response()->json(['data' => $communes]);
    }
}
