@extends('emails.layout')

@section('subject', 'Bienvenue sur Soutrali')

@section('body')
    <h1 style="margin:0 0 16px;font-size:22px;color:#0B5A2A;">Bienvenue {{ $user->display_name }} !</h1>

    <p style="margin:0 0 14px;">
        Votre compte Soutrali est créé. Vous pouvez dès maintenant parcourir
        les annonces près de chez vous, contacter les personnes qui proposent
        ou demandent un service, et publier la vôtre.
    </p>

    <p style="text-align:center;margin:26px 0;">
        <a href="{{ $homeUrl }}"
           style="display:inline-block;background-color:#FE7402;color:#FFFFFF;text-decoration:none;padding:13px 26px;border-radius:8px;font-weight:700;font-family:'Segoe UI',Arial,sans-serif;">
            Ouvrir Soutrali
        </a>
    </p>

    <p style="margin:0;color:#5A6B62;font-size:13px;">
        Votre adresse e-mail sert uniquement à vous connecter et à recevoir
        les messages importants ; elle n’est jamais affichée publiquement.
    </p>
@endsection
