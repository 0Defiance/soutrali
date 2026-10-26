<?php

namespace App\Http\Controllers\Api\V1;

use App\Mail\WelcomeMail;
use App\Models\User;
use App\Support\Mail\Outbox;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\ValidationException;

class AuthController
{
    /**
     * Inscription e-mail + mot de passe (D-04 validée le 22 oct. 2026),
     * ouverture immédiate de la session.
     */
    public function register(Request $request): JsonResponse
    {
        $data = $request->validate([
            'display_name' => ['required', 'string', 'min:2', 'max:80'],
            'email' => ['required', 'email', 'max:190', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
            'commune_id' => ['nullable', 'integer', 'exists:communes,id'],
        ]);

        $user = User::create([
            'display_name' => $data['display_name'],
            'email' => $data['email'],
            'password' => $data['password'],
            'commune_id' => $data['commune_id'] ?? null,
            'role' => 'UTILISATEUR',
            'status' => 'ACTIF',
        ]);

        Auth::login($user);
        $request->session()->migrate(true);

        // E-mail de bienvenue (F-09) : envoyé après la création du compte,
        // sans jamais faire échouer l’inscription si le transport tombe.
        Outbox::send($user->email, new WelcomeMail($user));

        return response()->json(['user' => $this->payload($user)], 201);
    }

    /**
     * Connexion par e-mail et mot de passe. Le message d'erreur est identique
     * que le compte existe ou non (pas d'énumération de comptes).
     */
    public function login(Request $request): JsonResponse
    {
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        if (! Auth::attempt($credentials)) {
            throw ValidationException::withMessages([
                'email' => 'E-mail ou mot de passe incorrect.',
            ]);
        }

        /** @var User $user */
        $user = Auth::user();

        if ($user->status !== 'ACTIF') {
            Auth::logout();
            $request->session()->invalidate();

            throw ValidationException::withMessages([
                'email' => 'E-mail ou mot de passe incorrect.',
            ]);
        }

        $request->session()->migrate(true);

        return response()->json(['user' => $this->payload($user)]);
    }

    public function logout(Request $request): JsonResponse
    {
        Auth::guard('web')->logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return response()->json(['message' => 'Session fermée.']);
    }

    /**
     * Jeton CSRF de la session courante, renvoyé en JSON pour le client
     * Flutter (équivalent JSON de GET /sanctum/csrf-cookie). À appeler avant
     * chaque mutation : le jeton change après une inscription ou une connexion.
     */
    public function csrfToken(Request $request): JsonResponse
    {
        return response()->json(['token' => $request->session()->token()]);
    }

    public function me(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        return response()->json(['user' => $this->payload($user)]);
    }

    private function payload(User $user): array
    {
        $user->loadMissing('commune:id,name');

        return [
            'id' => $user->id,
            'display_name' => $user->display_name,
            'email' => $user->email,
            'role' => $user->role,
            'commune' => $user->commune
                ? ['id' => $user->commune->id, 'name' => $user->commune->name]
                : null,
        ];
    }
}
