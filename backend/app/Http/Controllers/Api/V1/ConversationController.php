<?php

namespace App\Http\Controllers\Api\V1;

use App\Mail\NewMessageMail;
use App\Models\Interaction;
use App\Models\Listing;
use App\Models\Message;
use App\Models\User;
use App\Models\UserBlock;
use App\Support\Mail\Outbox;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ConversationController
{
    /**
     * Démarrer (ou reprendre) un fil de discussion autour d'une annonce,
     * avec un premier message interne (F-06, D-05 messagerie interne).
     */
    public function start(Request $request, Listing $listing): JsonResponse
    {
        $data = $request->validate([
            'message' => ['required', 'string', 'min:2', 'max:2000'],
        ]);

        /** @var User $user */
        $user = $request->user();

        abort_unless($listing->isLive(), 404);
        abort_if($listing->user_id === $user->id, 403, 'Vous ne pouvez pas contacter l’auteur de votre propre annonce.');
        abort_if(
            UserBlock::existsBetween($user->id, $listing->user_id),
            403,
            'La messagerie n’est pas possible avec ce compte.',
        );

        $interaction = Interaction::firstOrCreate([
            'listing_id' => $listing->id,
            'initiator_id' => $user->id,
        ]);

        $interaction->messages()->create([
            'sender_id' => $user->id,
            'body' => $data['message'],
        ]);

        // Notification de l’auteur de l’annonce (F-09) : le garde ci-dessus
        // garantit qu’il n’est jamais l’émetteur lui-même.
        $this->notifyParticipant(
            $listing->author,
            $user,
            $interaction,
            $data['message'],
        );

        return response()->json($this->summary($interaction, $user), 201);
    }

    /**
     * Fils de l'utilisateur connecté, du plus récent au plus ancien,
     * avec le nombre de messages non lus.
     */
    public function index(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        $interactions = Interaction::query()
            ->where('initiator_id', $user->id)
            ->orWhereHas('listing', fn ($query) => $query->where('user_id', $user->id))
            ->with(['listing:id,title,user_id,status', 'listing.author:id,display_name', 'initiator:id,display_name'])
            ->get()
            ->sortByDesc(fn (Interaction $interaction) => $interaction->messages()->max('created_at') ?? $interaction->created_at)
            ->values();

        $data = $interactions->map(fn (Interaction $interaction) => $this->summary($interaction, $user))->values();

        return response()->json([
            'data' => $data,
            'unread_total' => (int) $data->sum('unread'),
        ]);
    }

    /**
     * Détail d'un fil : les messages de l'autre participant sont marqués lus.
     */
    public function show(Request $request, Interaction $interaction): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        abort_unless($interaction->involves($user), 403);

        $interaction->messages()
            ->where('sender_id', '!=', $user->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        $messages = $interaction->messages()
            ->orderBy('created_at')
            ->get()
            ->map(fn (Message $message) => $this->messagePayload($message, $user))
            ->values();

        return response()->json([
            'id' => $interaction->id,
            'listing' => $this->listingPayload($interaction),
            'participant' => $this->participantPayload($interaction, $user),
            'messages' => $messages,
        ]);
    }

    /**
     * Envoyer un message dans un fil auquel on participe.
     */
    public function sendMessage(Request $request, Interaction $interaction): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        abort_unless($interaction->involves($user), 403);

        $other = $interaction->initiator_id === $user->id
            ? $interaction->listing?->user_id
            : $interaction->initiator_id;

        abort_if(
            $other !== null && UserBlock::existsBetween($user->id, $other),
            403,
            'La messagerie n’est pas possible avec ce compte.',
        );

        $data = $request->validate([
            'body' => ['required', 'string', 'min:1', 'max:2000'],
        ]);

        $message = $interaction->messages()->create([
            'sender_id' => $user->id,
            'body' => $data['body'],
        ]);

        // Notification de l’autre participant (F-09), jamais de soi-même.
        $this->notifyParticipant(
            $other !== null ? User::find($other) : null,
            $user,
            $interaction,
            $data['body'],
        );

        return response()->json($this->messagePayload($message, $user), 201);
    }

    /**
     * E-mail « vous avez reçu un message » (F-09) : envoyé au seul autre
     * participant, jamais à l’émetteur, jamais si le destinataire est
     * introuvable. Panne SMTP journalisée dans error.log, requête préservée.
     */
    private function notifyParticipant(?User $recipient, User $sender, Interaction $interaction, string $body): void
    {
        if ($recipient === null || $recipient->id === $sender->id) {
            return;
        }

        Outbox::send(
            $recipient->email,
            new NewMessageMail($recipient, $sender, $interaction, mb_strimwidth($body, 0, 300, '…')),
        );
    }

    /**
     * @return array<string, mixed>
     */
    private function summary(Interaction $interaction, User $me): array
    {
        $messages = $interaction->messages()->orderByDesc('created_at')->get();
        $last = $messages->first();

        $unread = $messages
            ->filter(fn (Message $message) => $message->sender_id !== $me->id && $message->read_at === null)
            ->count();

        return [
            'id' => $interaction->id,
            'listing' => $this->listingPayload($interaction),
            'participant' => $this->participantPayload($interaction, $me),
            'last_message' => $last
                ? ['body' => mb_strimwidth($last->body, 0, 120, '…'), 'created_at' => $last->created_at?->toISOString()]
                : null,
            'unread' => $unread,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function listingPayload(Interaction $interaction): array
    {
        return [
            'id' => $interaction->listing?->id,
            'title' => $interaction->listing?->title,
            'status' => $interaction->listing?->status,
        ];
    }

    /**
     * L'autre participant du fil (auteur de l'annonce ou initiateur).
     *
     * @return array<string, mixed>|null
     */
    private function participantPayload(Interaction $interaction, User $me): ?array
    {
        $other = $interaction->initiator_id === $me->id
            ? $interaction->listing?->author
            : $interaction->initiator;

        return $other
            ? ['id' => $other->id, 'display_name' => $other->display_name]
            : null;
    }

    /**
     * @return array<string, mixed>
     */
    private function messagePayload(Message $message, User $me): array
    {
        return [
            'id' => $message->id,
            'sender_id' => $message->sender_id,
            'body' => $message->body,
            'is_mine' => $message->sender_id === $me->id,
            'read_at' => $message->read_at?->toISOString(),
            'created_at' => $message->created_at?->toISOString(),
        ];
    }
}
