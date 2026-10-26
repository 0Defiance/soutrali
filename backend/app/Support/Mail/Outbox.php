<?php

namespace App\Support\Mail;

use Illuminate\Contracts\Mail\Mailable;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Throwable;

/**
 * Envoi des e-mails transactionnels (F-09).
 *
 * Une panne du transport (SMTP inaccessible, quota du fournisseur atteint,
 * identifiants absents en local) est journalisée dans `storage/logs/error.log`
 * mais ne fait **jamais** échouer la requête qui a déclenché l'e-mail :
 * l'inscription, la publication d'une annonce ou la réception d'un message
 * restent acquises même si la boîte mail est indisponible.
 */
class Outbox
{
    /**
     * @param  string  $recipient  Adresse du destinataire (expéditeur pris
     *                             dans `config('mail.from')`).
     */
    public static function send(string $recipient, Mailable $mailable): void
    {
        try {
            Mail::to($recipient)->send($mailable);
        } catch (Throwable $exception) {
            Log::error('E-mail non envoyé à '.$recipient.' — '.$exception->getMessage());
        }
    }

    /**
     * URL du front (app Flutter web ou application empaquetée) pour un lien
     * cliquable dans un e-mail. `config()` renvoie `mixed` : le cast est
     * explicite pour rester typé sous PHPStan.
     */
    public static function frontendUrl(string $path = ''): string
    {
        $base = (string) config('app.frontend_url', 'http://127.0.0.1:8082');

        return rtrim($base, '/').$path;
    }
}
