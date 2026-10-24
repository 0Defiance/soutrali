<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\ContactChannel;
use App\Models\Listing;
use App\Models\User;
use App\Models\UserBlock;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/**
 * Canaux de contact du profil (F-02) et leur exposition sur une annonce
 * (F-06). Arbitrage du 24 octobre 2026 : l’auteur choisit ses canaux et
 * leur visibilité ; un canal marqué visible est montré aux comptes
 * connectés sur le détail de l’annonce. Un canal masqué n’est jamais
 * renvoyé, et un blocage rend les canaux indisponibles dans les deux sens.
 */
class ContactChannelController
{
    /** Types de canaux autorisés (une seule occurrence par type et compte). */
    private const TYPES = ['EMAIL', 'TELEPHONE', 'WHATSAPP'];

    /**
     * Canaux de l’utilisateur connecté (gestion depuis le profil).
     */
    public function index(Request $request): JsonResponse
    {
        return response()->json([
            'data' => $this->ownedChannels($request->user()),
        ]);
    }

    /**
     * Créer ou mettre à jour un canal (l’unicité porte sur le couple
     * compte + type : un seul numéro, un seul e-mail… par type).
     */
    public function store(Request $request): JsonResponse
    {
        $type = $request->input('type');

        $data = $request->validate([
            'type' => ['required', Rule::in(self::TYPES)],
            'value' => [
                'required',
                'string',
                'max:190',
                $type === 'EMAIL'
                    ? 'email'
                    : 'regex:/^\+?[0-9][0-9\s().\-]{6,29}$/',
            ],
            'visible_to_members' => ['required', 'boolean'],
        ]);

        $channel = ContactChannel::updateOrCreate(
            ['user_id' => $request->user()->id, 'type' => $data['type']],
            [
                'value' => $data['value'],
                'visible_to_members' => $data['visible_to_members'],
            ],
        );

        return response()->json([
            'data' => $this->payload($channel, withId: true),
        ]);
    }

    /**
     * Retirer un canal : seulement le propriétaire y accède (404 sinon).
     */
    public function destroy(Request $request, ContactChannel $channel): JsonResponse
    {
        abort_unless($channel->user_id === $request->user()->id, 404);

        $channel->delete();

        return response()->json(['deleted' => true]);
    }

    /**
     * Canaux visibles de l’auteur d’une annonce (F-06) : connecté,
     * pas sa propre annonce, aucun blocage dans l’un ou l’autre sens.
     */
    public function forListing(Request $request, Listing $listing): JsonResponse
    {
        abort_unless($listing->isLive(), 404);

        /** @var User $viewer */
        $viewer = $request->user();

        abort_if($listing->user_id === $viewer->id, 403, 'Votre propre annonce n’affiche pas vos canaux de contact.');
        abort_if(
            UserBlock::existsBetween($viewer->id, $listing->user_id),
            403,
            'Les canaux de contact de ce compte sont indisponibles.',
        );

        $channels = ContactChannel::query()
            ->where('user_id', $listing->user_id)
            ->where('visible_to_members', true)
            ->orderBy('type')
            ->get()
            ->map(fn (ContactChannel $channel): array => $this->payload($channel))
            ->values();

        return response()->json(['data' => $channels]);
    }

    /**
     * @return array<int, array<string, mixed>>
     */
    private function ownedChannels(User $user): array
    {
        return ContactChannel::query()
            ->where('user_id', $user->id)
            ->orderBy('type')
            ->get()
            ->map(fn (ContactChannel $channel): array => $this->payload($channel, withId: true))
            ->values()
            ->all();
    }

    /**
     * @return array<string, mixed>
     */
    private function payload(ContactChannel $channel, bool $withId = false): array
    {
        $payload = [
            'type' => $channel->type,
            'label' => self::label($channel->type),
            'value' => $channel->value,
            'visible_to_members' => $channel->visible_to_members,
        ];

        if ($withId) {
            $payload = ['id' => $channel->id] + $payload;
        }

        return $payload;
    }

    private static function label(string $type): string
    {
        return match ($type) {
            'EMAIL' => 'E-mail',
            'TELEPHONE' => 'Téléphone',
            'WHATSAPP' => 'WhatsApp',
            default => $type,
        };
    }
}
