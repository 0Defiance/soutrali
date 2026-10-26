<?php

namespace App\Mail;

use App\Models\User;
use App\Support\Mail\Outbox;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

/**
 * E-mail de bienvenue envoyé à l'inscription (F-09, compte créé D-04).
 */
class WelcomeMail extends Mailable
{
    use SerializesModels;

    public function __construct(public readonly User $user) {}

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'Bienvenue sur Soutrali, '.$this->user->display_name.' !',
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.welcome',
            with: [
                'user' => $this->user,
                'homeUrl' => Outbox::frontendUrl('/'),
            ],
        );
    }
}
