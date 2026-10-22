<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Resources\PublicListingResource;
use App\Models\Listing;
use Illuminate\Http\Request;
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
        ]);

        $listings = Listing::query()
            ->with(['category:id,name', 'commune:id,name'])
            ->where('status', 'PUBLIEE')
            ->when($filters['q'] ?? null, function ($query, $term) {
                $query->where(function ($search) use ($term) {
                    $search->where('title', 'like', "%{$term}%")
                        ->orWhere('description', 'like', "%{$term}%");
                });
            })
            ->when($filters['commune'] ?? null, fn ($query, $name) => $query->whereHas('commune', fn ($communes) => $communes->where('name', $name)))
            ->when($filters['category'] ?? null, fn ($query, $id) => $query->where('category_id', $id))
            ->when($filters['type'] ?? null, fn ($query, $type) => $query->where('type', $type))
            ->when($filters['nature'] ?? null, fn ($query, $nature) => $query->where('nature', $nature))
            ->latest('created_at')
            ->paginate($filters['per_page'] ?? 12)
            ->withQueryString();

        return PublicListingResource::collection($listings);
    }

    public function show(Listing $listing): PublicListingResource
    {
        abort_unless($listing->status === 'PUBLIEE', 404);

        return new PublicListingResource($listing->load(['category:id,name', 'commune:id,name']));
    }
}
