<?php

namespace App\Mail;

use App\Models\Interaction;
use App\Models\User;
use App\Support\Mail\Outbox;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

/**
 * Notification « vous avez reçu un message » (F-09 / messagerie interne
 * D-05) : envoyée à l'autre participant du fil, jamais à l'émetteur.
 */
class NewMessageMail extends Mailable
{
    use SerializesModels;

    /**
     * @param  string  $body  Corps du message, tronqué par l'appelant.
     */
    public function __construct(
        public readonly User $recipient,
        public readonly User $sender,
        public readonly Interaction $interaction,
        public readonly string $body,
    ) {}

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: $this->sender->display_name.' vous a écrit sur Soutrali',
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.new-message',
            with: [
                'sender' => $this->sender,
                'interaction' => $this->interaction,
                'body' => $this->body,
                'url' => Outbox::frontendUrl('/messagerie/'.$this->interaction->id),
            ],
        );
    }
}
