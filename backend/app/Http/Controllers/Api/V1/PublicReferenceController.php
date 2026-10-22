<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\Category;
use App\Models\Commune;
use Illuminate\Http\JsonResponse;

class PublicReferenceController
{
    /**
     * Catégories actives, telles qu'administrées par la MOA (D-07).
     */
    public function categories(): JsonResponse
    {
        $categories = Category::query()
            ->where('active', true)
            ->orderBy('name')
            ->get(['id', 'name', 'description']);

        return response()->json(['data' => $categories]);
    }

    /**
     * Communes actives du référentiel d'Abidjan (D-03).
     */
    public function communes(): JsonResponse
    {
        $communes = Commune::query()
            ->where('active', true)
            ->orderBy('name')
            ->get(['id', 'name']);

        return response()->json(['data' => $communes]);
    }
}
