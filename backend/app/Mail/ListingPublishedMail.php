<?php

namespace App\Mail;

use App\Models\Listing;
use App\Support\Mail\Outbox;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

/**
 * Confirmation d'une annonce passée en ligne (F-09 / F-03) : publication
 * immédiate, mise en ligne manuelle ou publication programmée échue.
 */
class ListingPublishedMail extends Mailable
{
    use SerializesModels;

    public function __construct(public readonly Listing $listing) {}

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'Votre annonce est en ligne : '.$this->listing->title,
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.listing-published',
            with: [
                'listing' => $this->listing,
                'url' => Outbox::frontendUrl('/listing/'.$this->listing->id),
            ],
        );
    }
}
