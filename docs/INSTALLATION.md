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
- `php artisan db:seed` charge le référentiel validé : **14 lignes de communes** (13 communes d’Abidjan + zone « Plusieurs communes », D-03) et **8 catégories** (D-07). En environnement `local` uniquement, il charge aussi `DemoSeeder` : 2 comptes et 8 annonces **fictifs** pour les recettes. Aucun contenu fictif n’est chargé en préproduction ni en production. Vérifier ensuite :

```powershell
curl -H "Accept: application/json" http://127.0.0.1:8000/api/v1/communes
curl -H "Accept: application/json" http://127.0.0.1:8000/api/v1/categories
```
- Vérifier que l’API répond :

```powershell
curl -H "Accept: application/json" http://127.0.0.1:8000/api/v1/listings
```

Une base migrée mais vide renvoie une liste vide ; c’est un résultat **normal**, pas une erreur.

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
- [x] `flutter analyze` ne remonte aucune erreur
- [x] `flutter test` passe
- [x] Le site s’affiche sur `http://127.0.0.1:8082`
- [ ] À 390 px de large, aucun défilement horizontal
- [ ] Sans backend, l’écran affiche l’état d’indisponibilité, pas un écran cassé

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
| `use_build_context_synchronously` après un `await` | Un `BuildContext` issu d’une `GlobalKey` était protégé par le `mounted` du `State`, sans rapport avec lui | Garder avec `leContexte.mounted` plutôt qu’avec le `mounted` du `State` |

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
