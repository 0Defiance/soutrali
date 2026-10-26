@extends('emails.layout')

@section('subject', 'Nouveau message sur Soutrali')

@section('body')
    <h1 style="margin:0 0 16px;font-size:22px;color:#0B5A2A;">Vous avez reçu un message</h1>

    <p style="margin:0 0 14px;">
        <strong>{{ $sender->display_name }}</strong> vous écrit au sujet de
        l’annonce <strong>« {{ $interaction->listing->title ?? 'votre annonce' }} »</strong>&nbsp;:
    </p>

    <blockquote style="margin:0 0 18px;padding:14px 16px;background-color:#FFF0E0;border-left:4px solid #FE7402;border-radius:0 8px 8px 0;font-style:italic;color:#1F2A24;">
        {{ $body }}
    </blockquote>

    <p style="text-align:center;margin:26px 0;">
        <a href="{{ $url }}"
           style="display:inline-block;background-color:#FE7402;color:#FFFFFF;text-decoration:none;padding:13px 26px;border-radius:8px;font-weight:700;font-family:'Segoe UI',Arial,sans-serif;">
            Répondre dans la messagerie
        </a>
    </p>

    <p style="margin:0;color:#5A6B62;font-size:13px;">
        Les échanges se passent dans Soutrali : votre adresse e-mail reste
        masquée des deux côtés.
    </p>
@endsection
