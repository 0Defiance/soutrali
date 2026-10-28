# Soutrali — Installation et démarrage local

> **Objet :** permettre à une personne qui n’a jamais ouvert le projet de le faire tourner sur son poste, puis de vérifier que chaque couche répond.
>
> **Compléments :** l’état réel de l’implémentation et les blocages connus sont dans [`SUIVI_DEVELOPPEMENT.md`](SUIVI_DEVELOPPEMENT.md). L’architecture et les choix de référence sont dans [`README_TECHNIQUE.md`](README_TECHNIQUE.md). Le cadrage fonctionnel est dans [`README.md`](../README.md).
>
> **Version :** 1.0 · **Dernière mise à jour :** 22 octobre 2026
>
> Les versions ci-dessous sont celles **constatées par exécution** sur le poste de développement le 22 octobre 2026. Elles doivent être revérifiées sur toute autre machine, et figées conformément à T-08.

---

## Sommaire

1. [Prérequis](#1-prérequis)
2. [Ports de développement](#2-ports-de-développement)
3. [Base de données](#3-base-de-données)
4. [Backend Laravel](#4-backend-laravel)
5. [Application Flutter Web](#5-application-flutter-web)
6. [Liste de vérification](#6-liste-de-vérification)
7. [Problèmes connus et solutions](#7-problèmes-connus-et-solutions)
8. [Arrêter et relancer les serveurs](#8-arrêter-et-relancer-les-serveurs)
9. [Mise en ligne en production (AlwaysData)](#9-mise-en-ligne-en-production-alwaysdata)

---

## 1. Prérequis

| Outil | Version constatée | Rôle | Comment vérifier |
|---|---|---|---|
| Flutter / Dart | 3.47.7 / 3.13.5 | Interface web puis Android | `flutter --version` |
| PHP CLI | 8.3.33 | Laravel 13, Artisan, tests | `php -v` |
| Composer | 2.10.3 — absent du PATH, exécutable retrouvé le 22 oct. (voir §1 ci-dessous) | Dépendances PHP | `php "C:\Users\Abd Al Fattah\AppData\Local\Programs\Composer\composer.phar" --version` |
| Git | 2.56.0 | Versionnement | `git --version` |
| GitHub CLI | 2.102.1, non authentifiée | Accès compte et dépôts | `gh auth status` |
| XAMPP / MariaDB | MariaDB 10.4.32 | Base locale + phpMyAdmin | Panneau XAMPP |
| Navigateur récent | — | Recette du site | — |
| Android SDK / Studio | à installer pour l’étape Android | Émulateur et builds mobiles | Non requis pour le web |

**Points d’attention relevés le 22 octobre 2026 :**

- **PHP doit être le CLI 8.3+, pas celui de XAMPP.** Laravel 13 exige PHP 8.3 ou plus (P-01). Le PHP livré par Apache XAMPP peut être en 8.2 : vérifier séparément `php -v` en ligne de commande et le PHP chargé par Apache.
- **Composer peut être installé sans être dans le PATH.** Si `composer --version` échoue alors que `backend/vendor/` existe, les dépendances sont déjà présentes et `php artisan` fonctionne. **Constaté sur ce poste le 22 oct. 2026** : l’exécutable est `C:\Users\Abd Al Fattah\AppData\Local\Programs\Composer\composer.phar` et s’appelle avec PHP : `php "C:\Users\Abd Al Fattah\AppData\Local\Programs\Composer\composer.phar" <commande>`. Pour simplifier, ajouter ce dossier au PATH ou créer un alias `composer`.
- **XAMPP sert uniquement MariaDB et phpMyAdmin.** Apache XAMPP est facultatif : Laravel et Flutter ont leurs propres serveurs de développement.

---

## 2. Ports de développement

| Service | Port | Adresse locale | Rôle |
|---|---:|---|---|
| API Laravel | `8000` | `http://127.0.0.1:8000` | Routes `/api/v1`, sessions Sanctum, panneau `/admin` |
| Flutter Web | `8082` | `http://127.0.0.1:8082` | Site Soutrali ; cookies et origines autorisés pour ce port |
| MariaDB (XAMPP) | `3306` | `127.0.0.1:3306` | Consommée uniquement par Laravel ; jamais par Flutter |

Les ports `8000` et `8082` sont distincts **par conception** : le navigateur les voit comme deux origines. Sanctum, cookies CSRF et CORS doivent donc autoriser explicitement `127.0.0.1:8082` — c’est déjà configuré dans `backend/.env.example` (`SANCTUM_STATEFUL_DOMAINS`) et `backend/config/cors.php`. En production, servir web, API et `/admin` sous une seule origine HTTPS.

---

## 3. Base de données

### 3.1 Démarrer le moteur

Démarrer **MySQL/MariaDB** depuis le panneau XAMPP. Vérifier qu’il écoute :

```powershell
netstat -ano | findstr ":3306"
```

Ne pas lancer Laravel tant que rien n’écoute sur 3306.

### 3.2 Créer la base

Dans phpMyAdmin (`http://127.0.0.1/phpmyadmin`, Apache XAMPP démarré) :

- nom : `soutrali`
- jeu de caractères : `utf8mb4`
- interclassement : `utf8mb4_unicode_ci`

Ou en ligne de commande :

```sql
CREATE DATABASE soutrali CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 3.3 Créer l’utilisateur SQL dédié — **fait sur ce poste le 22 oct. 2026**

`.env.example` référence `DB_USERNAME=soutrali_dev`, mais ce compte **n’existait pas** sur le poste : seuls `root` et `pma` étaient déclarés. C’était la cause directe de l’échec de connexion de Laravel. Le compte a été créé le 22 octobre 2026 pour `127.0.0.1` et `localhost`, avec des droits limités à `soutrali.*`, et `backend/.env` a été basculé de `root` vers ce compte. Sur une machine neuve, reproduire :

```sql
CREATE USER 'soutrali_dev'@'127.0.0.1' IDENTIFIED BY '<MOT_DE_PASSE_CHOISI>';
GRANT ALL PRIVILEGES ON soutrali.* TO 'soutrali_dev'@'127.0.0.1';
FLUSH PRIVILEGES;
```

**Le mot de passe est choisi par la personne qui installe et recopié dans `backend/.env`.** Il ne figure jamais dans ce document, dans un ticket, une capture d’écran ou un commit. Ne pas utiliser `root` sans mot de passe pour l’application.

### 3.4 Moteur réel

XAMPP livre en pratique **MariaDB**, pas MySQL (P-02). Les migrations évitent les fonctions propres à un moteur ; la CI teste contre MySQL. Consigner le moteur et sa version réels ici après installation :

- Poste de développement : MariaDB 10.4.32 (constaté le 22 oct. 2026).

---

## 4. Backend Laravel

Depuis `backend/`, dans un terminal :

```powershell
# Composer hors PATH sur ce poste : utiliser le chemin exact (§1)
php "C:\Users\Abd Al Fattah\AppData\Local\Programs\Composer\composer.phar" install
Copy-Item .env.example .env
php artisan key:generate
php artisan migrate
php artisan db:seed
php artisan serve --host 127.0.0.1 --port 8000
```

Avant `migrate`, renseigner `DB_HOST`, `DB_PORT`, `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD` dans `backend/.env`. **Ce fichier n’est jamais versionné** (`.gitignore` l’exclut).

Notes :

- `composer install` résout les versions et crée `composer.lock`, à vérifier puis committer (T-08). Filament 5 et Laravel 13 doivent résoudre ensemble.
- Si `composer` n’est pas dans le PATH mais que `backend/vendor/` existe déjà, passer directement à `php artisan key:generate`.
- `php artisan db:seed` charge le référentiel validé : **14 lignes de communes** (13 communes d’Abidjan + zone « Plusieurs communes », D-03) et **8 catégories** (D-07). En environnement `local` uniquement, il charge aussi `DemoSeeder` : 3 comptes (dont l’administrateur du back-office) et 8 annonces **fictifs** pour les recettes. Aucun contenu fictif n’est chargé en préproduction ni en production. Vérifier ensuite :

```powershell
curl -H "Accept: application/json" http://127.0.0.1:8000/api/v1/communes
curl -H "Accept: application/json" http://127.0.0.1:8000/api/v1/categories
```
- Vérifier que l’API répond :

```powershell
curl -H "Accept: application/json" http://127.0.0.1:8000/api/v1/listings
```

Une base migrée mais vide renvoie une liste vide ; c’est un résultat **normal**, pas une erreur.

- **Publication programmée (24 oct. 2026)** : les annonces créées avec une date future restent en `BROUILLON` puis basculent en `PUBLIEE` via la commande `soutrali:publish-due`, planifiée chaque minute dans `routes/console.php` (`php artisan schedule:list` affiche `* * * * * php artisan soutrali:publish-due`). **En local**, exécuter dans un second terminal `php artisan schedule:work` pendant les tests ; **en production**, un cron `* * * * * cd /chemin/backend && php artisan schedule:run`. Sans cette étape, les annonces programmées ne passent pas automatiquement (la route publique les montre quand même une fois leur date atteinte).

### Accès au back-office `/admin`

- Ouvrir `http://127.0.0.1:8000/admin` une fois l’API démarrée : le panneau répond (redirection vers `/admin/login`).
- **Compte local** : `DemoSeeder` (environnement `local` uniquement) crée `admin.demo@soutrali.test`, mot de passe `password`, rôle ADMINISTRATEUR. **Hors local (production)** : créer le premier administrateur avec `php artisan soutrali:create-admin <email>` — le compte est créé (ou promu) en `ADMINISTRATEUR` actif ; si `--password` est omis, le mot de passe est saisi en clair-masqué, ce qui évite de le laisser dans l’historique de la session. Aucun compte privilégié n’est créé automatiquement en production.
- L’accès est réservé aux rôles `MODERATEUR` et `ADMINISTRATEUR` dont le statut est `ACTIF` ; un compte `UTILISATEUR` est refusé.
- Les assets Filament sont déjà publiés et versionnés dans `public/css|js|fonts/filament` ; pour les régénérer après une mise à jour : `php artisan filament:assets`.
- **Depuis l’application (26 oct. 2026)** : un compte connecté avec l’un de ces rôles voit une entrée **« Espace admin »** dans le menu du compte (initiales, en haut à droite de l’écran Découvrir) et un bouton du même nom dans la fenêtre **« Mon profil »** ; les deux ouvrent `http://127.0.0.1:8000/admin` dans un nouvel onglet. Un compte `UTILISATEUR` ou un invité ne voit rien.

### Journaux : accès et erreurs

Deux journaux sont produits automatiquement depuis le **26 octobre 2026**, dans `backend/storage/logs/` :

| Fichier | Contenu | Exemple de ligne |
|---|---|---|
| `access.log` (fichiers quotidiens `access-AAAA-MM-JJ.log`, rétention 30 jours) | Chaque requête de l’API (`/api/*`) et du back-office (`/admin*`) ; pages publiques et assets exclus | `GET /api/v1/listings 200 user=3 ip=127.0.0.1 12ms` |
| `error.log` (fichiers quotidiens `error-AAAA-MM-JJ.log`, rétention 30 jours) | Tout le niveau `error` et au-dessus (exceptions, échecs 500), en plus du `laravel.log` complet | `[2026-10-26 11:02:10] local.ERROR: …` |

- Lire le journal des accès :

```powershell
Get-Content storage\logs\access-*.log -Tail 5
```

- `user=-` signifie une requête **non authentifiée** ; le statut affiché est celui réellement rendu (401, 403, 422, 500 compris).
- Le middleware est enregistré **au niveau global** (`backend/bootstrap/app.php`) : c’est la seule position qui permet de tracer les réponses 401, le routeur plaçant sinon `auth:sanctum` avant un middleware de groupe.
- **Les tests ne touchent pas ces fichiers** : la suite écrit dans `storage/logs/testing-*.log`.
- Contrôle rapide pendant que l’API tourne :

```powershell
curl -H "Accept: application/json" http://127.0.0.1:8000/api/v1/listings
Get-Content storage\logs\access-*.log -Tail 3
```

### E-mails (F-09) : de l’inscription à la boîte mail

Depuis le **26 octobre 2026**, le backend envoie trois e-mails transactionnels : **bienvenue à l’inscription**, **confirmation d’annonce mise en ligne** (publication immédiate, mise en ligne manuelle ou publication programmée échue par `soutrali:publish-due`) et **notification « vous avez reçu un message »** dans la messagerie.

**Mode local par défaut — aucun compte requis** : `.env` contient `MAIL_MAILER=log` : chaque e-mail est écrit dans `storage/logs/laravel.log` (en-têtes `To:` / `Subject:`, puis le HTML).

```powershell
Get-Content storage\logs\laravel.log -Tail 40
```

**En réel — Mailjet** (offert : 200 e-mails/jour et 6 000/mois, SMTP, **sans domaine à acheter** : l’expéditeur se valide par un lien reçu dans sa propre boîte) :

1. Créer un compte sur `mailjet.com`, section *Email API* : récupérer la **clé API** et la **clé secrète** (jamais le mot de passe du compte).
2. Vérifier un expéditeur : *Sender* → ajouter une adresse e-mail → cliquer le lien de confirmation reçu dans cette boîte.
3. Renseigner `backend/.env` (fichier non versionné) :

```dotenv
MAIL_MAILER=smtp
MAIL_HOST=in-v3.mailjet.com
MAIL_PORT=587
MAIL_SCHEME=
MAIL_USERNAME=<clé API Mailjet>
MAIL_PASSWORD=<clé secrète Mailjet>
MAIL_FROM_ADDRESS=<adresse expéditrice vérifiée>
MAIL_FROM_NAME="Soutrali"
```

> `MAIL_SCHEME` doit rester **vide** sur le port 587 : Laravel monte alors automatiquement en STARTTLS. La valeur `tls` fait lever `UnsupportedSchemeException` (« the "tls" scheme is not supported ») — corrigé le 26 oct. 2026 après premier envoi réel ; alternative : `MAIL_SCHEME=smtps` avec le port 465.

4. **Redémarrer `php artisan serve`** (le `.env` ne se recharge pas à chaud), puis inscrire un compte : l’e-mail de bienvenue arrive dans la boîte du destinataire.

- **Une panne SMTP ne fait jamais échouer la requête** : inscription, publication et message restent enregistrés ; l’échec est écrit dans `storage/logs/error.log`. Un envoi raté n’est pas rejoué automatiquement — corriger la cause puis refaire l’action.
- Liens cliquables des e-mails : `FRONTEND_URL` (lu par `config/app.php` → `app.frontend_url`), `http://127.0.0.1:8082` en local.
- Tests associés : `backend/tests/Feature/EmailNotificationTest.php` (5 tests : bienvenue, publication immédiate / programmée / manuelle, commande programmée, messages des deux côtés, panne transport).

---

## 5. Application Flutter Web

Depuis `app/`, dans un second terminal :

```powershell
flutter pub get
flutter test
flutter run -d chrome --web-port 8082 --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

- L’écran envoie ses filtres à l’API Laravel. Sans backend démarré, il affiche un état d’indisponibilité et **ne fabrique pas d’annonces fictives**.
- Le build de contrôle se fait avec `flutter build web --release`, servi ensuite pour valider la session Sanctum sur une même origine. Pour servir simplement un build release en local (tir d’essai T1b du 22 oct. 2026) :

```powershell
flutter build web --release
python -m http.server 8082 --bind 127.0.0.1 --directory build\web
```

- **Polices et icônes de marque** : Manrope et Source Sans 3 sont déclarées dans `pubspec.yaml` (fichiers et licences OFL dans `app/assets/fonts/`). Les icônes web et favicons sont générés depuis le logo source ; depuis la racine du dépôt, `php brand/generate-icons.php` les régénère si le logo est retravaillé (§15.7 du README).

### Paquet desktop Windows tout-en-un (phase 2)

Depuis la **racine** du dépôt, dans PowerShell :

```powershell
powershell -ExecutionPolicy Bypass -File desktop\build-package.ps1
```

- Étapes : téléchargement de PHP 8.3.36 x64 portable (déjà présent dans `desktop/runtime/php/`), compilation release de l’application (`--dart-define=API_BASE_URL=http://127.0.0.1:8123`), assemblage de `dist/Soutrali-win64/` (backend Laravel + vendor, journaux purgés, runtime PHP), écriture du `.env` du paquet (SQLite, port 8123, `SANCTUM_STATEFUL_DOMAINS=127.0.0.1:8123`, `MAIL_MAILER=log`), `key:generate` + `migrate` + `db:seed`, puis archive `dist/Soutrali-win64.zip`.
- **Prérequis de compilation** : Visual Studio 2022 avec le chargeur « Développement C++ avec les composants par défaut ». Constaté le 27 oct. 2026 : sans Visual Studio, `flutter build windows` répond « Unable to find suitable Visual Studio toolchain ». Sans Visual Studio, utilisez `-SkipFlutter` : le reste du paquet est assemblé avec un build de l’application existant (ou sans exécutable).
- **Sur la poste cible** : dézipper puis double-cliquer sur l’exécutable — il réutilise le backend s’il répond déjà, sinon démarre `php artisan serve` sur `127.0.0.1:8123` avec le PHP embarqué, puis ouvre l’application. Aucune installation (PHP, MySQL, Flutter) n’est requise.
- **Vérifié le 27 octobre 2026 avec le PHP embarqué seul** : `GET /api/v1/categories` → 200 (données du seeder), inscription → 201, connexion → 200, `GET /me` → 200 sur `127.0.0.1:8123` — parcours d’authentification complet sur la base SQLite du paquet.
- Les cookies de session de l’application desktop sont persistants (`PersistCookieJar` dans `%APPDATA%/Soutrali/cookies`) ; l’en-tête `Origin` est envoyé sur chaque requête, indispensable à Sanctum hors navigateur.

---

## 6. Liste de vérification

Cocher chaque ligne après exécution réelle. Ne cocher que ce qui a été observé.

- [x] MariaDB écoute sur 3306
- [x] La base `soutrali` existe avec `utf8mb4_unicode_ci`
- [x] L’utilisateur SQL dédié existe et ses droits sont limités à `soutrali`
- [x] `backend/.env` renseigné, non versionné
- [x] `php artisan migrate` crée les onze tables du modèle conceptuel (plus les tables d’infrastructure Laravel)
- [x] `GET /api/v1/listings` répond en JSON (liste vide acceptée)
- [x] `vendor/bin/pest` passe (tests sur SQLite en mémoire)
- [x] `vendor/bin/pint --test` ne remonte aucun défaut de style
- [x] `vendor/bin/phpstan analyse` ne remonte aucune erreur
- [x] Le panneau `http://127.0.0.1:8000/admin` répond et redirige vers sa page de connexion
- [x] `php artisan schedule:list` affiche `soutrali:publish-due` (publication programmée, vérifié le 24 oct. 2026)
- [x] Icônes web et favicons aux couleurs de la marque présents dans `app/web/` et `backend/public/` (générés le 24 oct. 2026)
- [x] `flutter analyze` ne remonte aucune erreur
- [x] `flutter test` passe
- [x] Le site s’affiche sur `http://127.0.0.1:8082`
- [x] `storage/logs/access.log` se remplit pendant que l’API reçoit des requêtes (26 oct. 2026 : 200 / 401 / 302 relus après trois `curl`)
- [x] Un compte `MODERATEUR` ou `ADMINISTRATEUR` voit l’entrée et le bouton **« Espace admin »** dans l’application ; un `UTILISATEUR` ne les voit pas (26 oct. 2026)
- [x] `EmailNotificationTest` passe : les trois e-mails partent aux bons destinataires, rien n’est envoyé avant la mise en ligne, une panne SMTP n’empêche pas l’inscription (26 oct. 2026)
- [x] Envoi réel accepté par Mailjet (26 oct. 2026) : inscription réelle → e-mail de bienvenue accepté en SMTP, aucune erreur dans `error.log`
- [ ] L’e-mail de bienvenue réellement **reçu** dans la boîte du destinataire (spams compris) — le porteur confirme
- [ ] À 390 px de large, aucun défilement horizontal
- [ ] Sans backend, l’écran affiche l’état d’indisponibilité, pas un écran cassé
- [ ] `php artisan schedule:work` (local) ou le cron (production) tourne pour la publication programmée
- [x] Parcours du paquet desktop vérifié avec le PHP portable seul : catégories 200, inscription 201, connexion 200, `/me` 200 sur `127.0.0.1:8123` (27 oct. 2026)
- [ ] Exécutable Windows du paquet compilé (nécessite Visual Studio, chargeur « Développement C++ », sur le poste de build)

---

## 7. Problèmes connus et solutions

| Symptôme | Cause vérifiée | Solution |
|---|---|---|
| Laravel écoute sur 8000 mais ne répond pas (`HTTP 000`) | Processus `php artisan serve` figé, hérité d’une session précédente | Arrêter le processus (`taskkill /PID <n> /T /F`), relancer proprement |
| Erreur d’authentification SQL au démarrage | Utilisateur `soutrali_dev` inexistant | Créer le compte (§3.3) et renseigner `.env` |
| `GET /api/v1/listings` renvoie une liste vide alors que le serveur tourne | Base migrée mais seeder vide, ou migrations jamais appliquées | Vérifier `SHOW TABLES;` puis appliquer les migrations |
| `composer` introuvable | Absent du PATH | Retrouver l’exécutable du profil utilisateur ou l’ajouter au PATH ; si `vendor/` existe, `php artisan` fonctionne sans lui |
| Page blanche au premier rendu Flutter | Locale française sans délégués Material/Cupertino | Corrigé dans `app/lib/src/app.dart` ; vérifier que les délégués sont présents |
| Impossible de déplacer ou renommer `app/` | Éditeur ouvert tenant le dossier (serveur d’analyse Dart) | Fermer l’éditeur ou le dossier de travail, puis réessayer |
| phpMyAdmin ne répond pas sur `127.0.0.1` | Apache XAMPP non démarré | Démarrer Apache **et** MySQL dans le panneau XAMPP |
| `php artisan test` échoue avec « could not find driver » | Les tests utilisent SQLite en mémoire (`phpunit.xml`) et le PHP CLI installé n’active ni `pdo_sqlite` ni `sqlite3` | Sur le poste de développement, les deux extensions ont été activées le 23 oct. 2026 dans le `php.ini` du PHP WinGet (une sauvegarde `.bak-soutrali` du fichier a été créée à côté) ; `php artisan test` fonctionne alors directement. Sans toucher au `php.ini` : `php -d extension=pdo_sqlite -d extension=sqlite3 vendor/bin/pest` (méthode utilisée le 22 oct. 2026) ; alternative : un `php.ini` temporaire avec `php -c <chemin.ini> vendor/bin/pest` |
| La CI échoue sur `composer test` avec `MissingAppKeyException` | Aucune `.env` n’existe en CI : le fichier est ignoré par Git et `APP_KEY` reste vide | Corrigé le 22 oct. 2026 : `.github/workflows/ci.yml` copie `.env.example` en `.env` puis exécute `php artisan key:generate` avant les tests |
| La CI échoue sur `composer format:check` | Fichiers écrits avec des fins de ligne CRLF sous Windows, imports non triés | Exécuter `vendor/bin/pint` avant de commiter ; `.gitattributes` normalise déjà le dépôt en LF |
| La CI échoue sur `composer analyse` | Larastan ne rattache pas les attributs lus dans une ressource API non annotée | Annoter la ressource avec `@mixin <Modele>` et typer les relations du modèle avec `@return BelongsTo<…>` |
| La CI échoue sur `flutter analyze` avec `setPhysicalSize`/`setDevicePixelRatio` indéfinis | Ces méthodes n’existent pas sur `TestFlutterView` ; l’API expose des accesseurs en écriture | Écrire `tester.view.physicalSize = const Size(…)` et `tester.view.devicePixelRatio = 1.0`, sans `await`, puis `addTearDown(tester.view.resetPhysicalSize)` |
| `argument_type_not_assignable` sur un override Riverpod | Sous Riverpod 3, `provider(arg).overrideWith(...)` attend une fonction à un seul paramètre ; la signature `(ref, arg)` n’existe qu’au niveau de la famille | Surcharger la famille entière : `monProvider.overrideWith((ref, arg) => …)` |
| `UnsupportedSchemeException` « The "tls" scheme is not supported » à l’envoi d’un e-mail | `MAIL_SCHEME=tls` n’est pas un schéma SMTP valide (seuls `smtp` et `smtps` le sont) | Laisser `MAIL_SCHEME=` vide sur le port 587 (STARTTLS automatique), ou `MAIL_SCHEME=smtps` + port 465 (26 oct. 2026) |
| `use_build_context_synchronously` après un `await` | Un `BuildContext` issu d’une `GlobalKey` était protégé par le `mounted` du `State`, sans rapport avec lui | Garder avec `leContexte.mounted` plutôt qu’avec le `mounted` du `State` |
| `Access denied for user '…' (using password: YES)` alors que le mot de passe est juste | Hébergeur avec « Connexion SSL requise » (AlwaysData) : le client `mysql` chiffre automatiquement, **PDO non** | `MYSQL_ATTR_SSL_CA=/etc/ssl/certs/ca-certificates.crt` dans le `.env` (PDO chiffre et vérifie le certificat — voir §9.2) |

---

## 8. Arrêter et relancer les serveurs

Trois serveurs hérités de la session du 21 octobre ont été arrêtés le 22 octobre 2026 (Laravel figé sur 8000, deux serveurs Flutter sur 8081 et 8082). Pour les relancer :

```powershell
# Terminal 1 — API
cd backend
php artisan serve --host 127.0.0.1 --port 8000

# Terminal 2 — site
cd app
flutter run -d chrome --web-port 8082 --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Pour arrêter un serveur devenu muet, identifier son PID puis le terminer :

```powershell
netstat -ano | findstr ":8000"
taskkill /PID <n> /T /F
```

MariaDB, elle, se gère depuis le panneau XAMPP et **ne doit pas** être arrêtée pendant une séance de développement. Sur cette machine elle n’est **pas installée comme service Windows** : si le panneau XAMPP n’est pas ouvert, le serveur se démarre directement avec son binaire :

```powershell
C:\xampp\mysql\bin\mysqld.exe --defaults-file=C:\xampp\mysql\bin\my.ini
```

Laisser cette fenêtre ouverte pendant la séance ; la fermer arrête la base. Vérifier ensuite que le port 3306 répond avant de lancer Laravel.

---

## 9. Mise en ligne en production (AlwaysData)

> **Réalisé le 28 octobre 2026** — site : **https://soutrali.alwaysdata.net** (offre gratuite AlwaysData : 1 Go, MariaDB, HTTPS wildcard `*.alwaysdata.net`, SSH, cron). Faits, contrôles et diagnostic e-mails détaillés dans `SUIVI_DEVELOPPEMENT.md` §2 (28 oct.).

### 9.1 Création dans le panneau (une fois)

1. **Web ▸ Sites ▸ Add a site** : adresse `soutrali.alwaysdata.net`, type **PHP 8.3+**, chemin du site `www/soutrali`.
2. **Databases ▸ MySQL** : base `soutrali_bd` + utilisateur (ici `soutrali`), « Connexion SSL requise » possible — voir 9.2.
3. **Remote Access ▸ SSH/SFTP** : ajouter une clé SSH publique pour le déploiement.
4. **Advanced ▸ Scheduled tasks** : `cd /home/soutrali/soutrali/backend && php artisan schedule:run` **toutes les minutes** (le `crontab` est refusé en SSH sur AlwaysData).

### 9.2 Déploiement par SSH

```bash
git clone --depth 1 --branch labo-soutrali-v2 https://github.com/0Defiance/soutrali.git /home/soutrali/soutrali
cd /home/soutrali/soutrali/backend
composer install --no-dev --optimize-autoloader
```

`.env` de production (les clés et mots de passe ne transitent **jamais** par une conversation) :

- `APP_ENV=production`, `APP_DEBUG=false`, `LOG_LEVEL=error` ;
- `APP_URL` et `FRONTEND_URL=https://soutrali.alwaysdata.net` (CORS s’appuie sur `FRONTEND_URL`) ;
- `SESSION_DOMAIN` et `SANCTUM_STATEFUL_DOMAINS=soutrali.alwaysdata.net` ;
- `DB_HOST=mysql-soutrali.alwaysdata.net`, `DB_DATABASE=soutrali_bd`, utilisateur et mot de passe du panneau ;
- **`MYSQL_ATTR_SSL_CA=/etc/ssl/certs/ca-certificates.crt`** — obligatoire si le panneau impose le SSL : sans lui, PDO échoue avec « Access denied » alors que le client `mysql` se connecte (voir §7) ;
- bloc `MAIL_*` Mailjet avec un **expéditeur vérifié** dans Mailjet : un domaine « En attente » est accepté en SMTP puis jamais distribué (constaté le 28 oct.).

Ensuite, sur le serveur :

```bash
php artisan key:generate --force
php artisan migrate --force && php artisan db:seed --force
php artisan optimize
ln -sfn /home/soutrali/soutrali/backend/public /home/soutrali/www/soutrali  # .env hors racine web
php artisan soutrali:create-admin <email>   # mot de passe saisi en clair-masqué
```

### 9.3 Vérifications minimales

```bash
curl https://soutrali.alwaysdata.net/up                          # 200
curl https://soutrali.alwaysdata.net/api/v1/categories           # 200, 32 services
curl -I https://soutrali.alwaysdata.net/admin                    # 302 vers /admin/login
```
Puis inscription réelle (201), `GET /me` avec session (200), connexion `/admin` avec le compte créé, et contrôle de `storage/logs/access.log`.

### 9.4 Front Flutter en ligne (la racine du site)

**Depuis le 28 octobre 2026**, `/` sert l’application Flutter et non plus la page d’accueil Laravel. Le partage est assuré par `backend/public/.htaccess` : `DirectoryIndex index.html index.php` fait servir `index.html` à la racine, et un repli vers `index.html` couvre les liens profonds Flutter — **sauf** `/api` et `/admin`, restés au front controller Laravel. Le site reste un lien unique `www/soutrali → backend/public` ; `.env` demeure hors racine web.

Déploiement du front (à refaire à chaque changement de l’application) :

```bash
cd app
flutter build web --release --dart-define=API_BASE_URL=https://soutrali.alwaysdata.net
tar czf - -C build/web . | ssh -i <clé> soutrali@ssh-soutrali.alwaysdata.net \
  'tar xzf - -C /home/soutrali/soutrali/backend/public'
```

Vérifications :

```bash
curl -s https://soutrali.alwaysdata.net/ | grep '<title>'   # Soutrali — L’entraide à porter de main
curl -o /dev/null -w '%{http_code}\n' https://soutrali.alwaysdata.net/connexion   # 200 (lien profond Flutter)
curl https://soutrali.alwaysdata.net/api/v1/listings         # JSON, toujours traité par Laravel
curl -I https://soutrali.alwaysdata.net/admin                # 302 vers /admin/login
```

> Le serveur ne renvoie pas d’en-tête `Cache-Control` sur `index.html` : après un redéploiement, **Ctrl+F5** dans le navigateur, sinon l’ancien bundle reste en cache.
