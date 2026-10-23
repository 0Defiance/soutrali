# Soutrali — Suivi de développement

> **Objet :** journal technique étape par étape du socle Soutrali. Il répond à une seule question : *où en est réellement l’implémentation, qu’est-ce qui a été vérifié, qu’est-ce qui bloque, et que reste-t-il à faire ?*
>
> **Ce document n’est pas le cadrage fonctionnel.** Le cadrage (besoins, règles métier, périmètre MVP, décisions D-xx) vit dans [`README.md`](../README.md). L’architecture de référence vit dans [`README_TECHNIQUE.md`](README_TECHNIQUE.md). La procédure de démarrage vit dans [`INSTALLATION.md`](INSTALLATION.md).
>
> **Règle d’or :** chaque entrée décrit un fait observé, jamais une intention. Si une mesure n’a pas été faite, elle est écrite « non mesurée ». Si un seuil n’est pas fixé par la MOA, aucun chiffre n’est proposé.
>
> **Version :** 1.1 · **Dernière mise à jour :** 23 octobre 2026

---

## Sommaire

1. [État vérifié en un coup d’œil](#1-état-vérifié-en-un-coup-dœil)
2. [Journal chronologique](#2-journal-chronologique)
3. [Ce qui est fait et vérifié](#3-ce-qui-est-fait-et-vérifié)
4. [Ce qui bloque, et pourquoi](#4-ce-qui-bloque-et-pourquoi)
5. [Ce qui reste à faire, dans l’ordre](#5-ce-qui-reste-à-faire-dans-lordre)
6. [Décisions techniques applicables](#6-décisions-techniques-applicables)
7. [FAQ — priorité web](#7-faq--priorité-web)
8. [Comment tenir ce document à jour](#8-comment-tenir-ce-document-à-jour)

---

## 1. État vérifié en un coup d’œil

Constats relevés le **23 octobre 2026** sur le poste de développement, par exécution réelle des commandes.

| Élément | Constat vérifié |
|---|---|
| Dépôt distant | `github.com/0Defiance/soutrali`, branche `main`, publique. Contient désormais le code, la documentation et le cadrage |
| Dépôt local | Initialisé le 22 oct. 2026, index aligné sur `main`, arborescence réorganisée |
| Flutter / Dart | 3.47.7 / 3.13.5 installés et fonctionnels (`flutter --version` exécuté) |
| PHP CLI | 8.3.33 installé séparément de XAMPP, fonctionnel (`php -v` exécuté) |
| Composer | **Absent du PATH** de la session de commande, mais l’exécutable a été retrouvé : `php "C:\Users\Abd Al Fattah\AppData\Local\Programs\Composer\composer.phar"` — Composer 2.10.3, chemin documenté dans `INSTALLATION.md` |
| Git | 2.56.0 fonctionnel |
| GitHub CLI | 2.102.1 installée, **non authentifiée** (`gh auth status` : aucune session) |
| MariaDB | 10.4.32 démarrée sur le port 3306 (revérifié le 22 oct. : le port écoute) |
| Base `soutrali` | **Migrée : 17 tables.** `php artisan migrate:status` affiche les 4 migrations « Ran » (revérifié le 22 oct.) |
| Utilisateur SQL `soutrali_dev` | **Créé le 22 oct. 2026**, droits limités à `soutrali.*`. `backend/.env` l’utilise et `php artisan migrate:status` s’y connecte sans erreur |
| `backend/.env` | Présent localement, **correctement ignoré par Git**, non publié |
| Icônes web | `app/web/icons/*` et `app/web/favicon.png` sont les **icônes par défaut du squelette Flutter**, pas la marque Soutrali |
| `backend/public/favicon.ico` | **Fichier vide (0 octet)** |
| Polices | Manrope et Source Sans 3 **non embarquées** ; le thème retombe sur `Arial` |
| Serveurs de développement | À la reprise du 23 oct. : MariaDB relancée (`mysqld.exe` XAMPP, port 3306), API Laravel sur `127.0.0.1:8000` (`php artisan serve`) répondant HTTP 200, build web release servi sur `127.0.0.1:8082` (Python http.server). PHP 8.3 (WinGet) : extensions `pdo_sqlite` et `sqlite3` activées dans `php.ini` (sauvegarde `.bak-soutrali` créée) pour permettre `php artisan test` en local |
| Fonctionnalités pilotes | **Inscription, connexion, session, publication, modification, clôture avec issue, messagerie interne, signalement : implémentées et vérifiées** (D-04, D-05, D-06 validées le 22 oct. 2026) |
| Back-office `/admin` | **Opérationnel et testé** (23 oct. 2026) : panneau Filament 5 (7 ressources, 8 policies, mode strict), traitement des signalements tracé dans `moderation_actions`, accès réservé aux comptes `MODERATEUR` / `ADMINISTRATEUR` actifs |
| Tests | 23 oct. 2026 : `flutter analyze` sans problème ; **14 tests Flutter** verts ; **33 tests Pest** verts (244 assertions, SQLite en mémoire, dont 9 tests du back-office) |

**Conclusion :** l’étape T1 (référentiels en base, exposés par l’API, consommés par l’écran) est faite et vérifiée ; les étapes pilotes T2/T3/T4 (comptes, annonces, contact, signalement, clôture) sont faites et le parcours complet inscription → publication → contact → signalement → clôture est observé en local. **Le tir d’essai T1b n’est plus bloqué** : la session Sanctum est validée de bout en bout ; restent les mesures téléphone (poids compressé, premier écran utile) à cadrer avec la MOA.

---

## 2. Journal chronologique

### 20 octobre 2026 — socle initial

- Stack technique v3.1 rédigée puis **validée par le porteur du projet** (décisions T-01 à T-14). La validation MOA reste à venir.
- Création du squelette Laravel 13 dans `backend/` : manifeste Composer, configuration, migrations des tables du modèle conceptuel.
- Création du projet Flutter dans `app/` : page de découverte, thème aux couleurs de la charte v2, client HTTP vers `GET /api/v1/listings`.
- Publication manuelle de la documentation sur GitHub (le dépôt ne contenait alors que le cadrage et les documents Word).

### 21 octobre 2026 — premier rendu web et premiers blocages

- `flutter analyze` propre et les deux tests Flutter passent depuis `app/`. **Ce constat n’a pas été reproductible le 22 octobre** : voir la correction détaillée plus bas dans la journée du 22.
- Le squelette navigateur (`app/web/`) n’existait pas : il a été généré dans un dossier temporaire puis copié dans l’application, sans écraser les fichiers existants.
- Build web release généré. **Mesure partielle :** le JavaScript principal faisait environ **2,96 Mo non compressé**. Cette mesure n’inclut ni le transfert compressé, ni les ressources du moteur, ni le temps jusqu’au premier écran utile. Le tir d’essai n’est donc pas déclaré terminé.
- Page blanche au premier rendu : cause identifiée et corrigée — l’application fixe la locale française sans fournir les délégués de localisation Material/Cupertino. Correction dans `app/lib/src/app.dart`.
- Rendu contrôlé sur ordinateur et à 390 px, sans débordement horizontal.
- Ajout des actions « Annonce » et « Prestation de service » avec leurs choix immédiat/programmé et leurs formulaires. **Les formulaires valident la saisie côté interface mais n’enregistrent rien en base** : les routes d’authentification et de publication n’existent pas.
- Création de la base `soutrali` dans phpMyAdmin (utf8mb4 / utf8mb4_unicode_ci). **Les migrations n’ont pas été appliquées** : la base est restée vide.
- Tentatives de push GitHub : échecs. Le dossier source n’était pas un dépôt Git et la session de commande ne restituait pas les sorties de Git ; GitHub CLI n’était pas authentifiée. Aucun commit ni push n’a été créé ce jour-là.

### 22 octobre 2026 — publication du code et alignement local/distant

- Vérification de l’environnement : PHP 8.3.33, Flutter 3.47.7, Git 2.56.0 répondent ; Composer est absent du PATH ; GitHub CLI n’est pas authentifiée.
- Constat des blocages hérités : base `soutrali` vide, utilisateur SQL `soutrali_dev` inexistant, processus Laravel figé sur le port 8000 (il écoutait sans répondre).
- Arrêt, avec accord explicite du porteur, des trois serveurs hérités (PID `php.exe` sur 8000, deux `dartvm.exe` sur 8081 et 8082). MariaDB conservée sur 3306.
- Initialisation du dépôt Git local, raccordement du remote `origin`, récupération de `main` et alignement de l’index sur l’arbre distant **sans écraser les fichiers locaux**.
- Réorganisation de l’arborescence pour que le dossier local miroite le dépôt : `app/`, `backend/`, `.github/`, `.gitignore` à la racine ; documentation consolidée sous `docs/` ; Documentation v1 archivée sous `docs/archive/` ; logo placé dans `brand/logo/`.
  - Le dossier `app/` était verrouillé par l’éditeur ouvert (serveur d’analyse Dart) : son **contenu** a été déplacé. Le dossier vide `Code Source Soutrali/app/` subsiste sur le disque et ne peut être supprimé qu’éditeur fermé ; il ne contient aucun fichier et Git l’ignore.
- Ajout de `.gitattributes` pour normaliser les fins de ligne (développement Windows, CI et hébergement Linux) : sans cela `backend/artisan` risque de recevoir des CRLF et de casser côté Linux.
- Contrôle des règles d’ignore : `backend/.env`, `backend/vendor/`, `app/build/`, `app/.dart_tool/` et les journaux sont ignorés ; `.env.example`, `pubspec.lock` et `composer.lock` sont suivis, conformément à T-08.
- Contrôle des secrets sur les 97 fichiers publiés : aucun `APP_KEY` renseigné, aucune clé privée, aucun jeton, aucun mot de passe. `backend/.env.example` a `APP_KEY=` et `DB_PASSWORD=` vides.
- Nettoyage des deux dossiers temporaires créés par les tentatives de clone de la session précédente (`soutrali-github-worktree/`, `Code Source Soutrali/.git`) : contrôlés avant suppression, ils ne contenaient aucun commit et aucun fichier absent du dépôt.
- Suppression du logo dupliqué dans `docs/archive/` : empreinte MD5 identique à `brand/logo/soutrali-logo-couleurs.png`, aucune référence dans la documentation. Un seul exemplaire est conservé (1,1 Mo économisés).
- Correction des sections périmées du README de cadrage (§15.7 dossier `brand/` inexistant, §19.1 phases, §22.3 « aucun code », §23 liste des documents, §25 journal, §26 prochaines étapes) et de l’image d’en-tête cassée.
- Rédaction du présent document et de `INSTALLATION.md`, à partir de l’ancien `README.md` du dossier code, scindé en deux pour séparer le *suivi* de la *procédure*.
- Publication sur `origin/main` : commits créés localement puis push lancé, l’authentification GitHub étant ouverte par Git Credential Manager côté porteur. Le résultat vérifié (empreinte du commit distant, arborescence publiée, état de la CI) est consigné à la suite de cette journée.
- Résultat vérifié de la publication : `origin/main` pointe sur `e3d8429`, empreinte identique au HEAD local. La racine distante contient `.gitattributes`, `.github/`, `.gitignore`, `README.md`, `app/`, `backend/`, `brand/` et `docs/`. Aucun fichier `.env`, `vendor/`, `build/` ou `.dart_tool/` n’est publié. Le logo distant `brand/logo/soutrali-logo-couleurs.png` (1 149 220 o) est bien au chemin référencé par l’en-tête du README.

### 22 octobre 2026, suite — premier passage de la CI et corrections

La CI s’est exécutée pour la première fois sur le commit de publication (exécution n°1, commit `e3d8429`). Trois défauts réels sont apparus côté backend ; chacun a été reproduit localement avant d’être corrigé.

| Étape CI | Constat | Cause vérifiée | Correction |
|---|---|---|---|
| `composer test` | échec, code de sortie 2 | Aucune `.env` en CI : ce fichier est ignoré par Git, `APP_KEY` reste vide et le test fonctionnel lève `MissingAppKeyException` | Le workflow copie `.env.example` en `.env` puis exécute `php artisan key:generate` avant les tests |
| `composer format:check` | jamais atteinte en CI ; 13 défauts constatés en local | Fins de ligne CRLF, imports non triés, import inutilisé, position d’accolades | `pint` exécuté sur le backend |
| `composer analyse` | jamais atteinte en CI ; 10 erreurs constatées en local | `PublicListingResource` lit les attributs du modèle sans que Larastan puisse les lui rattacher, et les relations `category` / `commune` ne sont pas typées | `@mixin Listing` sur la ressource et `@return BelongsTo<…>` sur les trois relations du modèle |

Vérifications locales après correction, avec PHP 8.3.33 :

- `pest` : 2 tests passés, 2 assertions.
- `pint --test` : PASS sur 36 fichiers.
- `phpstan analyse` (Larastan, niveau 5) : aucune erreur.

Les tests backend utilisent SQLite en mémoire (`backend/phpunit.xml`) : les extensions `pdo_sqlite` et `sqlite3` sont désormais explicitement demandées dans le workflow. Sur le poste de développement, le PHP installé ne les active pas par défaut ; les vérifications locales ont été faites avec un `php.ini` temporaire qui les charge, **sans modifier la configuration globale de PHP**.

Job `flutter` de cette même exécution : `checkout`, installation de Flutter 3.47.7 et `flutter pub get` ont réussi ; `flutter analyze` était encore en cours au moment de la rédaction. Son résultat n’est donc pas affirmé ici.

### 22 octobre 2026, second passage de la CI

L’exécution n°2 (commit `84961f6`) donne : **job `backend` réussi**, toutes étapes confondues (`composer test`, `format:check`, `analyse`). Les trois corrections ci-dessus sont donc validées par la CI elle-même.

Le **job `flutter` échoue** en revanche sur `flutter analyze`, ce qui bloque `flutter test` et `flutter build web --release`.

**Correction d’un constat antérieur erroné.** Le journal du 21 octobre et le §3 annonçaient « `flutter analyze` propre » et « deux tests passent ». Ce n’était **pas reproductible** le 22 octobre : `flutter analyze` remonte **11 problèmes dont 10 erreurs**, et la suite compte en réalité **5 tests**, dont 3 dans un fichier qui ne compilait pas. Les affirmations antérieures sont remplacées par les mesures ci-dessous.

| Problème | Fichier | Cause vérifiée | Correction |
|---|---|---|---|
| `setPhysicalSize` / `setDevicePixelRatio` indéfinis (6 erreurs) | `test/features/discover/publication_actions_test.dart` | Ces méthodes n’existent pas sur `TestFlutterView` ; l’API expose des **accesseurs en écriture** `physicalSize` et `devicePixelRatio` | Affectation directe, sans `await` ; les `reset*` utilisés en `addTearDown` existent bien |
| « The name 'Size' isn't a class » (3 erreurs) | idem | `Size` n’était importé par aucun des imports présents | Ajout de `import 'package:flutter/material.dart';` |
| `argument_type_not_assignable` sur l’override (1 erreur) | idem | `listingsProvider(filtres).overrideWith(...)` attend une fonction à **un** paramètre ; la signature à deux paramètres `(ref, arg)` n’existe qu’au niveau de la **famille** Riverpod 3 | Override de la famille : `listingsProvider.overrideWith((ref, filters) => ...)` |
| `use_build_context_synchronously` (1 info) | `lib/src/features/discover/discover_page.dart` | Un `BuildContext` issu d’une `GlobalKey` était protégé par le `mounted` du `State`, que le lint considère comme sans rapport | Garde remplacée par `headingContext.mounted` |

Vérifications locales après correction, avec Flutter 3.47.7 :

- `flutter analyze` : **No issues found**.
- `flutter test` : **5 tests passés** (2 sur le modèle d’annonce, 3 sur les actions de publication).
- `flutter build web --release` : **compilation réussie**. La police d’icônes Material est réduite de 1 645 184 à 9 996 octets par tree-shaking. Un avertissement subsiste sur la famille `CupertinoIcons` absente des assets ; il n’empêche pas le build et sera traité avec l’identité visuelle (§5, point 7).
- L’essai de compilation WebAssembly lancé automatiquement par Flutter réussit (`--wasm`), ce qui documente la piste de repli prévue par T-09.

L’exécution n°3 (commit `2069a1f`) est **entièrement réussie** : les jobs `backend` et `flutter` passent tous deux, y compris `flutter test` (5 tests) et `flutter build web --release`. L’intégration continue du dépôt est donc verte de bout en bout pour la première fois.

### 22 octobre 2026, étape T0 — environnement débloqué

- MariaDB était arrêtée et n’est pas installée comme service Windows. Elle a été démarrée directement avec le binaire XAMPP : `mysqld.exe --defaults-file=C:/xampp/mysql/bin/my.ini`. Version constatée à la connexion : **10.4.32-MariaDB**.
- Création du compte dédié **`soutrali_dev`** pour `127.0.0.1` et `localhost`, avec un mot de passe généré aléatoirement. Ce mot de passe n’est écrit **que** dans `backend/.env` ; il n’apparaît ni dans ce document, ni dans un commit, ni dans une capture. Droits limités à `soutrali.*` : le compte ne voit aucune autre base applicative.
- `backend/.env` basculé de `root` sans mot de passe vers `soutrali_dev`, conformément à la règle « éviter le compte root sans mot de passe ».
- `php artisan migrate` exécuté avec succès : **17 tables** créées, soit les onze tables du modèle conceptuel (`communes`, `users`, `categories`, `listings`, `sessions`, `personal_access_tokens`, `contact_channels`, `user_blocks`, `interactions`, `reports`, `moderation_actions`) plus six tables d’infrastructure Laravel (`cache`, `cache_locks`, `jobs`, `job_batches`, `failed_jobs`, `migrations`).
- API démarrée sur `127.0.0.1:8000` : `GET /api/v1/listings` répond **HTTP 200** avec une liste paginée vide au format attendu (`data`, `links`, `meta`, `per_page` 12, `total` 0). C’est la première fois que la chaîne complète navigateur → API → Laravel → MariaDB est observée fonctionnelle.
- Le seeder reste vide : aucune commune ni catégorie n’est chargée. Les routes `GET /api/v1/categories` et `/communes` n’existent pas encore, et aucune route de publication n’existe ; alimenter le seeder n’aurait donc aucun effet observable tant que ces routes ne sont pas écrites. L’étape T1 est reportée à ce titre.

### 22 octobre 2026, étape T1 — référentiels et premier tir d’essai avec données

**Arbitrages reçus du porteur** : D-03 confirmée (13 communes d’Abidjan + zone « Plusieurs communes »), D-07 confirmée (8 catégories), chargement de 6 à 8 annonces fictives et de 2 comptes de test pour le tir d’essai, recherche de l’exécutable Composer autorisée. Ces deux décisions passent de « Proposé » / « Ouvert » à **Validé le 22 octobre 2026** dans le registre du README.

Backend :

- `CommuneSeeder` (14 lignes), `CategorySeeder` (8 catégories avec description) et `DemoSeeder` (2 comptes fictifs, 8 annonces publiées, aucun nom réel). `DatabaseSeeder` charge toujours les référentiels, et ne charge `DemoSeeder` **que** en environnement `local` : aucun contenu fictif en préproduction ni en production.
- Nouvelles routes publiques `GET /api/v1/categories` et `GET /api/v1/communes` (contrôleur `PublicReferenceController`, throttle 60/min, éléments `active` uniquement, tri par nom côté moteur).
- Correction de `UserFactory` : la colonne `name` n’existe pas dans `users`, la factory écrivait `display_name`.
- `php artisan db:seed` exécuté sur la base locale. Vérification par requêtes HTTP réelles sur `127.0.0.1:8000` : `/communes` renvoie **14 communes** (dont « Plusieurs communes »), `/categories` renvoie **8 catégories**, `/listings` renvoie **8 annonces** avec commune et catégorie résolues.
- Vérifications après correction, avec PHP 8.3.33 : `pint --test` **PASS sur 41 fichiers** ; `phpstan analyse` (Larastan niveau 5) **aucune erreur** ; `pest` **7 tests passés, 58 assertions** (dont 5 créés pour T1 : routes de référentiels, exclusion des éléments inactifs, filtrage des annonces, absence de coordonnée privée). Les extensions SQLite étant toujours absentes de la configuration PHP, les tests sont lancés avec `php -d extension=pdo_sqlite -d extension=sqlite3 vendor/bin/pest` — aucun `php.ini` global modifié.

Application Flutter :

- Nouveau dépôt `references_repository.dart` : modèle `ReferenceItem`, providers `communesProvider` et `categoriesProvider` vers les nouvelles routes.
- Écran de découverte : le filtre « Commune » n’est plus codé en dur (liste partielle de 8) mais alimenté par l’API ; un filtre « Catégorie » est ajouté ; `ListingFilters` accepte `category` (identifiant) et l’envoie en requête. En cas d’échec de chargement, les listes dégradent en « Communes / Catégories indisponibles » sans casser l’écran.
- Vérifications : `flutter analyze` **No issues found** ; `flutter test` **9 tests passés** (les 5 précédents + 3 sur `ReferenceItem` / `ListingFilters` + 1 test widget vérifiant que la sélection commune + catégorie est bien transmise au fournisseur d’annonces).
- `flutter build web --release` : **compilation réussie en 183,6 s**. Poids constatés sur `build/web` : `main.dart.js` **3 294 322 o brut / 942 397 o en gzip** ; `canvaskit/canvaskit.wasm` 7 284 602 o (2 916 585 o en gzip), servi par le CDN `gstatic.com` par défaut ; police d’icônes Material 9 996 o après tree-shaking ; total sur disque du dossier `build/web` 42 799 985 o (variants canvaskit inclus).

**Tir d’essai T1b observé** (build release servi sur `127.0.0.1:8082`, API sur `127.0.0.1:8000`) :

- Requêtes réseau constatées depuis le navigateur, toutes en **HTTP 200** : `GET /api/v1/listings`, `/communes`, `/categories`, puis les filtres réels `GET /api/v1/listings?type=DEMANDE` et `?q=Déménagement&type=DEMANDE`.
- Aucun message d’erreur console ; CORS OK (origine `127.0.0.1:8082` autorisée avec crédentiels).
- Rendu constaté via l’arbre d’accessibilité de la page : la carte « Aide au déménagement un samedi — Marcory — 16 oct. — Transport léger et déménagement » apparaît dans la section « Annonces près de vous », issus de la base MariaDB.
- **Non mesurés :** le temps jusqu’au premier écran utile sur téléphone (aucun téléphone instrumenté dans cette séance), le poids réellement transféré compressé (le serveur local de test ne compresse pas), et la session Sanctum (routes d’authentification inexistantes, D-04 toujours ouverte).

### 22 octobre 2026, soir — étapes pilotes T2/T3/T4 : comptes, publication, contact, signalement, clôture

**Arbitrages reçus du porteur** : D-04 validée (inscription e-mail + mot de passe, sans SMS), D-05 validée (messagerie interne tracée, aucune coordonnée privée exposée), D-06 validée (publication immédiate + modération a posteriori par signalement).

Backend :

- `AuthController` : `POST /api/v1/register` (nom affiché, e-mail unique, mot de passe 8 car. minimum avec confirmation, commune facultative ; connexion ouverte immédiatement), `POST /api/v1/login` (message d’erreur identique que le compte existe ou non — pas d’énumération de comptes ; refus si le compte n’est pas `ACTIF`), `POST /api/v1/logout` (invalidation de session), `GET /api/v1/me`, `GET /api/v1/csrf-token` (jeton CSRF renvoyé en JSON pour le client Flutter).
- `MyListingController` (authentifié) : `POST /api/v1/listings` (publication immédiate, statut `PUBLIEE`), `GET /v1/me/listings`, `PATCH /api/v1/listings/{id}` (seul le propriétaire, sinon 403), `POST /api/v1/listings/{id}/close` avec `closure_outcome` (409 si déjà clôturée).
- `ConversationController` : `POST /api/v1/listings/{id}/conversations` (démarrer ou reprendre un fil avec un premier message ; refus 403 sur sa propre annonce, 404 si l’annonce n’est pas `PUBLIEE`), `GET /api/v1/conversations` (fils + non-lus), `GET /api/v1/conversations/{id}` (marque les messages reçus comme lus), `POST .../messages`.
- `ReportController` : `POST /api/v1/listings/{id}/reports` (motif + détails, statut `NOUVEAU`, refus de signaler sa propre annonce), `GET /api/v1/me/reports`.
- Migration `2026_10_22_000001_create_messages_table.php` ; les tables `interactions` et `reports` de la migration centrale sont désormais exploitées.
- `DemoSeeder` enrichi d’un fil de démonstration (2 messages) consultable en se connectant comme Koffi.

Application Flutter :

- `auth_repository.dart` (modèle `AuthUser`, `AuthController` Riverpod, `prepareCsrf` avant chaque mutation), `login_page.dart`, `register_page.dart` (validation champ par champ, renvoi des erreurs 422 de l’API).
- `account_repository.dart` et `my_listings_page.dart` : mes annonces (tous statuts), modification, clôture avec issue.
- `messaging_repository.dart` et `messages_page.dart` : liste des fils avec non-lus, vue de fil, envoi de messages.
- `listing_detail_page.dart` : détail d’une annonce, bouton contacter (renvoie vers la connexion si visiteur), signalement, et garde-fou « C’est votre annonce » pour l’auteur.
- `discover_page.dart` : en-tête avec compte connecté (menu : mes annonces, messagerie avec badge de non-lus, déconnexion), actions publier (choix immédiat/programmé puis formulaire complet), cartes cliquables vers le détail, signalement.
- `app.dart` : routes `/login`, `/register`, `/listing/:id`, `/mes-annonces`, `/messagerie`, `/messagerie/:id`.
- Tests : `auth_pages_test.dart` (validation e-mail/mot de passe, liens entre connexion et inscription) et extensions de `publication_actions_test.dart` (visiteur invité à se connecter avant de publier).

### 23 octobre 2026 — tir d’essai complet, correction du contrat `budget`, suites de tests vertes

- Reprise de séance après redémarrage de la machine : MariaDB relancée avec `mysqld.exe` (XAMPP), API et serveur web statique relancés. **Constat** : `GET /api/v1/listings` répond 200 mais l’écran Flutter affiche l’état d’erreur.
- **Bug identifié** : les listings dont `budget` est renseigné sont sérialisés avec `budget` en **chaîne** (`"10000.00"`, conséquence du cast `decimal:2` d’Eloquent), alors que `Listing.fromJson` faisait `json['budget'] as num?` : le cast lève une exception et **casse l’interprétation de toute la réponse**, d’où l’écran d’erreur malgré un HTTP 200.
- **Correction double** : `PublicListingResource` et `MyListingResource` forcent un nombre JSON (`(float) $this->budget`) ; `Listing.fromJson` et `MyListing.fromJson` tolèrent désormais la chaîne (`num.tryParse`).
- Revérification dans le navigateur (build web régénéré) : la liste s’affiche et l’annonce publiée pendant le tir d’essai (« Besoin d'aide pour déménager un frigo », Yopougon) apparaît dans le fil.
- **Parcours navigateur observé** : inscription complète (création du compte « Aïcha Traoré », HTTP 201 puis redirection), session ouverte, publication d’une annonce (choix « Demande immédiate », catégorie et commune sélectionnées, nature rémunérée, HTTP 201), détail de l’annonce avec garde-fou auteur, rendu de la carte dans le fil.
- **Chaîne contact → signalement → clôture rejouée par API avec deux comptes** (Koffi et Awa, jeton CSRF JSON, session par cookie) : 12 scénarios exécutés et conformes — démarrage de fil (201), reprise du fil existant, liste des fils avec non-lus, lecture (accusé), réponse (201), non-lus côté autre participant, signalement (201, statut NOUVEAU), refus de signaler sa propre annonce (422), refus de clôturer l’annonce d’autrui (403), clôture (statut CLOTUREE), double clôture (409), contact d’une annonce clôturée (404), liste des signalements de l’auteur.
- **Extensions PHP** : `pdo_sqlite` et `sqlite3` activées dans le `php.ini` du PHP WinGet (sauvegarde `.bak-soutrali` à côté), nécessaires à `php artisan test` (SQLite en mémoire). Aucune modification de PHP XAMPP.
- **Vérifications finales, avec PHP 8.3 et Flutter 3.47.7** : `flutter analyze` **No issues found** ; `flutter test` : **14 tests passés** ; `php artisan test` : **24 tests passés, 163 assertions** (AuthTest, MyListingTest, ConversationTest, ReportTest, contrats publics).

### 23 octobre 2026, après-midi — back-office Filament (T2/T4) : modération traitée et tracée

- **Panneau `/admin` opérationnel** (T-05) : `AdminPanelProvider` affiche « Soutrali — Administration » aux couleurs de la charte v2 (orange `#FE7402`, vert `#037C30`), navigation groupée Modération / Contenus / Comptes, et **`strictAuthorization()`** : toute ressource sans policy explicite lève une exception au lieu d’autoriser silencieusement. L’accès est limité par `User::canAccessPanel` aux comptes `MODERATEUR` ou `ADMINISTRATEUR` dont le statut est `ACTIF` ; anonymes et utilisateurs ordinaires sont renvoyés.
- **7 ressources** : signalements (consultation + traitement — jamais de création ni de suppression depuis le back-office), annonces (édition limitée, masquage / republication tracés, suppression interdite), utilisateurs (aucune suppression : suspension à la place, rôle et statut réservés aux administrateurs), catégories et communes (création, édition, **désactivation** — la suppression est refusée par policy), interactions (lecture des fils et de leurs messages en lecture seule), journal des actions de modération (lecture seule). Deux widgets sur le tableau de bord : compteurs et derniers signalements.
- **8 policies** enregistrées explicitement dans `AppServiceProvider` (`Category`, `Commune`, `Interaction`, `Listing`, `Message`, `ModerationAction`, `Report`, `User`) — requis par le mode strict du panneau.
- **Décisions de modération tracées** : enum `App\Support\Moderation\Decision` (`PRISE_EN_CHARGE`, `ANNONCE_MASQUEE`, `ANNONCE_REPUBLIEE`, `SIGNALEMENT_REJETE`, `SANS_SUITE`, `COMPTE_SUSPENDU`, `COMPTE_REACTIVE`) et service `ReportModerator` : chaque décision crée une ligne `moderation_actions` horodatée (modérateur, décision, justification) et fait évoluer le statut du signalement (`NOUVEAU` → `EN_COURS` / `TRAITE` / `REJETE`). Le masquage d’une annonce déjà clôturée est refusé.
- **Défaut trouvé par les tests** : `UserFactory` ne renseignait ni `role` ni `status` — les valeurs par défaut (`UTILISATEUR` / `ACTIF`) n’existent qu’en base, l’instance en mémoire avait donc `status = null`, ce qui rendait `isModerator()` / `canAccessPanel()` faux et provoquait des 403 en cascade dans toute la suite. La factory renseigne désormais les deux colonnes.
- `DemoSeeder` crée en local un compte administrateur de démonstration (`admin.demo@soutrali.test`, mot de passe `password`) pour ouvrir `/admin`. Les assets Filament publiés (`public/css|js|fonts/filament`, 41 fichiers) sont versionnés : `/admin` fonctionne sans commande supplémentaire ; `php artisan filament:assets` les régénère.
- **Vérifications exécutées, avec PHP 8.3** : `php artisan test` → **33 tests passés, 244 assertions**, dont `AdminPanelTest` (9 tests : ouverture du panneau réservée aux modérateurs et administrateurs actifs, refus de l’anonyme et de l’utilisateur ordinaire, traitement d’un signalement qui masque l’annonce et trace la décision, classement sans suite, refus du masquage sur annonce déjà clôturée, rejet motivé, suspension et réactivation tracées avec refus de l’auto-suspension, gestion des comptes réservée aux administrateurs, suppression interdite partout) ; `pint --test` → **PASS sur 106 fichiers** ; `phpstan analyse` (Larastan niveau 5) → **aucune erreur** ; `GET /admin` sur l’API locale répond **302 → `/admin/login`**.

---

## 3. Ce qui est fait et vérifié

### Backend Laravel

- API publique versionnée : `GET /api/v1/listings` (filtres `q`, `commune`, `category`, `type`, `nature`, pagination `page` / `per_page` plafonnée à 24) et `GET /api/v1/listings/{id}`, toutes deux limitées à 60 requêtes/minute.
- Référentiels publics : `GET /api/v1/categories` et `GET /api/v1/communes` (éléments `active` uniquement, 60 requêtes/minute), qui alimentent les filtres de l’écran.
- Authentification par session web Sanctum (D-04 validée) : `POST /api/v1/register`, `/login` (message d’erreur identique si le compte est inconnu), `/logout`, `GET /api/v1/me`, `GET /api/v1/csrf-token` (jeton CSRF en JSON). Mutations exigées en session, cookie de session `soutrali-session` et origine contrôlée.
- Annonces de l’utilisateur : publication immédiate `PUBLIEE`, modification réservée au propriétaire (403 sinon), clôture avec `closure_outcome` (409 si déjà clôturée), liste `GET /api/v1/me/listings`.
- Messagerie interne tracée (D-05 validée) : fils par couple auteur/initiateur autour d’une annonce publiée, premier message au démarrage, accusés de lecture, compteurs de non-lus. Aucune coordonnée privée n’est échangée.
- Signalements (D-06 validée) : motif + détails, statut `NOUVEAU`, refus de signaler sa propre annonce, suivi côté auteur du signalement.
- Back-office Filament sur `/admin` (T-05) : 7 ressources (signalements, annonces, utilisateurs, catégories, communes, interactions, journal de modération), 8 policies enregistrées, panneau en **mode strict** (`strictAuthorization()`), accès réservé aux comptes `MODERATEUR` / `ADMINISTRATEUR` actifs. Toute décision de modération (prise en charge, masquage, republication, rejet, classement sans suite, suspension, réactivation) passe par le service `ReportModerator` et laisse une trace horodatée dans `moderation_actions` — le back-office ne crée ni ne supprime de signalement.
- Les réponses publiques n’exposent **aucune coordonnée privée** : la ressource ne renvoie que titre, description, type, nature, disponibilité, budget (nombre JSON), catégorie, commune, auteur (identifiant + nom affiché) et date. Les ressources `author` ne sont chargées que sur la route détail.
- Migrations des onze tables du modèle conceptuel : `communes`, `users`, `categories`, `listings`, `sessions`, `personal_access_tokens`, `contact_channels`, `user_blocks`, `interactions`, `reports`, `moderation_actions`. Les tables `contact_channels` et `user_blocks` correspondent à la décision T-14.
- Seeders : communes d’Abidjan (D-03) et catégories (D-07) validées le 22 oct. 2026, plus — **en local uniquement** — 3 comptes fictifs de démonstration (dont un administrateur du back-office) et 8 annonces.
- Modèles Eloquent avec relations et index de recherche (`status + commune + date`, `status + category + type + nature`).
- Manifeste Composer Laravel 13 + Sanctum 4 + Filament 5, avec Pest, Pint et Larastan en développement. `composer.lock` versionné.
- Workflow CI `.github/workflows/ci.yml` : Pest, Pint, Larastan côté backend ; `flutter analyze`, `flutter test`, build web release côté application.

### Application Flutter

- Page d’accueil interactive (`discover_page.dart`) : en-tête avec compte connecté (initiales, menu mes annonces / messagerie avec badge de non-lus / déconnexion), actions « Annonce » et « Prestation de service » avec choix immédiat/programmé, formulaire complet relié à l’API, filtres commune/nature/q, cartes cliquables vers le détail, signalement d’une annonce.
- Pages `/login` et `/register` : validation champ par champ, erreurs API 422 affichées champ par champ, ouverture de session immédiate après inscription.
- Détail d’annonce (`listing_detail_page.dart`) : contact de l’auteur par message (renvoi vers la connexion si visiteur, garde-fou « C’est votre annonce »), signalement, lien de retour.
- `mes-annonces` : liste des annonces de l’utilisateur tous statuts, modification, clôture avec issue (récompensé, besoin satisfait, pas de réponse).
- `messagerie` : liste des fils avec non-lus et dernier message, vue de fil avec accusés de lecture et envoi.
- Thème centralisé aux couleurs de la charte v2 (`app/lib/src/theme/soutrali_theme.dart`) : orange `#FE7402`, vert `#037C30`, ivoire `#FFF9F2`. Aucune couleur écrite dans les écrans.
- Configuration française fonctionnelle (délégués Material/Cupertino).
- Filtres « Commune » et « Catégorie » alimentés par l’API de référentiels (le filtre commune n’est plus codé en dur), avec état dégradé propre si l’API est absente.
- Quatorze tests : modèle d’annonce et filtres, référentiels et transmission des filtres, pages d’authentification (validation e-mail/mot de passe, liens croisés), actions de publication (visiteur invité à se connecter).

### Vérifications exécutées

- `pest` / `php artisan test` : **33 tests passés, 244 assertions** le 23 oct. (PHP 8.3, SQLite en mémoire ; 7 tests au niveau T1, 17 tests d’authentification / annonces / conversations / signalements, 9 tests d’accès et de modération du back-office).
- `pint --test` : PASS sur 106 fichiers (23 oct.).
- `phpstan analyse` avec Larastan niveau 5 : aucune erreur (23 oct.).
- `flutter analyze` : **No issues found** (revérifié le 23 oct.).
- `flutter test` : **14 tests passés** (revérifié le 23 oct.).
- `flutter build web --release` : compilation réussie (183,6 s) ; `main.dart.js` 3 294 322 o brut / 942 397 o gzip ; police d’icônes Material réduite de 1 645 184 à 9 996 octets.
- Parcours navigateur → API → MariaDB observé avec données le 22 oct. : requêtes `listings`, `communes`, `categories` et filtres en HTTP 200, annonce rendue à l’écran (voir §2, étape T1).
- Parcours complet observé dans le navigateur le 23 oct. : inscription, session, publication, détail avec garde-fou auteur, rendu de l’annonce publiée dans le fil ; puis 12 scénarios API à deux comptes (contact, lecture, réponse, non-lus, signalement, refus de signaler sa propre annonce, clôture, 403/404/409 attendus).
- `php artisan migrate` : **17 tables** créées (11 tables du modèle conceptuel + 6 tables d’infrastructure Laravel).
- `GET /api/v1/listings` : **HTTP 200** avec une liste paginée vide — résultat normal tant que le seeder est vide.
- Rendu navigateur contrôlé sur ordinateur et à 390 px : aucun débordement horizontal.
- Contrôle des règles Git d’ignore et scan de secrets : conformes (voir §2, 22 oct.).
- Ces vérifications sont exécutées sur le poste de développement. Leur passage dans la CI GitHub est suivi au §2.

---

## 4. Ce qui bloque, et pourquoi

**Résolus** : la base `soutrali` est migrée (17 tables) et le compte SQL dédié `soutrali_dev` existe avec des droits limités ; `GET /api/v1/listings` répond 200 (T0). Les référentiels sont en base et exposés par l’API (T1). Les décisions D-04, D-05 et D-06 sont validées et les parcours compte / publication / contact / signalement / clôture sont implémentés et vérifiés (22–23 oct.). La modération des signalements a désormais une interface : le back-office `/admin` traite et trace chaque décision depuis le 23 oct. 2026 (9 tests Pest dédiés).

| Blocage | Cause vérifiée | Conséquence |
|---|---|---|
| Le tir d’essai T1b est incomplet sur ses volets mesure | Le parcours navigateur → API → base et la session Sanctum sont observés, mais les mesures téléphone (temps jusqu’au premier écran utile, poids réellement transféré compressé) ne sont pas faites : aucun téléphone instrumenté et le serveur local de test ne compresse pas | Les seuils de réussite ne peuvent pas être présentés à la MOA |
| Pas d’identité visuelle embarquée | Icônes Flutter par défaut, favicon backend vide, polices non embarquées (constat du 22 oct., inchangé) | Le rendu n’est pas à l’identité de la marque |
| Création du premier administrateur en production | Le compte `admin.demo` n’existe qu’en local (`DemoSeeder`, environnement `local`) ; aucun mécanisme de création initial n’est encore arrêté pour la production | Un déploiement ne peut pas encore ouvrir `/admin` sans création manuelle documentée |

---

## 5. Ce qui reste à faire, dans l’ordre

L’ordre suit le plan T0 → T8 de la stack v3. **Ne pas ajouter d’écran avant la fin de T1b.**

1. **T0 — débloquer l’environnement : fait le 22 octobre 2026**
   - Compte SQL dédié créé, droits limités à `soutrali`. **Fait.**
   - Migrations exécutées, 17 tables vérifiées. **Fait.**
   - `GET /api/v1/listings` répond 200. **Fait.**
   - Composer retrouvé et chemin exact documenté dans `INSTALLATION.md`. **Fait.**
2. **T1 — données de référence : fait le 22 octobre 2026**
   - Seeder chargé : 14 lignes de communes (D-03 validée), 8 catégories (D-07 validées) +, en local, 2 comptes et 8 annonces fictifs. **Fait.**
   - Routes `GET /api/v1/categories` et `GET /api/v1/communes` écrites et vérifiées par HTTP réel. **Fait.**
   - Filtres Flutter commune et catégorie alimentés par l’API. **Fait.**
   - Hors T1, toujours ouvert : les routes de publication et d’authentification n’existent pas (D-04).
3. **T1b — tir d’essai : en cours**
   - Faire répondre l’API à l’écran Flutter Web avec des données de la base. **Fait le 22 oct. 2026** (requêtes 200 observées, annonce rendue à l’écran).
   - Valider la session Sanctum de bout en bout : connexion, requête mutante avec CSRF, déconnexion, en développement puis sur build servi par la même origine. **Fait le 23 oct. 2026** (inscription, connexion, publication, contact, signalement, clôture observés dans le navigateur et rejoués par API à deux comptes).
   - Mesurer le poids compressé et le temps jusqu’au premier écran utile sur un téléphone Android courant en réseau limité. **Seuils à fixer avec la MOA ; aucun chiffre inventé.** À faire.
   - Si la mesure échoue durablement : évaluer `--wasm`, chargement différé, assets réduits, puis rouvrir T-01 pour le web seul.
4. **T2 — comptes et administration** : comptes, authentification et profil minimal **faits** (22 oct.). Rôles, back-office `/admin`, catégories et communes, traitement des signalements par un modérateur : **faits le 23 octobre 2026**. Reste : définir la procédure de création du premier compte administrateur en production (le compte de démonstration n’existe qu’en local).
5. **T3 — annonces** : création, recherche filtrée, détail, modification, clôture avec issue : **faits** (22–23 oct.). Reste à tester sur téléphone et à durcir (contrats API dans la CI).
6. **T4 — confiance et contact** : messagerie interne tracée et signalements **faits** (22 oct.), modération traçable **faite le 23 oct. 2026** (back-office + journal `moderation_actions`). Reste : blocages d’utilisateurs (`user_blocks`, T-14).
7. **Identité visuelle** : produire les icônes et déclinaisons du logo aux couleurs de la marque, remplacer les icônes Flutter par défaut et régénérer le favicon vide du backend ; embarquer Manrope et Source Sans 3 après vérification de licence.
8. **Tests** : les permissions du back-office sont couvertes depuis le 23 oct. (9 tests d’accès et de modération). Reste : tests Pest du contrat API, des migrations et de la visibilité des canaux de contact.

---

## 6. Décisions techniques applicables

Extrait de la stack v3.1 validée le 20 octobre 2026. Liste complète dans `docs/Soutrali_Stack_Technique_v3.docx`.

| ID | Décision |
|---|---|
| T-01 | Flutter/Dart, même code source pour le web puis Android ; **web livré en premier** |
| T-02 | Base MySQL ; en local via XAMPP (MariaDB en pratique), administrée avec phpMyAdmin |
| T-04 | Backend Laravel 13 en monolithe modulaire, API REST versionnée `/api/v1` |
| T-05 | Back-office Filament sur `/admin` |
| T-06 | Authentification Laravel Sanctum : session web sécurisée, jeton révocable pour Android |
| T-07 | PHP 8.3 ou plus installé séparément de XAMPP |
| T-08 | Versions figées dans `composer.lock` et `pubspec.lock` |
| T-09 | Build web Flutter : mesure obligatoire de poids et de rapidité avant d’engager les écrans |
| T-10 | Gestion d’état Flutter : Riverpod, une seule approche |
| T-11 | Tests backend : Pest, un seul framework |
| T-12 | Intégration continue sur GitHub Actions |
| T-14 | Tables `contact_channels` et `user_blocks` au MVP |

---

## 7. FAQ — priorité web

### Pourquoi le site web avant l’application Android ?

La décision T-01 fixe la livraison du web en premier. Cela valide l’usage, les formulaires, la recherche, les règles de confidentialité et l’administration avant la distribution mobile. Le code Flutter est partagé ; Android reste hors de la première livraison tant que les parcours web et le backend ne sont pas validés.

### Le site peut-il fonctionner sans le backend Laravel ?

Le shell visuel peut s’afficher, mais la recherche appelle `GET /api/v1/listings`. Sans backend et base démarrés, il n’y a pas de données partagées : l’interface présente un état d’indisponibilité et **ne fabrique pas d’annonces fictives**.

### Que reste-t-il à valider avant de développer toutes les pages web ?

Terminer T1b (voir §5). Les seuils de réussite doivent être décidés avec la MOA. Ensuite seulement : comptes, détail, publication, gestion des annonces, contact, signalement et Filament.

### Android est-il abandonné ?

Non. Flutter reste le code source partagé. Android vient après le MVP web validé et réutilisera modèles, appels API et une grande partie de l’interface.

### Pourquoi deux ports, 8000 et 8082 ?

Un serveur sert l’API, l’autre les fichiers Flutter. Le navigateur les traite comme des origines distinctes : Sanctum, cookies CSRF et CORS doivent autoriser explicitement le client `127.0.0.1:8082`. En production, l’architecture recommandée sert le web, l’API et `/admin` sous une seule origine HTTPS.

---

## 8. Comment tenir ce document à jour

À la fin de **chaque séance de développement**, ajouter :

1. une entrée datée dans le §2, décrivant les faits observés (commandes exécutées, résultats, mesures) ;
2. la mise à jour du §1 si un constat a changé ;
3. la mise à jour des §3, §4 et §5 selon ce qui est fait, bloqué ou restant ;
4. une ligne correspondante dans le journal §25 du README de cadrage.

Interdictions : annoncer une mesure non faite, un test non exécuté, un déploiement non réalisé ; proposer un seuil ou un chiffre non validé par la MOA ; présenter une recommandation comme une décision.
