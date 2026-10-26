<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;

/**
 * Journal d’accès (fourni avec le back-office et l’API).
 *
 * Trace chaque requête de l’API (`/api/*`) et du back-office (`/admin*`)
 * dans le canal `access` → `storage/logs/access.log` : méthode, chemin,
 * code HTTP, identifiant d’utilisateur, adresse IP et durée. Les assets
 * statiques (chemin se terminant par une extension) sont ignorés pour ne
 * pas noyer le journal sous les fichiers `.js` / `.css`.
 */
class LogAccess
{
    public function handle(Request $request, Closure $next): Response
    {
        $startedAt = microtime(true);

        try {
            $response = $next($request);
            $status = $response->getStatusCode();
        } catch (\Throwable $exception) {
            // L’exception n’est transformée en réponse qu’au niveau du noyau :
            // on journalise le statut qu’elle produira, puis on la relance.
            $this->log($request, $this->statusOf($exception), $startedAt);

            throw $exception;
        }

        $this->log($request, $status, $startedAt);

        return $response;
    }

    private function log(Request $request, int $status, float $startedAt): void
    {
        if (! $this->shouldLog($request)) {
            return;
        }

        Log::channel('access')->info(sprintf(
            '%s %s %d user=%s ip=%s %.0fms',
            $request->method(),
            $request->getRequestUri(),
            $status,
            $request->user()->id ?? '-',
            $request->ip(),
            (microtime(true) - $startedAt) * 1000,
        ));
    }

    /**
     * Statut HTTP que le noyau rendra pour l’exception levée.
     */
    private function statusOf(\Throwable $exception): int
    {
        return match (true) {
            $exception instanceof HttpExceptionInterface => $exception->getStatusCode(),
            $exception instanceof AuthenticationException => 401,
            $exception instanceof AuthorizationException => 403,
            $exception instanceof ValidationException => 422,
            default => 500,
        };
    }

    /**
     * Seules l’API et la console d’administration sont journalisées.
     */
    private function shouldLog(Request $request): bool
    {
        if (! $request->is('api/*') && ! $request->is('admin') && ! $request->is('admin/*')) {
            return false;
        }

        return preg_match('/\.[a-z0-9]{2,5}$/i', $request->path()) !== 1;
    }
}
