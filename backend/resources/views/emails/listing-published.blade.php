@extends('emails.layout')

@section('subject', 'Votre annonce est en ligne')

@section('body')
    <h1 style="margin:0 0 16px;font-size:22px;color:#0B5A2A;">Votre annonce est en ligne</h1>

    <p style="margin:0 0 14px;">
        Bonjour {{ $listing->author->display_name }},<br>
        votre annonce <strong>« {{ $listing->title }} »</strong> est
        maintenant visible par tous les membres de Soutrali.
    </p>

    <div style="background-color:#FFF9F2;border:1px solid #DCE5DF;border-radius:10px;padding:14px 16px;margin:0 0 18px;">
        <p style="margin:0;font-size:13px;color:#5A6B62;">
            Catégorie&nbsp;: {{ $listing->category->name ?? '—' }}<br>
            Commune&nbsp;: {{ $listing->commune->name ?? '—' }}
        </p>
    </div>

    <p style="text-align:center;margin:26px 0;">
        <a href="{{ $url }}"
           style="display:inline-block;background-color:#037C30;color:#FFFFFF;text-decoration:none;padding:13px 26px;border-radius:8px;font-weight:700;font-family:'Segoe UI',Arial,sans-serif;">
            Voir mon annonce
        </a>
    </p>

    <p style="margin:0;color:#5A6B62;font-size:13px;">
        Les messages des intéressés arrivent dans la messagerie interne de
        Soutrali, depuis votre espace « Mon profil ».
    </p>
@endsection
