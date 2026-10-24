<?php

namespace App\Http\Resources;

use App\Models\Listing;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Annonce vue par son auteur : ajoute le statut, l’issue de clôture
 * et le quartier à la ressource publique.
 *
 * @mixin Listing
 */
class MyListingResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'description' => $this->description,
            'type' => $this->type,
            'nature' => $this->nature,
            'status' => $this->status,
            'closure_outcome' => $this->closure_outcome,
            'publish_at' => $this->publish_at?->toISOString(),
            'neighborhood' => $this->neighborhood,
            'availability' => $this->availability,
            // Le cast decimal:2 renvoie une chaîne : on force un nombre JSON.
            'budget' => $this->budget !== null ? (float) $this->budget : null,
            'category' => ['id' => $this->category?->id, 'name' => $this->category?->name],
            'commune' => ['id' => $this->commune?->id, 'name' => $this->commune?->name],
            'created_at' => $this->created_at?->toISOString(),
        ];
    }
}
