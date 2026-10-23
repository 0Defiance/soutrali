<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Resources\MyListingResource;
use App\Models\Listing;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class MyListingController
{
    /**
     * Publier une annonce (F-03). Publication immédiate : statut PUBLIEE
     * (D-06 validée le 22 oct. 2026).
     */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate($this->rules());

        $listing = Listing::create([
            ...$data,
            'user_id' => $request->user()->id,
            'status' => 'PUBLIEE',
        ]);

        return response()->json(
            new MyListingResource($listing->load(['category:id,name', 'commune:id,name'])),
            201,
        );
    }

    /**
     * Modifier sa propre annonce (F-05). Seul le propriétaire peut modifier ;
     * la requête directe à l'API est refusée avec 403 (CA-05).
     */
    public function update(Request $request, Listing $listing): JsonResponse
    {
        abort_unless($listing->user_id === $request->user()->id, 403);

        $data = $request->validate($this->rules());
        $listing->update($data);

        return response()->json(
            new MyListingResource($listing->load(['category:id,name', 'commune:id,name'])),
        );
    }

    /**
     * Liste des annonces de l'utilisateur connecté, tous statuts confondus.
     */
    public function index(Request $request)
    {
        $listings = Listing::query()
            ->where('user_id', $request->user()->id)
            ->with(['category:id,name', 'commune:id,name'])
            ->latest('created_at')
            ->get();

        return MyListingResource::collection($listings);
    }

    /**
     * Clôturer sa propre annonce avec une issue (F-05, besoins 16 et 6).
     */
    public function close(Request $request, Listing $listing): JsonResponse
    {
        abort_unless($listing->user_id === $request->user()->id, 403);

        if ($listing->status === 'CLOTUREE') {
            return response()->json(['message' => 'Cette annonce est déjà clôturée.'], 409);
        }

        $data = $request->validate([
            'closure_outcome' => ['required', 'string', 'max:24'],
        ]);

        $listing->update([
            'status' => 'CLOTUREE',
            'closure_outcome' => $data['closure_outcome'],
        ]);

        return response()->json(
            new MyListingResource($listing->load(['category:id,name', 'commune:id,name'])),
        );
    }

    /**
     * @return array<string, array<int, mixed>>
     */
    private function rules(): array
    {
        return [
            'title' => ['required', 'string', 'min:4', 'max:140'],
            'description' => ['required', 'string', 'min:10', 'max:5000'],
            'type' => ['required', Rule::in(['DEMANDE', 'OFFRE'])],
            'nature' => ['required', Rule::in(['BENEVOLE', 'REMUNEREE'])],
            'category_id' => ['required', 'integer', Rule::exists('categories', 'id')->where('active', true)],
            'commune_id' => ['required', 'integer', Rule::exists('communes', 'id')->where('active', true)],
            'neighborhood' => ['nullable', 'string', 'max:100'],
            'availability' => ['nullable', 'string', 'max:160'],
            'budget' => ['nullable', 'numeric', 'min:0', 'max:9999999999'],
        ];
    }
}
