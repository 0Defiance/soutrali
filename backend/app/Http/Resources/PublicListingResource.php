<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PublicListingResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'description' => $this->description,
            'type' => $this->type,
            'nature' => $this->nature,
            'availability' => $this->availability,
            'budget' => $this->budget,
            'category' => ['name' => $this->category?->name],
            'commune' => ['name' => $this->commune?->name],
            'created_at' => $this->created_at?->toISOString(),
        ];
    }
}