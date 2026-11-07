<?php

namespace App\Http\Resources;

use App\Models\Listing;
use App\Support\AbidjanGeolocation;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Listing
 */
class PublicListingResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $latitude = $request->filled('latitude') ? (float) $request->query('latitude') : null;
        $longitude = $request->filled('longitude') ? (float) $request->query('longitude') : null;
        $communeLatitude = $this->commune?->latitude;
        $communeLongitude = $this->commune?->longitude;

        return [
            'id' => $this->id,
            'title' => $this->title,
            'description' => $this->description,
            'type' => $this->type,
            'nature' => $this->nature,
            'availability' => $this->availability,
            // Le cast decimal:2 renvoie une chaîne : on force un nombre JSON.
            'budget' => $this->budget !== null ? (float) $this->budget : null,
            'category' => ['name' => $this->category?->name, 'icon' => $this->category?->icon],
            'commune' => ['name' => $this->commune?->name],
            // Distance au centre de la commune, seulement quand la position a
            // été fournie (tri « Annonces près de vous », 7 nov. 2026).
            'distance_km' => $this->when(
                $latitude !== null && $longitude !== null && $communeLatitude !== null && $communeLongitude !== null,
                fn () => round(AbidjanGeolocation::distanceKm(
                    $latitude,
                    $longitude,
                    (float) $communeLatitude,
                    (float) $communeLongitude,
                ), 2),
            ),
            'author' => $this->whenLoaded('author', fn () => [
                'id' => $this->author?->id,
                'display_name' => $this->author?->display_name,
            ]),
            'created_at' => $this->created_at?->toISOString(),
        ];
    }
}
