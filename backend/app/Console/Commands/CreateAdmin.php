<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;

/**
 * Création du premier administrateur en production : le compte
 * `admin.demo` du `DemoSeeder` n'existe qu'en local, ce qui bloquait
 * l'ouverture de `/admin` sur un déploiement vierge (SUIVI §4).
 *
 * Le mot de passe peut être omis pour être saisi en clair-masqué
 * (recommandé sur un hébergement partagé : l'argument en clair reste
 * dans l'historique de la session SSH).
 */
class CreateAdmin extends Command
{
    protected $signature = 'soutrali:create-admin
        {email : Adresse e-mail du compte administrateur}
        {--name= : Nom affiché (défaut : le parti avant arobase)}
        {--password= : Mot de passe en clair ; omis => saisi de façon non affichable}';

    protected $description = 'Crée (ou promeut en ADMINISTRATEUR actif) le compte administrateur du back-office /admin.';

    public function handle(): int
    {
        $email = (string) $this->argument('email');

        if (! filter_var($email, FILTER_VALIDATE_EMAIL)) {
            $this->error('Adresse e-mail invalide.');

            return self::FAILURE;
        }

        $password = (string) $this->option('password');

        if ($password === '') {
            $password = (string) $this->secret('Mot de passe (8 caractères minimum)');
        }

        if (strlen($password) < 8) {
            $this->error('Le mot de passe doit contenir au moins 8 caractères.');

            return self::FAILURE;
        }

        $name = trim((string) $this->option('name'));

        if ($name === '') {
            $local = explode('@', $email, 2)[0];

            $name = 'Administrateur '.$local;
        }

        $user = User::query()->firstOrNew(['email' => $email]);

        $isNew = ! $user->exists;

        $user->fill([
            'display_name' => $user->display_name ?: $name,
            'password' => $password,
            'role' => 'ADMINISTRATEUR',
            'status' => 'ACTIF',
        ]);

        $user->save();

        $this->info(($isNew ? 'Compte créé : ' : 'Compte promu : ').$email.' (ADMINISTRATEUR, actif).');

        return self::SUCCESS;
    }
}
