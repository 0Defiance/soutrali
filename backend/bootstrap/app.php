<?php

use App\Http\Middleware\LogAccess;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->statefulApi();

        // Journal d’accès : middleware global, pour être exécuté avant le
        // routage (le routeur place `auth:sanctum` avant un middleware de
        // groupe, ce qui court-circuiterait la journalisation des 401).
        $middleware->append(LogAccess::class);

        // Aucune route web de connexion n'existe : la connexion vit dans
        // l'application Flutter. Les requêtes API non authentifiées doivent
        // renvoyer du JSON (401), jamais une redirection vers route('login').
        $middleware->redirectGuestsTo(fn () => '/');
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) => $request->is('api/*') || $request->expectsJson(),
        );
    })->create();
