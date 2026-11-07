<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Resources\PublicListingResource;
use App\Models\Listing;
use App\Support\AbidjanGeolocation;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Http\Request;
use Illuminate\Pagination\LengthAwarePaginator as Paginator;
use Illuminate\Pagination\Paginator as PaginatorFactory;
use Illuminate\Support\Collection;
use Illuminate\Validation\Rule;

class PublicListingController
{
    public function index(Request $request)
    {
        $filters = $request->validate([
            'q' => ['nullable', 'string', 'max:120'],
            'commune' => ['nullable', 'string', 'max:80'],
            'category' => ['nullable', 'integer', 'min:1'],
            'type' => ['nullable', Rule::in(['DEMANDE', 'OFFRE'])],
            'nature' => ['nullable', Rule::in(['BENEVOLE', 'REMUNEREE'])],
            'page' => ['nullable', 'integer', 'min:1'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:24'],
            // Position de l'utilisateur, transmise après confirmation (7 nov.
            // 2026) : les deux coordonnées vont ensemble, sinon aucune.
            'latitude' => ['nullable', 'numeric', 'between:-90,90', 'required_with:longitude'],
            'longitude' => ['nullable', 'numeric', 'between:-180,180', 'required_with:latitude'],
        ]);

        $latitude = isset($filters['latitude']) ? (float) $filters['latitude'] : null;
        $longitude = isset($filters['longitude']) ? (float) $filters['longitude'] : null;

        $query = Listing::query()
            ->with(['category:id,name,icon', 'commune:id,name,latitude,longitude', 'author:id,display_name'])
            ->published()
            ->when($filters['q'] ?? null, function ($query, $term) {
                $query->where(function ($search) use ($term) {
                    $search->where('title', 'like', "%{$term}%")
                        ->orWhere('description', 'like', "%{$term}%");
                });
            })
            ->when($filters['commune'] ?? null, fn ($query, $name) => $query->whereHas('commune', fn ($communes) => $communes->where('name', $name)))
            ->when($filters['category'] ?? null, fn ($query, $id) => $query->where('category_id', $id))
            ->when($filters['type'] ?? null, fn ($query, $type) => $query->where('type', $type))
            ->when($filters['nature'] ?? null, fn ($query, $nature) => $query->where('nature', $nature));

        if ($latitude === null || $longitude === null) {
            return PublicListingResource::collection(
                $query->latest('created_at')->paginate($filters['per_page'] ?? 12)->withQueryString(),
            );
        }

        // Tri par distance réelle au centre de la commune. Le calcul est fait
        // en PHP plutôt qu'en SQL : les tests tournent sur SQLite, qui n'expose
        // pas les fonctions trigonométriques selon la compilation, et le
        // référentiel reste de taille modeste (annonces d'une ville).
        $listings = $query->get()
            ->sort(function (Listing $left, Listing $right) use ($latitude, $longitude) {
                $distance = $this->distanceFor($left, $latitude, $longitude)
                    <=> $this->distanceFor($right, $latitude, $longitude);

                // À distance égale, la plus récente d'abord.
                return $distance !== 0
                    ? $distance
                    : $right->created_at->timestamp <=> $left->created_at->timestamp;
            })
            ->values();

        return PublicListingResource::collection(
            $this->paginate($listings, $filters['per_page'] ?? 12, $request),
        );
    }

    public function show(Listing $listing): PublicListingResource
    {
        abort_unless($listing->isLive(), 404);

        return new PublicListingResource($listing->load(['category:id,name,icon', 'commune:id,name,latitude,longitude', 'author:id,display_name']));
    }

    private function distanceFor(Listing $listing, float $latitude, float $longitude): float
    {
        $commune = $listing->commune;

        if ($commune->latitude === null || $commune->longitude === null) {
            return PHP_FLOAT_MAX;
        }

        return AbidjanGeolocation::distanceKm(
            $latitude,
            $longitude,
            (float) $commune->latitude,
            (float) $commune->longitude,
        );
    }

    /**
     * Pagination manuelle d'une collection déjà triée par distance.
     *
     * @param  Collection<int, Listing>  $listings
     */
    private function paginate($listings, int $perPage, Request $request): LengthAwarePaginator
    {
        PaginatorFactory::currentPageResolver(fn () => (int) $request->query('page', 1));
        PaginatorFactory::currentPathResolver(fn () => $request->url());

        $page = max(1, (int) $request->query('page', 1));

        return new Paginator(
            $listings->forPage($page, $perPage)->values(),
            $listings->count(),
            $perPage,
            $page,
            ['path' => $request->url(), 'query' => $request->query()],
        );
    }
}
