<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\User;
use App\Models\UserBlock;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Blocages d’utilisateurs (T-14) : un compte peut bloquer un autre
 * compte ; la messagerie est alors désactivée dans les deux sens
 * (voir ConversationController). Le blocage ne supprime rien : il
 * désactive seulement la mise en relation.
 */
class BlockController
{
    /**
     * Comptes bloqués par l’utilisateur connecté.
     */
    public function index(Request $request): JsonResponse
    {
        $blocks = UserBlock::query()
            ->where('blocker_id', $request->user()->id)
            ->with('blocked:id,display_name')
            ->latest()
            ->get()
            ->map(fn (UserBlock $block): array => [
                'id' => $block->blocked?->id,
                'display_name' => $block->blocked?->display_name,
                'blocked_at' => $block->created_at?->toISOString(),
            ])
            ->values();

        return response()->json(['data' => $blocks]);
    }

    /**
     * Bloquer un compte : jamais soi-même, et idempotent (re-bloquer
     * n’est pas une erreur).
     */
    public function store(Request $request, User $user): JsonResponse
    {
        $me = $request->user();

        abort_if($user->id === $me->id, 403, 'Vous ne pouvez pas bloquer votre propre compte.');

        UserBlock::firstOrCreate([
            'blocker_id' => $me->id,
            'blocked_id' => $user->id,
        ]);

        return response()->json(['blocked' => true]);
    }

    /**
     * Débloquer un compte (idempotent : déjà absent = fait).
     */
    public function destroy(Request $request, User $user): JsonResponse
    {
        UserBlock::query()
            ->where('blocker_id', $request->user()->id)
            ->where('blocked_id', $user->id)
            ->delete();

        return response()->json(['blocked' => false]);
    }
}
