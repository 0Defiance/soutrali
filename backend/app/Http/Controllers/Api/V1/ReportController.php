<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\Listing;
use App\Models\Report;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class ReportController
{
    /**
     * Signaler une annonce (F-07). Le signalement est enregistré avec le
     * statut NOUVEAU ; son traitement par un modérateur viendra avec Filament.
     */
    public function store(Request $request, Listing $listing): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        $data = $request->validate([
            'reason' => ['required', 'string', 'max:60'],
            'details' => ['nullable', 'string', 'max:2000'],
        ]);

        if ($listing->user_id === $user->id) {
            throw ValidationException::withMessages([
                'reason' => 'Vous ne pouvez pas signaler votre propre annonce.',
            ]);
        }

        $report = Report::create([
            'listing_id' => $listing->id,
            'reporter_id' => $user->id,
            'reason' => $data['reason'],
            'details' => $data['details'] ?? null,
            'status' => 'NOUVEAU',
        ]);

        return response()->json([
            'id' => $report->id,
            'reason' => $report->reason,
            'status' => $report->status,
            'created_at' => $report->created_at?->toISOString(),
        ], 201);
    }

    /**
     * Suivi des signalements émis par l'utilisateur (F-07).
     */
    public function myReports(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        $reports = Report::query()
            ->where('reporter_id', $user->id)
            ->with('listing:id,title')
            ->latest()
            ->get()
            ->map(fn (Report $report) => [
                'id' => $report->id,
                'reason' => $report->reason,
                'status' => $report->status,
                'listing' => [
                    'id' => $report->listing?->id,
                    'title' => $report->listing?->title,
                ],
                'created_at' => $report->created_at?->toISOString(),
            ])
            ->values();

        return response()->json(['data' => $reports]);
    }
}
