# Soutrali — Suivi de développement

> **Objet :** journal technique étape par étape du socle Soutrali. Il répond à une seule question : *où en est réellement l’implémentation, qu’est-ce qui a été vérifié, qu’est-ce qui bloque, et que reste-t-il à faire ?*
>
> **Ce document n’est pas le cadrage fonctionnel.** Le cadrage (besoins, règles métier, périmètre MVP, décisions D-xx) vit dans [`README.md`](../README.md). L’architecture de référence vit dans [`README_TECHNIQUE.md`](README_TECHNIQUE.md). La procédure de démarrage vit dans [`INSTALLATION.md`](INSTALLATION.md).
>
> **Règle d’or :** chaque entrée décrit un fait observé, jamais une intention. Si une mesure n’a pas été faite, elle est écrite « non mesurée ». Si un seuil n’est pas fixé par la MOA, aucun chiffre n’est proposé.
>
> **Version :** 1.6 · **Dernière mise à jour :** 29 octobre 2026

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

Constats relevés le **24 octobre 2026** sur le poste de développement, par exécution réelle des commandes (les constats antérieurs du 23 oct. sont conservés dans le journal §2).

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
| Icônes web | **Icônes de marque** (24 oct. 2026) : `app/web/favicon.png` et `app/web/icons/*` (192, 512, maskable 192/512) régénérés depuis le logo source par `brand/generate-icons.php` (variante « symbole seul » sur fond ivoire) |
| `backend/public/favicon.ico` | **Généré le 24 oct. 2026** : ICO multi-tailles (32 + 16 px) + `favicon.png`, aux couleurs de la marque |
| Polices | **Embarquées depuis le 24 oct. 2026** : Manrope (164 700 o) et Source Sans 3 (646 340 o) en TTF variable dans `app/assets/fonts/`, licences SIL OFL 1.1 jointes (`OFL-Manrope.txt`, `OFL-SourceSans3.txt`), familles déclarées dans `pubspec.yaml` (sections `assets:` et `fonts:`) et chargées par le moteur Flutter (présentes dans `FontManifest.json` du build) |
| Serveurs de développement | À la reprise du 23 oct. : MariaDB relancée (`mysqld.exe` XAMPP, port 3306), API Laravel sur `127.0.0.1:8000` (`php artisan serve`) répondant HTTP 200, build web release servi sur `127.0.0.1:8082` (Python http.server). PHP 8.3 (WinGet) : extensions `pdo_sqlite` et `sqlite3` activées dans `php.ini` (sauvegarde `.bak-soutrali` créée) pour permettre `php artisan test` en local |
| Fonctionnalités pilotes | **Inscription, connexion, session, publication immédiate et programmée, modification, clôture avec issue, messagerie interne, signalement, blocages d’utilisateurs, canaux de contact du profil : implémentées et vérifiées** (D-04, D-05, D-06 validées le 22 oct. 2026 ; D-05 complétée et T-14 intégrés le 24 oct. 2026) |
| Publication programmée | Colonne `publish_at` (migration du 24 oct. 2026), commande `soutrali:publish-due` planifiée chaque minute dans `routes/console.php` (à exécuter via `schedule:work` en local ou cron en production) |
| Back-office `/admin` | **Opérationnel et testé** (23 oct. 2026) : panneau Filament 5 (7 ressources, 8 policies, mode strict), traitement des signalements tracé dans `moderation_actions`, accès réservé aux comptes `MODERATEUR` / `ADMINISTRATEUR` actifs |
| **Mise en ligne** | **https://soutrali.alwaysdata.net depuis le 28 octobre 2026** (AlwaysData, offre gratuite 1 Go — PHP 8.3, MariaDB 11.8 en SSL, HTTPS wildcard) :6 migrations + seeder appliqués (14 communes, 32 services), API et `/admin` vérifiés par requêtes réelles, premier administrateur créé, cron de publication programmée planifié dans le panneau |
| **Livraisons phase 2** | **28 oct. 2026** : front Flutter servi à la racine du site, paquet desktop Windows tout-en-un (3 zip dans `livrables/`, extraction vérifiée par SHA-256) et APK Android signé (56,3 Mo, `CN=Soutrali`, API en ligne gravée) · **29 oct. 2026** : correctif `/livewire` du back-office en ligne (connexion `/admin` rétablie, §2) |
| Tests | 24 oct. 2026 : `flutter analyze` sans problème ; **14 tests Flutter** verts ; **61 tests Pest** verts (**558 assertions**, SQLite en mémoire : 27 tests dans 5 nouveaux fichiers — contrat API, blocages, canaux de contact, migrations, publication programmée — et 1 test ajouté au back-office) · **relevé du 26 oct. 2026 : `flutter analyze` sans problème, 21 tests Flutter verts, 66 tests Pest verts (688 assertions), pint PASS sur 118 fichiers, Larastan sans erreur** · **relevé du 27 oct. 2026 : `flutter analyze` sans problème, 24 tests Flutter verts (configuration desktop), puis 74 tests Pest verts (722 assertions, dont `CreateAdminCommandTest`), pint PASS sur 125 fichiers, Larastan sans erreur** · **relevé du 29 oct. 2026 : 74 tests Pest (722 assertions), pint PASS (125 fichiers), Larastan sans erreur, `flutter analyze` propre, 25 tests Flutter** |

**Conclusion :** l’étape T1 (référentiels en base, exposés par l’API, consommés par l’écran) est faite et vérifiée ; les étapes pilotes T2/T3/T4 (comptes, annonces, contact, signalement, clôture) sont faites et le parcours complet inscription → publication → contact → signalement → clôture est observé en local ; le reste du MVP prévu (T-14 blocages, canaux de contact F-02/F-06, publication programmée F-04, polices et icônes D-02) est intégré le 24 oct. 2026. **Le tir d’essai T1b n’est plus bloqué** : la session Sanctum est validée de bout en bout et les **mesures locales** (poids du build, premier écran utile sur machine de développement) sont relevées au §2 du 24 oct. ; restent les mesures sur téléphone Android en réseau limité, dont les seuils sont à fixer avec la MOA (aucun chiffre n’est proposé sans leur validation).

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

### 24 octobre 2026 — reste du MVP intégré (T-14, F-02/F-06, F-04, D-02) et mesures locales T1b

- **Blocages d’utilisateurs (T-14), de bout en bout** : table `user_blocks` (déjà présente dans la migration du 20 oct., couple auteur/bloqué unique), nouveau `BlockController` — `GET /api/v1/me/blocks` (liste des comptes bloqués, id : identifiant du compte bloqué, libellé, horodatage), `POST /api/v1/users/{user}/block` et `DELETE /api/v1/users/{user}/block` (idempotents, 403 sur soi-même). Effets : `ConversationController` refuse le démarrage (403) et l’envoi (403) quand l’un des deux a bloqué l’autre ; les canaux de contact d’une annonce sont refusés (403) pour un compte bloqué ; côté Flutter, section « Comptes bloqués » dans l’écran du compte (débloquer), bouton bloquer/débloquer sur le détail d’une annonce, garde-fou affiché à la place du contact. 5 tests Pest (`BlockTest`).
- **Canaux de contact du profil (F-02, F-06 — complétion de D-05, arbitrage du 24 oct.)** : table `contact_channels` (déjà présente depuis le 20 oct.) avec `ContactChannelController` — `GET/POST/DELETE /api/v1/me/channels` (3 types : `EMAIL`, `TELEPHONE`, `WHATSAPP` ; **un seul canal par type** et par compte — création ou mise à jour par `updateOrCreate` ; validation e-mail pour `EMAIL`, expression régulière téléphone sinon ; visibilité propre à chaque canal via `visible_to_members` ; 404 sur le canal d’un autre compte), et `GET /api/v1/listings/{id}/contact-channels` : exposé **aux membres connectés uniquement** (visiteur : 401), **uniquement les canaux que leur propriétaire a marqués visibles**, jamais pour ses propres annonces (403), 403 si bloqué dans les deux sens, 404 si l’annonce n’est pas en ligne. Section « Canaux de contact » dans l’écran du compte ; sur le détail d’une annonce connecté, canaux affichés à côté de l’action messagerie. 6 tests Pest (`ContactChannelTest`).
- **Publication programmée (F-04)** : migration `add_publish_at_to_listings` (colonne `publish_at`, non destructrice), `publishNow` (publication immédiate d’un brouillon programmé) et règle « date de programmation non modifiable après publication » dans `MyListingController` ; commande `soutrali:publish-due` (passe les annonces `BROUILLON` échues en `PUBLIEE`) planifiée chaque minute dans `routes/console.php` — **à exécuter** en local via `php artisan schedule:work` et en production via un cron `schedule:run`, sinon les annonces programmées ne passent pas automatiquement ; le filtre de visibilité publique intègre les annonces échues même sans la commande. Côté Flutter : bouton « Publier maintenant » et encart « Publication programmée » dans « mes annonces » ; champ `publish_at` éditable dans le back-office. 6 tests Pest (`ScheduledPublicationTest`, dont voyage dans le temps pour la bascule automatique).
- **Transmission à l’administrateur (complétion D-06)** : enum `Decision` enrichie du cas `TRANSMIS` (le statut du signalement reste `EN_COURS`) et action « transmettre » dans `ReportModerationActions` — justification obligatoire, objet de la transmission renseigné, trace dans `moderation_actions`. 1 test ajouté à `AdminPanelTest` (« transfers a report to the administrator with its justification »).
- **Migrations et contrats sous test** : `MigrationTest` (17 tables, colonnes `publish_at` et `status` présentes) et `ApiContractTest` (structure JSON des listes publiques, nombre `budget`, absence de champs privés) ajoutés à la suite.
- **Identité visuelle (D-02)** : **polices Manrope et Source Sans 3 embarquées** — TTF variables récupérés depuis le dépôt officiel `google/fonts` (licences SIL OFL 1.1 vérifiées et jointes : `app/assets/fonts/OFL-Manrope.txt`, `OFL-SourceSans3.txt`), **déclarées dans `pubspec.yaml`** (sections `assets:` et `fonts:`, familles « Manrope » et « Source Sans 3 ») — le moteur Flutter les charge au démarrage (présentes dans `FontManifest.json` du build ; 164 700 o + 646 340 o). **Icônes et favicons générés depuis le logo source** par `brand/generate-icons.php` : cadrage automatique du symbole, fond ivoire de charte (`#FFF9F2`), icônes Flutter (favicon 48 px, Icon-192/512 et maskable) dans `app/web/`, favicon du backend `backend/public/favicon.ico` (conteneur PNG, tailles 32 et 16 px) et `favicon.png` (32 px) — remplacement des icônes du squelette Flutter et du favicon vide (0 octet).
- **Mesures T1b locales (non définitives)** — build web release servi sur `127.0.0.1:8082`, API sur `127.0.0.1:8000`, MariaDB locale :
  - **Poids du build** (`flutter build web --release`, postérieure à l’ajout des polices) : `main.dart.js` **3 790 546 o brut / 1 071 108 o gzip** ; `canvaskit/canvaskit.wasm` 7 284 602 o brut / 2 922 578 o gzip (servi par le CDN `gstatic.com` par défaut) ; polices `Manrope.ttf` 164 700 o (68 197 o gzip) et `SourceSans3.ttf` 646 340 o (235 336 o gzip) ; dossier `build/web` complet : **43 Mo** (variants inclus).
  - **Premier écran utile, deux relevés dans Chromium** : premier rendu peint (FCP) à **1 273 ms** (chargement à froid) et **1 009 ms** (rechargement à cache chaud) ; la réponse `GET /api/v1/listings` arrive à ~3,0 s (froid) / ~3,3 s (chaud) et le canvas Flutter est rendu ; console propre (seul le 401 `/me` attendu en visiteur).
  - **Limites de ces mesures** : poste de développement en réseau local, serveur statique Python **sans compression gzip** (le chiffre « gzip » ci-dessus est calculé à la volée, pas mesuré sur le fil), aucun téléphone instrumenté, aucune mesure en réseau contraint. **Ce ne sont pas les mesures de recette T1b** ; les seuils restent à fixer avec la MOA (aucun chiffre n’est proposé comme objectif).
- **Vérifications exécutées, avec PHP 8.3 et Flutter 3.47.7** : `php artisan test` → **61 tests passés, 558 assertions** (33 du 23 oct. + 27 tests dans les 5 nouveaux fichiers — contrat API, blocages, canaux de contact, migrations, publication programmée — + 1 test ajouté au back-office pour la transmission) ; `pint --test` → **PASS sur 115 fichiers** ; `phpstan analyse` (Larastan niveau 5) → **aucune erreur** ; `flutter analyze` → **No issues found** ; `flutter test` → **14 tests passés** ; `flutter build web --release` → **succès**.

### 26 octobre 2026 — règle de travail : toute fonctionnalité accessible, testée, committée

- **Constat** : pendant la séance du 24-25 octobre, des changements sont restés invisibles plusieurs heures alors que le code était correct — la cause n’était pas le code mais deux caches empilés : le port 8082 sert une **compilation statique** (`python -m http.server --directory app/build/web`), et ce serveur n’envoie aucun en-tête `Cache-Control`, donc le navigateur conserve son ancien `main.dart.js` jugé « frais » par heuristique sans jamais revérifier. Par ailleurs, une fonctionnalité n’était parfois atteignable qu’en modifiant le code (route ou point d’entrée manquant).
- **Décision** : dépôt racine **`AGENTS.md`** (v1.0), lu automatiquement par l’agent à chaque ouverture du projet, qui fixe la définition de « fait » :
  1. **Accessible** — route enregistrée (`app/lib/src/app.dart` / `backend/routes/api.php`) **et** point d’entrée visible depuis un écran déjà utilisable ; atteignable en suivant uniquement `docs/INSTALLATION.md` ;
  2. **Testable directement** — test ajouté à la suite existante (`backend/tests/Feature/…` Pest, `app/test/…` Flutter), qui reproduit l’usage réel (appel HTTP authentifié avec assertions de statut **et** de contenu, ou parcours de widgets jusqu’à l’écran) ; aucun second outil de test introduit ;
  3. **Vérifié puis committé** — mêmes commandes que la CI (`composer test && composer format:check && composer analyse`, `flutter analyze && flutter test`), recompilation web release, **Ctrl+F5 obligatoire** après chaque build (serveur statique sans en-têtes de cache), entrée ici même, puis commit à la française et push — dépôt local et distant au même niveau d’information.
- **Modifications** : création de `AGENTS.md` ; `README.md` : ligne `AGENTS.md` ajoutée au tableau §0 « Où est le code et la documentation technique » et au tableau des livrables §23 ; entrée de journal ci-dessus.
- **Vérifications exécutées** : aucun code applicatif modifié — les suites ne sont pas relancées pour cette seule documentation ; `git status` ne montre que ces fichiers, aucun changement tiers en attente, `origin/main` identique à `HEAD` avant commit.

### 26 octobre 2026, suite — référentiel complet des services et icônes de charte

- **Besoin du porteur** : proposer **tous les services possibles** (réparation, cours, aide à domicile, déménagement, …), avec des données de test réalistes et une icône réaliste par service.
- **Référentiel porté de 8 à 32 catégories** (`CategorySeeder`) : les 8 catégories validées (D-07) sont conservées à l’identique — aucun test ni aucune annonce de démonstration existante n’est renommé — et 24 services ajoutés : plomberie, électricité, menuiserie, peinture, maçonnerie, jardinage, garde d’enfants, aide aux aînés, cuisine/traiteur, santé-bien-être, sport, photo-vidéo, événements, mécanique, livraison, comptabilité, droit et démarches, langues, sécurité, animaux, musique-arts, communication-marketing, vente, agriculture.
- **Icône par service** : nouvelle colonne `categories.icon` (migration `2026_10_26_000001_add_icon_to_categories`, valeur par défaut `misc`), clés centralisées dans `Category::ICONS` (32 clés) et exposées par `GET /api/v1/categories` ainsi que par `category.icon` des annonces publiques et de « mes annonces ». Côté Flutter, `category_icons.dart` traduit chaque clé en icône Material (`Icons.plumbing`, `Icons.school`, `Icons.local_shipping`, …) avec repli sur l’icône générique.
- **Affichage** : nouveau bloc **« Tous les services »** sur l’écran Découvrir (pastilles icône + nom, sélection colorée, survol relevé, motif de charte en fond) qui **filtre les annonces au toucher** ; icône ajoutée au menu de catégorie des filtres et des formulaires de publication et de modification, à la ligne de catégorie des cartes de résultats, à la puce de catégorie du détail d’annonce et à la ligne « catégorie · commune » de « mes annonces ». Back-office : liste déroulante d’icônes dans la fiche catégorie et badge d’icône dans le tableau.
- **Données de test réalistes** : `DemoSeeder` passe de 8 à 32 annonces (un aperçu par service) — titres, descriptions, quartiers, disponibilités et budgets en FCFA plausibles pour Abidjan, réparties entre les deux comptes de démonstration ; contenu entièrement fictif, aucun nom ni numéro réel.
- **Contrats de test alignés** : `PublicReferenceTest` (nombre de Yopougon 2 → 4, annonces `BENEVOLE` 3 → 6, structure `icon` vérifiée) et nouveau test « il sert une clé d’icône connue de l’application pour chaque service ». Côté Flutter, `services_test.dart` (bloc « Tous les services » : icônes présentes, un toucher sur un service devient le filtre des résultats), `references_test` et `listing_test` étendus à la clé `icon`.
- **Vérifications exécutées, PHP 8.3 et Flutter 3.47.7** : `php artisan test` → **62 tests passés, 676 assertions** ; `pint --test` → **PASS sur 116 fichiers** ; `phpstan analyse` → **aucune erreur** ; `flutter analyze` → **No issues found** ; `flutter test` → **17 tests passés** ; `flutter build web --release` → **succès** (166,9 s).
- **Accessibilité vérifiée sur l’installation locale** : migration appliquée à la base `soutrali` (32 catégories, 34 annonces, seule « Autres » en `misc`), seeder rejoué ; sur `127.0.0.1:8000`, `GET /api/v1/categories` répond **200** avec les 32 services et leur `icon` ; sur le build servi par `127.0.0.1:8082`, le bundle livré est celui du 26 oct. et la page appelle bien `/api/v1/categories` (200) — console propre, seul le 401 `/me` attendu en visiteur. **Ctrl+F5 sur l’onglet ouvert** pour voir le nouveau bundle.

---

### 26 octobre 2026, suite 2 — journaux d’accès et d’erreurs, bouton « Espace admin »

- **Besoin du porteur** : savoir comment accéder au tableau de bord, tracer les accès et les erreurs, et donner aux comptes d’équipe un bouton **« Espace admin »** dans l’application pour ouvrir la console `/admin`.
- **Journal d’accès** : middleware `App\Http\Middleware\LogAccess`, enregistré en **middleware global** dans `bootstrap/app.php`. Chaque requête de l’API (`/api/*`) et du back-office (`/admin*`) est écrite dans le canal `access` → `storage/logs/access.log` au format `GET /api/v1/listings 200 user=3 ip=127.0.0.1 12ms`. Le positionnement global n’est pas un choix décoratif : placé dans un groupe, il était exécuté **après** `auth:sanctum` (le routeur trie les middleware par priorité, constaté puis corrigé), ce qui court-circuitait la journalisation des 401. Les pages publiques et les assets (chemin se terminant par une extension) ne sont pas journalisés ; une exception levée pendant la requête est journalisée avec le statut qu’elle produira, puis relancée.
- **Journal d’erreurs** : canal `errors` ajouté au `stack` par défaut (`config/logging.php`) → `storage/logs/error.log` reçoit tout ce qui est de niveau `error` et au-dessus (exceptions, échecs 500), en plus du `laravel.log` complet. Les deux canaux sont quotidiens avec **30 jours de rétention** (`max_files: 30`).
- **Bouton « Espace admin »** : `canAccessAdminPanel()` (dans `auth_repository.dart`) reprend la règle de `User::canAccessPanel()` — `ADMINISTRATEUR` ou `MODERATEUR`. L’entrée apparaît (1) dans le menu du compte de l’écran Découvrir et (2) comme bouton plein dans la fenêtre « Mon profil » ; elle ouvre `<API_BASE_URL>/admin` dans un nouvel onglet via `url_launcher` (constante publique `apiBaseUrl` exposée par `listings_repository.dart`), avec message en cas d’échec d’ouverture. Un `UTILISATEUR` ni un invité ne voient rien ; le back-office revérifie de son côté (statut `ACTIF` compris).
- **Tests** : backend `AccessLogTest` (4 tests — requête API tracée, utilisateur connecté et statut 401 tracés, pages hors journal, exception dirigée vers `error.log`) avec des fichiers **isolés** `storage/logs/testing-*.log` : la suite ne lit ni ne remplit les journaux réels. Flutter `admin_entry_test.dart` (4 tests — règle de rôle, entrée visible pour l’administrateur, absente pour un membre, bouton dans la fenêtre « Mon profil »).
- **Vérifications exécutées, PHP 8.3 et Flutter 3.47.7** : `php artisan test` → **66 tests passés, 688 assertions** ; `pint --test` → **PASS sur 118 fichiers** ; `phpstan analyse` → **aucune erreur** ; `flutter analyze` → **No issues found** ; `flutter test` → **21 tests passés** ; `flutter build web --release` → **succès**.
- **Vérification en local** : avec l’API sur `127.0.0.1:8000`, trois `curl` relus dans `storage/logs/access.log` : `GET /api/v1/listings 200 user=-`, `GET /api/v1/me 401 user=-`, `GET /admin 302 user=-` (chacun avec IP et durée).

---

### 26 octobre 2026, suite 3 — phase 2 ouverte (`labo-soutrali-v2`) : e-mails transactionnels F-09

- **Besoin du porteur** : phase 2 = application **desktop + Android tout-en-un, sans rien installer** sur les postes (d’abord en local, ensuite en ligne), et **e-mails réellement reçus en boîte mail** via des hébergements gratuits. Trois décisions prises avec lui avant de coder : (1) ordre **e-mails → desktop → mise en ligne → Android**, (2) fournisseur **Mailjet**, (3) hébergement **gratuit uniquement**.
- **Comparatif des offres gratuites (recherche web du 26 oct. 2026)** : Mailjet 6 000/mois et 200/jour, SMTP, **expéditeur vérifiable par lien sans domaine acheté** → retenu ; Brevo 300/jour (activation transactionnelle par le support, domaine conseillé) ; Resend 3 000/mois et Mailgun 100/jour **exigent un domaine vérifié** ; SendGrid 100/jour seulement 60 jours (essai) ; AWS SES en sandbox (récipiendaires vérifiés) ; Cloudflare 3 000 sortants/mois mais payant au-delà. Détails et URL des sources : réponse de recherche de la séance.
- **Branche** : `labo-soutrali-v2` créée depuis `main` (Git interdit les espaces dans un nom de branche).
- **Implémentation F-09** : classe `App\Support\Mail\Outbox` — envoi synchrone, **toute panne de transport est capturée et journalisée en `Log::error` (→ `storage/logs/error.log`) sans faire échouer la requête** ; helper `frontendUrl()` lit `config('app.frontend_url')`. Trois Mailables avec enveloppe + contenu : `WelcomeMail`, `ListingPublishedMail`, `NewMessageMail`, et quatre gabarits Blade dans `resources/views/emails/` au gabarit **table** recommandé pour les clients mail, aux couleurs de charte (entête vert profond `#0B5A2A`, boutons orange `#FE7402` / vert `#037C30`, fond ivoire `#FFF9F2`, texte `#1F2A24`).
- **Déclencheurs** : `AuthController::register` (bienvenue) ; `MyListingController::store` quand le statut est `PUBLIEE` + `publishNow` (mise en ligne manuelle) ; commande `soutrali:publish-due` (**passée d’un `update` en masse à une boucle** avec chargement de l’auteur, pour que chaque annonce publiée déclenche son e-mail) ; `ConversationController::start` (à l’auteur de l’annonce) et `sendMessage` (à l’autre participant, **jamais à soi-même**, extrait du corps tronqué à 300 caractères).
- **Configuration** : `FRONTEND_URL` exposée comme `config('app.frontend_url')` (liens cliquables des e-mails) ; bloc `MAIL_*` complet ajouté à `.env.example` (mode local `log`, valeurs Mailjet commentées). `phpunit.xml` utilisait déjà `MAIL_MAILER=array` : les tests n’ouvrent aucun réseau.
- **Tests** : nouveau `backend/tests/Feature/EmailNotificationTest.php` — 5 tests / 20 assertions : bienvenue à l’inscription (destinataire + sujet), publication immédiate envoyée, programmée **non** envoyée puis envoyée à la mise en ligne manuelle, commande programmée qui notifie l’auteur, messages dans les deux sens (auteur puis expéditeur), et **inscription maintenue quand le transport lève une exception** (`Mail::shouldReceive('to')->andThrow(...)`). Écueil rencontré et corrigé : sans en-tête `Origin`, Sanctum ne démarre pas la session d’un domaine « stateful » → `Session store not set on request` ; le test reproduit désormais l’en-tête d’origine comme `AuthTest`.
- **Vérifications exécutées, PHP 8.3** : `php artisan test` → **71 tests passés, 708 assertions** ; `pint --test` → **PASS sur 123 fichiers** ; `phpstan analyse` → aucune erreur. Flutter inchangé (aucune modification côté app pour ce jalon).
- **Envoi réel vérifié le soir du 26 octobre 2026** : le porteur a créé son compte Mailjet et renseigné ses clés dans `backend/.env` (**fichier non versionné, jamais committé**), expéditeur `support@soutrali.com`. Deux envois réels acceptés en SMTP vers sa boîte Gmail : un message de test, puis un **e-mail de bienvenue déclenché par une vraie inscription `POST /api/v1/register`** (utilisateur de test créé puis supprimé, serveur de test éphémère sur le port 8001). Leçon immédiate : `MAIL_SCHEME=tls` fait lever `UnsupportedSchemeException` (seuls `smtp` et `smtps` sont des schéma valides) — sur le port 587, le champ reste vide et STARTTLS est automatique. Corrigé dans `.env.example` et `INSTALLATION.md` (+ ligne au tableau §7) ; le test de panne volontaire est désormais isolé sur `storage/logs/testing-error.log` pour ne pas salir le vrai `error.log`.
- **Reste** : confirmation de la **réception** en boîte (spams compris) par le porteur ; puis jalon desktop tout-en-un (PHP portable + SQLite + zip), hébergement gratuit, APK Android.

### 27 octobre 2026 — phase 2 desktop : paquet tout-en-un assemblé, backend embarqué vérifié

- **Plateforme Windows de l’application** : `flutter create --platforms=windows` a généré `app/windows/` (runner + CMake). La compilation `flutter build windows --release --dart-define=API_BASE_URL=http://127.0.0.1:8123` s’arrête sur « Unable to find suitable Visual Studio toolchain » : **Visual Studio n’est pas installé sur ce poste** (voir §4). En attendant, `desktop\build-package.ps1 -SkipFlutter` assemble déjà tout le reste du paquet.
- **Runtime PHP portable** : PHP 8.3.36 x64 téléchargé et configuré (`desktop/runtime/php/` + `desktop/runtime/php.ini` : extensions `pdo_sqlite`, `sqlite3`, `openssl`, `mbstring`, `curl`, `fileinfo`, `sodium`, `zip`), copié dans le paquet. Aucune installation sur la cible.
- **Script `desktop/build-package.ps1`** : télécharge PHP si absent, compile l’application, assemble `dist/Soutrali-win64/` (backend Laravel complet sans les journaux + runtime PHP), écrit le `.env` du paquet (SQLite, port 8123, `SANCTUM_STATEFUL_DOMAINS=127.0.0.1:8123`, `MAIL_MAILER=log`), `key:generate` + `migrate --force` + `db:seed --force`, puis archive en `dist/Soutrali-win64.zip` (tar natif Windows).
- **Vérifié par HTTP réel le 27 octobre 2026 avec le PHP embarqué seul** (`artisan serve` sur `127.0.0.1:8123`, base SQLite du paquet, aucune installation) : `GET /api/v1/categories` → **200** (32 services issus du seeder) ; `GET /api/v1/csrf-token` → **200** avec en-tête `Origin` ; `POST /register` → **201** ; `POST /login` → **200** ; `GET /me` → **200** ; `GET /me/listings` → **200**. Le parcours inscription → connexion → session authentifiée fonctionne sur le paquet.
- **Correctif des tests Flutter (blocage de toute la suite)** : `configurePlatformDio` installait un `PersistCookieJar` **à fichier**, dont les lectures disque ne se terminent jamais dans la zone FakeAsync de `flutter test` — les requêtes restaient en chargement éternel et `pumpAndSettle` expirait sur chaque test applicatif. Désormais, sous le drapeau `FLUTTER_TEST`, la configuration utilise un `DefaultCookieJar` **en mémoire** (le client factice de `flutter test` ne renvoie de toute façon aucun `Set-Cookie` réel) ; en production, le jar fichier reste celui qui conserve la session entre deux lancements. L’en-tête `Origin` est conservé — vérifié inoffensif sous le client factice (la requête y répond en 400 comme sans lui).
- **Piège de compilation relevé** : `bool.fromEnvironment(...)` **sans `const`** évalue à `false` et ignore silencieusement le `--dart-define` ; toute bissection fondée sur un tel drapeau est invalide. Seul `const bool.fromEnvironment(...)` lit la valeur.
- Relevé : `flutter analyze` → **No issues found** ; `flutter test` → **24 tests passés** (dont `app_runtime_test`, qui exige toujours `Origin` + `CookieManager`).

### 27 octobre 2026, suite — commande `soutrali:create-admin` : le premier administrateur devient créable en production

- **Besoin** : sur un déploiement vierge, `/admin` était inaccessible — le compte `admin.demo` n’existe qu’en local (`DemoSeeder`, environnement `local`) et aucun mécanisme de création initial n’existait (blocage §4).
- **Nouvelle commande artisan** `backend/app/Console/Commands/CreateAdmin.php` : `php artisan soutrali:create-admin <email> [--name=…] [--password=…]` — crée le compte en `ADMINISTRATEUR` / `ACTIF`, ou **promeut** un compte existant en conservant son nom affiché, valide l’adresse e-mail et refuse un mot de passe de moins de 8 caractères. Si `--password` est omis, le mot de passe est saisi en clair-masqué (`secret()`) : recommandé sur hébergement partagé, l’argument en clair restant dans l’historique SSH.
- **Deux défauts trouvés par les tests puis corrigés** : (1) une apostrophe française dans la chaîne du `$signature` (`l'e-mail`) clôturait prématurément le littéral et produisait une erreur de syntaxe PHP — la commande n’était même pas enregistrée (`CommandNotFoundException`) ; (2) les tests passaient `password` en argument positionnel alors que c’est l’option `--password`.
- **Test intégré à la suite existante** : `backend/tests/Feature/CreateAdminCommandTest.php` (3 tests / 14 assertions — création sur déploiement vierge avec vérification du hachage, promotion d’un compte existant sans doublon, refus d’une adresse invalide ou d’un mot de passe court).
- **Vérifications exécutées, PHP 8.3** : `php artisan list --raw` affiche `soutrali:create-admin` aux côtés de `soutrali:publish-due` ; `php artisan test` → **74 tests passés, 722 assertions** ; `pint --test` → **PASS sur 125 fichiers** ; `phpstan analyse` → aucune erreur. Flutter inchangé (`flutter analyze` sans problème, 24 tests).
- **Usage en production documenté** : sur l’hébergement, `php artisan soutrali:create-admin admin@domaine.tld` puis ouverture de `/admin` depuis le bouton « Espace admin » de l’application.

### 28 octobre 2026 — mise en ligne du backend (AlwaysData) et paquet desktop finalisé

- **Paquet desktop finalisé (constat sur disque, 27 oct. au soir)** : Visual Studio Build Tools installés sur le poste, `flutter build windows --release` compile avec succès, et `desktop/build-package.ps1` produit `dist/Soutrali-win64/` complet — `soutrali.exe` (91 136 o), runtime PHP portable (`runtime/php/php.exe`), `backend/` avec `artisan` et la base SQLite pré-migrée — archivé en **`dist/Soutrali-win64.zip` (112 452 771 o)**. **Test d’acceptation** : double-clic sur `soutrali.exe` comme un utilisateur final sur poste sans rien d’installé → API locale en HTTP 200 au bout de 4 s. Le blocage « exécutable Windows » du §4 est levé.
- **Hébergement retenu : AlwaysData** (offre gratuite : 1 Go de disque partagé, MariaDB, HTTPS wildcard `*.alwaysdata.net` inclus, SSH/SFTP, cron, sans carte bancaire) — seul candidat satisfaisant toutes les contraintes techniques du plan (PHP 8.3+, MariaDB, cron à la minute, HTTPS).
- **Déploiement par SSH (28 octobre 2026)**, compte `soutrali` :
  - Site `soutrali.alwaysdata.net` (PHP 8.3), racine `www/soutrali` → lien symbolique vers `/home/soutrali/soutrali/backend/public` (le code reste hors racine web : `.env` inaccessible depuis HTTP) ; code cloné depuis GitHub, branche `labo-soutrali-v2` ; `composer install --no-dev --optimize-autoloader` (vendor 100 Mo).
  - `.env` de production : `APP_ENV=production`, `APP_DEBUG=false`, `APP_URL` et `FRONTEND_URL` sur le domaine HTTPS, `SESSION_DOMAIN` + `SANCTUM_STATEFUL_DOMAINS=soutrali.alwaysdata.net`, clés Mailjet transférées **sans jamais transiter par la conversation**, `MYSQL_ATTR_SSL_CA=/etc/ssl/certs/ca-certificates.crt`.
  - **Contrainte SSL de la base (piège résolu sans code)** : l’utilisateur MySQL `soutrali` du panneau a « Connexion SSL requise » — le client `mysql` chiffre par défaut (TLS_AES_256_GCM_SHA384) mais **PDO non**, d’où `Access denied … (using password: YES)` alors que les identifiants étaient justes (vérifié en croisant `mysql` CLI et `php -r`). Correctif : la variable `MYSQL_ATTR_SSL_CA` déjà lue par `config/database.php` → PDO chiffre **et vérifie le certificat** avec le magasin système. Aucune ligne de code modifiée.
  - Migrations : **6 migrations** appliquées sur `soutrali_bd` (MariaDB 11.8.9), seeder des référentiels (**14 communes, 32 services**), `php artisan optimize` (cache config/routes/vues).
  - `crontab` refusé depuis le SSH (« not allowed to use this program ») : la publication programmée passe par une **tâche planifiée du panneau** (toutes les minutes : `cd /home/soutrali/soutrali/backend && php artisan schedule:run`).
- **Vérification par requêtes réelles depuis l’extérieur (28 octobre 2026)** : `/up` → **200** ; `/api/v1/categories` → **200** (32 services avec icônes) ; `/api/v1/communes` → **200** (14) ; `/api/v1/listings` → **200** (`total: 0`, base vierge propre) ; `GET /api/v1/csrf-token` → **200** avec cookie `XSRF` ; `POST /api/v1/register` → **201** ; `GET /api/v1/me` → **200** ; `GET /admin` → **302** vers `/admin/login` → **200** ; `POST /api/v1/login` → **200** puis `/me` → **200** avec rôle `ADMINISTRATEUR` ; HTTPS forcé (HTTP → 301) ; les 9 requêtes relues dans `storage/logs/access.log` production (statut, utilisateur, IP publique, durée).
- **Premier administrateur de production** : `php artisan soutrali:create-admin inbox.pro.perso@gmail.com` a promu le compte de vérification en `ADMINISTRATEUR` / `ACTIF` (renommé « Administrateur Soutrali ») ; connexion API vérifiée avec ce compte — le blocage §4 « création du premier administrateur » est levé aussi en réel.
- **E-mails F-09 en production — diagnostic d’un non-reçu** : le transport SMTP **acceptait** les messages (test réel capturé : `SMTP_ACCEPTED`) alors que le porteur **ne recevait rien**. Cause vérifiée : l’expéditeur `support@soutrali.com` porte sur un domaine `soutrali.com` **« En attente »** de vérification dans le compte Mailjet, seul `my.fat.inc@gmail.com` est **« Actif »** — Mailjet accepte en SMTP puis ne distribue pas. Correctif : `MAIL_FROM_ADDRESS` basculé sur l’expéditeur vérifié, test réenvoyé. **Reste** : confirmation de la réception en boîte (spams compris) par le porteur, puis vérification du domaine `soutrali.com` dans Mailjet (enregistrements DNS) pour retrouver un expéditeur de marque `support@soutrali.com`.

### 28 octobre 2026, suite — chaîne Android installée et APK signé compilé

- **Blocage levé — chemin du SDK avec espace** : le SDK Flutter se trouvait dans `C:\Users\Abd Al Fattah\flutter` ; le hook `objective_c` (déclenché par `path_provider_foundation`) fait échouer toute compilation sous Windows dès qu’un chemin de l’environnement contient une espace non échappée — cela cassait `flutter build` **et** `flutter test`. SDK déplacé vers `C:\soutrali-android\flutter`, PATH utilisateur mis à jour et junction conservée à l’ancien emplacement pour la compatibilité : `flutter doctor` redevient **entièrement vert**, y compris l’outil Android.
- **Outils Android installés** sous `C:\soutrali-android\` : JDK 17.0.20.1, Android SDK — platform 35, build-tools 36.x, NDK r28c et CMake 3.22.1 téléchargés et licences acceptées lors du premier build (27 min).
- **Hôte Android ajouté au dépôt** : `app/android/` (projet généré ; son `.gitignore` suit le template Flutter : `local.properties`, `gradlew`, keystores ignorés), `path_provider` ajouté à `pubspec.yaml` (stockage des cookies hors web), icônes de lancement générées dans les cinq densités `mipmap-*` par `brand/generate-icons.php` (script étendu aux cibles Android).
- **Signature de release hors dépôt** : keystore `~/.android/soutrali-release.keystore` (certificat `CN=Soutrali`) et `~/.android/soutrali-keystore.properties` — le `.gitignore` racine ignore désormais `keystore.properties` et `*.jks`. Échec corrigé au second build : `storeFile` contenait un chemin MSYS (`/c/Users/…`) que Gradle résolvait relativement au projet (« Keystore file … not found for signing config release ») ; remplacé par `C:/Users/…`.
- **APK construit et vérifié** : `flutter build apk --release --dart-define=API_BASE_URL=https://soutrali.alwaysdata.net` → `app/build/app/outputs/flutter-apk/app-release.apk`, **56,3 Mo**, code de sortie 0. Vérifications : chaîne `https://soutrali.alwaysdata.net` (dont `/admin`) retrouvée dans `lib/arm64-v8a/libapp.so` — l’URL de l’API est bien gravée ; `apksigner verify --print-certs` → signature **v2/v3 valide, signataire `CN=Soutrali`**.
- **Vérifications de code** : `flutter analyze` sans erreur, `flutter test` → **25 tests verts**, `php -l brand/generate-icons.php` → aucune erreur de syntaxe.
- **Reste (Android)** : installer l’APK sur un téléphone et y parcourir inscription, recherche, publication, session conservée ; mesures T1b sur téléphone en réseau limité (seuils à fixer avec la MOA) ; suivre `versionCode`/`versionName` pour les mises à jour signées avec la même clé.

### 28 octobre 2026, suite 2 — le site en ligne sert l’application, livrables de test, expéditeur e-mail en attente de DNS

- **`https://soutrali.alwaysdata.net/` sert désormais l’application Flutter** (auparavant : page d’accueil Laravel 13). Cause : la racine du site (`www/soutrali`) est un lien vers `backend/public`. Correctif versionné dans `backend/public/.htaccess` : `DirectoryIndex index.html index.php` fait servir `index.html` à la racine, et un repli vers `index.html` couvre les liens profonds — **sauf** `/api` et `/admin`, restés Laravel. Front web compilé avec `API_BASE_URL=https://soutrali.alwaysdata.net` et téléversé dans `backend/public` (tunnel tar/SSH) ; procédure ajoutée à `INSTALLATION.md` §9.4.
- **Vérifications depuis l’extérieur** : `/` → `<title>Soutrali — L’entraide à porter de main</title>` ; `/api/v1/listings` → 200 JSON ; `/api/v1/categories` → 200 ; `/admin` → 302 → `/admin/login` → 200 ; lien profond `/connexion` → 200 (shell Flutter) ; `main.dart.js` → 200 avec l’URL AlwaysData gravée (3 occurrences). **Contrôle navigateur** : canvas chargé, application rendue (`docs/apercu-site-en-ligne-28-oct.png`), appels `/api/v1/me` → 401 (déconnecté, normal), `/categories`, `/communes`, `/listings` → 200 sur la même origine.
- **Répertoire `livrables/` committé** pour que le porteur teste sans rien installer : les 3 zip du paquet desktop (`backend` 61,9 Mo · `runtime` 35,3 Mo · `programme + data` 13,4 Mo — découpés sous la limite de 100 Mo par fichier de GitHub) + `soutrali-android.apk` (59,0 Mo). Assemblés par `build-livrables.php` ; **test réel** : extraction des 3 zip dans un dossier vide → 18 577 fichiers comme `dist/Soutrali-win64/`, empreintes SHA-256 identiques sur `soutrali.exe`, `artisan`, `php.exe` et `data/app.so`. Notice de test dans `livrables/README.md`.
- **E-mails F-09 — diagnostic de l’expéditeur affiché (`bnc3.mailjet.com`)** : le `.env` de production porte `MAIL_FROM_ADDRESS="my.fat.inc@gmail.com"` (constaté en SSH le 28 oct.) ; ni Gmail, ni `soutrali.com` (toujours « En attente » dans Mailjet) ne sont authentifiés, Mailjet envoie donc depuis sa propre infrastructure et les clients de messagerie affichent `bnc3.mailjet.com`. **État DNS relevé** : NS et MX IONOS (`mx00/01.ionos.fr`), SPF existant `v=spf1 include:_spf-eu.ionos.com ~all` (**à fusionner** avec `include:spf.mailjet.com` — un seul SPF autorisé par domaine), DMARC `v=DMARC1; p=none;` déjà présent, DKIM Mailjet absent.
- **Reste (action du porteur, guide fourni)** : valider `soutrali.com` dans Mailjet (Account Settings ▸ Domains & DNS) et créer les 2 enregistrements chez IONOS ; ensuite je bascule `MAIL_FROM_ADDRESS` sur `support@soutrali.com`, je vide le cache de config et je refais un test réel de bout en bout (l’arrivée doit afficher « Soutrali <support@soutrali.com> » et le domaine `soutrali.com` comme expéditeur authentifié).

### 29 octobre 2026 — correctif back-office en ligne : le repli SPA avalait les scripts Livewire

- **Symptômes rapportés** sur `https://soutrali.alwaysdata.net/admin/login` : connexion impossible malgré des identifiants valides, œil « afficher le mot de passe » inerte, et formulaire qui **recharge la page** au lieu d’être soumis.
- **Cause isolée par requêtes réelles** : le repli vers `index.html` ajouté le 28 oct. n’excluait que `/api` et `/admin` ; or Filament charge son JavaScript Livewire depuis **`/livewire-fc0c5cb6/livewire.min.js`** (préfixe versionné, sans `/` après « livewire »), qui renvoyait donc le shell Flutter en `text/html` (`/up` était avalé aussi). Sans ce script, `wire:submit` ne peut pas intercepter la soumission : le POST natif part sur une route POST inexistante (405) d’où le rechargement, et les composants interactifs (œil du mot de passe) restent morts. Tous les autres assets Filament (`/js`, `/css`, `/fonts`, fichiers réels) répondaient déjà 200.
- **Correctif versionné** dans `backend/public/.htaccess` : exclusion élargie en `!^/(api|admin|livewire)` (préfixes, sans ancrage `/`) et repli limité aux méthodes `GET|HEAD` ; téléversé par SSH puis vérifié depuis l’extérieur.
- **Vérifications après déploiement** : `livewire.min.js` → **200 `application/javascript`** ; `POST /livewire-fc0c5cb6/update` → **419 « CSRF token mismatch »** (route vivante, attendue sans jeton) ; `/admin/login` → 200 ; `/api/v1/categories` → 200 JSON ; `/connexion` → 200 (shell Flutter) ; `/` → titre Soutrali. **Parcours navigateur réel** : œil du mot de passe bascule `password` → `text` ; soumission d’identifiants faux → notification inline « Ces identifiants ne correspondent pas » **sans rechargement** (marqueur JS toujours présent) et **zéro erreur console** ; compte administrateur temporaire créé par `soutrali:create-admin`, connexion → **Tableau de bord** avec les 7 rubriques, `/admin/users` → 2 comptes, puis compte de probe **supprimé** (base redevenue à son état initial).
- **Contrôles CI relancés** (29 oct.) : 74 tests Pest verts (722 assertions), pint PASS (125 fichiers), Larastan sans erreur.

---

## 3. Ce qui est fait et vérifié

### Backend Laravel

- API publique versionnée : `GET /api/v1/listings` (filtres `q`, `commune`, `category`, `type`, `nature`, pagination `page` / `per_page` plafonnée à 24) et `GET /api/v1/listings/{id}`, toutes deux limitées à 60 requêtes/minute.
- Référentiels publics : `GET /api/v1/categories` et `GET /api/v1/communes` (éléments `active` uniquement, 60 requêtes/minute), qui alimentent les filtres de l’écran. Les catégories — **32 services** depuis le 26 oct. 2026 — renvoient leur clé `icon`, que l’application traduit en icône de charte (bloc « Tous les services », menus de catégorie, cartes et détail).
- Authentification par session web Sanctum (D-04 validée) : `POST /api/v1/register`, `/login` (message d’erreur identique si le compte est inconnu), `/logout`, `GET /api/v1/me`, `GET /api/v1/csrf-token` (jeton CSRF en JSON). Mutations exigées en session, cookie de session `soutrali-session` et origine contrôlée.
- Annonces de l’utilisateur : publication immédiate `PUBLIEE` ou **programmée** (`publish_at` futur → statut `BROUILLON`, publication automatique par `soutrali:publish-due` planifiée chaque minute ; date non modifiable après mise en ligne ; publication immédiate `POST /listings/{id}/publish` renvoie 409 si déjà publiée), modification réservée au propriétaire (403 sinon), clôture avec `closure_outcome` (409 si déjà clôturée), liste `GET /api/v1/me/listings`.
- Messagerie interne tracée (D-05 validée) : fils par couple auteur/initiateur autour d’une annonce publiée, premier message au démarrage, accusés de lecture, compteurs de non-lus. Aucune coordonnée privée n’est échangée.
- Signalements (D-06 validée) : motif + détails, statut `NOUVEAU`, refus de signaler sa propre annonce, suivi côté auteur du signalement.
- Blocages d’utilisateurs (T-14, 24 oct. 2026) : `GET /api/v1/me/blocks`, `POST` / `DELETE /api/v1/users/{user}/block` (idempotents, 403 sur soi-même). Un blocage désactive la mise en relation dans les deux sens : démarrage et envoi dans une conversation refusés (403), canaux de contact refusés (403) — rien n’est supprimé.
- Canaux de contact du profil (F-02/F-06, complétion de D-05 le 24 oct. 2026) : `GET/POST/DELETE /api/v1/me/channels` (types `EMAIL`, `TELEPHONE`, `WHATSAPP` — un seul canal par type, visibilité propre à chaque canal) et `GET /api/v1/listings/{id}/contact-channels` : membres connectés uniquement (visiteur 401), canaux visibles de l’auteur uniquement, jamais ses propres (403), 403 en cas de blocage.
- Back-office Filament sur `/admin` (T-05) : 7 ressources (signalements, annonces, utilisateurs, catégories, communes, interactions, journal de modération), 8 policies enregistrées, panneau en **mode strict** (`strictAuthorization()`), accès réservé aux comptes `MODERATEUR` / `ADMINISTRATEUR` actifs. Toute décision de modération (prise en charge, masquage, republication, rejet, classement sans suite, **transmission à l’administrateur** — `TRANSMIS`, statut maintenu `EN_COURS`, 24 oct. —, suspension, réactivation) passe par le service `ReportModerator` et laisse une trace horodatée dans `moderation_actions` — le back-office ne crée ni ne supprime de signalement.
- Commande `soutrali:create-admin` (27 oct. 2026) : crée ou promeut en `ADMINISTRATEUR` actif le premier compte du back-office sur un déploiement vierge, avec validation e-mail et mot de passe (8 car. minimum), saisie masquée du mot de passe si l’option est omise.
- Journaux d’exploitation (26 oct. 2026, NF-10) : middleware global `LogAccess` → `storage/logs/access.log` (API et back-office, format `MÉTHODE /chemin statut user=… ip=… durée`) et canal `errors` → `storage/logs/error.log` (exceptions et échecs), rétention quotidienne de 30 jours ; les tests écrivent dans `storage/logs/testing-*.log` et ne touchent pas les journaux réels.
- E-mails transactionnels (F-09, 26 oct. 2026, branche `labo-soutrali-v2`) : `App\Support\Mail\Outbox` envoie trois mailables — bienvenue à l’inscription, annonce mise en ligne (immédiate, manuelle ou programmée échue), message reçu dans la messagerie (à l’autre participant, jamais à soi-même). Gabarits Blade à la charte, liens cliquables sur `config('app.frontend_url')`, mode local `MAIL_MAILER=log` et SMTP Mailjet en réel. **Une panne SMTP est journalisée dans `error.log` sans jamais faire échouer la requête.**
- Les réponses publiques n’exposent **aucune coordonnée privée** : la ressource ne renvoie que titre, description, type, nature, disponibilité, budget (nombre JSON), catégorie, commune, auteur (identifiant + nom affiché) et date. Les ressources `author` ne sont chargées que sur la route détail.
- Migrations des onze tables du modèle conceptuel : `communes`, `users`, `categories`, `listings`, `sessions`, `personal_access_tokens`, `contact_channels`, `user_blocks`, `interactions`, `reports`, `moderation_actions`. Les tables `contact_channels` et `user_blocks` correspondent à la décision T-14 ; colonne `publish_at` ajoutée aux `listings` le 24 oct. 2026 (migration non destructrice).
- Seeders : communes d’Abidjan (D-03) et catégories (D-07) validées le 22 oct. 2026, plus — **en local uniquement** — 3 comptes fictifs de démonstration (dont un administrateur du back-office) et 8 annonces.
- Modèles Eloquent avec relations et index de recherche (`status + commune + date`, `status + category + type + nature`).
- Manifeste Composer Laravel 13 + Sanctum 4 + Filament 5, avec Pest, Pint et Larastan en développement. `composer.lock` versionné.
- Workflow CI `.github/workflows/ci.yml` : Pest, Pint, Larastan côté backend ; `flutter analyze`, `flutter test`, build web release côté application.

### Application Flutter

- Page d’accueil interactive (`discover_page.dart`) : en-tête avec compte connecté (initiales, menu mes annonces / messagerie avec badge de non-lus / déconnexion), actions « Annonce » et « Prestation de service » avec choix immédiat/programmé, formulaire complet relié à l’API, filtres commune/nature/q, cartes cliquables vers le détail, signalement d’une annonce.
- Pages `/login` et `/register` : validation champ par champ, erreurs API 422 affichées champ par champ, ouverture de session immédiate après inscription.
- Détail d’annonce (`listing_detail_page.dart`) : contact de l’auteur par message (renvoi vers la connexion si visiteur, garde-fou « C’est votre annonce »), **canaux de contact de l’auteur affichés aux membres connectés** (section masquée si blocage ou pour sa propre annonce), **bouton bloquer / débloquer l’auteur**, signalement, lien de retour.
- `mes-annonces` : liste des annonces de l’utilisateur tous statuts, modification, clôture avec issue (récompensé, besoin satisfait, pas de réponse), **« Publier maintenant » et encart « Publication programmée » pour les annonces à date future**.
- `messagerie` : liste des fils avec non-lus et dernier message, vue de fil avec accusés de lecture et envoi.
- Thème centralisé aux couleurs de la charte v2 (`app/lib/src/theme/soutrali_theme.dart`) : orange `#FE7402`, vert `#037C30`, ivoire `#FFF9F2`. Aucune couleur écrite dans les écrans. **Polices de charte embarquées depuis le 24 oct. 2026** : familles « Manrope » (titres) et « Source Sans 3 » (corps) déclarées dans `pubspec.yaml`, fichiers TTF et licences OFL dans `assets/fonts/`, repli Arial/Helvetica conservé.
- Écran du compte : sections « **Canaux de contact** » (ajout / modification / visibilité) et « **Comptes bloqués** » (liste, déblocage) ; depuis le 26 oct. 2026, **bouton « Espace admin »** (menu du compte et fenêtre « Mon profil ») réservé aux rôles `MODERATEUR` / `ADMINISTRATEUR`, qui ouvre `/admin` dans un nouvel onglet.
- Configuration française fonctionnelle (délégués Material/Cupertino).
- Filtres « Commune » et « Catégorie » alimentés par l’API de référentiels (le filtre commune n’est plus codé en dur), avec état dégradé propre si l’API est absente.
- Quatorze tests : modèle d’annonce et filtres, référentiels et transmission des filtres, pages d’authentification (validation e-mail/mot de passe, liens croisés), actions de publication (visiteur invité à se connecter).

### Vérifications exécutées

- `pest` / `php artisan test` : **61 tests passés, 558 assertions** le 24 oct. (PHP 8.3, SQLite en mémoire) — dont 5 nouveaux fichiers : `ApiContractTest` (7), `BlockTest` (5), `ContactChannelTest` (6), `MigrationTest` (3), `ScheduledPublicationTest` (6), plus 1 test ajouté à `AdminPanelTest` (transmission à l’administrateur).
- `pint --test` : PASS sur 115 fichiers (24 oct.).
- `phpstan analyse` avec Larastan niveau 5 : aucune erreur (24 oct.).
- `flutter analyze` : **No issues found** (revérifié le 24 oct.).
- `flutter test` : **14 tests passés** (revérifié le 24 oct.).
- `flutter build web --release` : compilation réussie en 152 s (24 oct., après ajout des polices) ; `main.dart.js` **3 790 546 o brut / 1 071 108 o gzip** (relevé local), polices `Manrope.ttf` 164 700 o et `SourceSans3.ttf` 646 340 o, dossier `build/web` 43 Mo. Relevé antérieur du 22 oct. : 183,6 s, 3 294 322 o / 942 397 o gzip.
- **Mesures locales T1b (24 oct., non définitives)** : FCP 1 273 ms à froid / 1 009 ms à cache chaud dans Chromium, réponse `GET /api/v1/listings` à ~3,0 s / ~3,3 s, console propre — détails et limites au §2. Les mesures sur téléphone Android en réseau limité restent à faire.
- Parcours navigateur → API → MariaDB observé avec données le 22 oct. : requêtes `listings`, `communes`, `categories` et filtres en HTTP 200, annonce rendue à l’écran (voir §2, étape T1).
- Parcours complet observé dans le navigateur le 23 oct. : inscription, session, publication, détail avec garde-fou auteur, rendu de l’annonce publiée dans le fil ; puis 12 scénarios API à deux comptes (contact, lecture, réponse, non-lus, signalement, refus de signaler sa propre annonce, clôture, 403/404/409 attendus).
- `php artisan migrate` : **17 tables** créées (11 tables du modèle conceptuel + 6 tables d’infrastructure Laravel).
- `GET /api/v1/listings` : **HTTP 200** (relevé le 22 oct. sur base sans annonce, résultat normal à l’époque ; depuis le 22 oct., le seeder local charge 8 annonces fictives).
- Rendu navigateur contrôlé sur ordinateur et à 390 px : aucun débordement horizontal.
- Contrôle des règles Git d’ignore et scan de secrets : conformes (voir §2, 22 oct.).
- Ces vérifications sont exécutées sur le poste de développement. Leur passage dans la CI GitHub est suivi au §2.
- **Relevé du 26 octobre 2026** : `php artisan test` → **66 tests passés, 688 assertions** (dont `AccessLogTest`, 4 tests) ; `pint --test` → PASS sur **118 fichiers** ; `phpstan analyse` → aucune erreur ; `flutter analyze` → **No issues found** ; `flutter test` → **21 tests passés** (dont `admin_entry_test.dart`, 4 tests) ; `flutter build web --release` → succès. Vérifié en local : trois `curl` (liste publique 200, `/me` en 401, `/admin` en 302) relus dans `storage/logs/access.log` avec utilisateur, IP et durée.
- **Relevé du 26 octobre 2026 (suite, phase 2)** : `php artisan test` → **71 tests passés, 708 assertions** (dont `EmailNotificationTest`, 5 tests / 20 assertions) ; `pint --test` → PASS sur **123 fichiers** ; `phpstan analyse` → aucune erreur. Aucune modification Flutter à ce jalon.
- **Relevé du 27 octobre 2026 (phase 2, desktop)** : `flutter analyze` → **No issues found** ; `flutter test` → **24 tests passés** (configuration desktop couverte, jar mémoire sous `FLUTTER_TEST`) ; backend relancé à l’identique : `composer test` → **71 tests Pest passés (708 assertions)**, `composer format:check` → PASS sur **123 fichiers**, `composer analyse` → aucune erreur. Vérifié en réel avec le paquet `dist/Soutrali-win64` : catégories 200, inscription 201, connexion 200, `/me` 200, `/me/listings` 200 sur `127.0.0.1:8123` avec le PHP 8.3.36 portable et la base SQLite du paquet. **Suite du 27 oct. (constat final)** : exécutable Windows compilé et zip de 112 Mo assemblé (voir §2, 28 oct.).
- **Relevé du 28 octobre 2026 (mise en ligne)** : vérifications HTTP réelles sur `https://soutrali.alwaysdata.net` — `/up` **200**, `/api/v1/categories` **200** (32 services), `/api/v1/communes` **200** (14), `/api/v1/listings` **200** (0 en base vierge), `csrf-token` **200** + cookie, `register` **201**, `me` **200**, `/admin` **302 → /admin/login 200**, `login` **200** puis `me` **200** avec rôle `ADMINISTRATEUR` ; 9 requêtes relues dans `access.log` de production ; aucune erreur SMTP journalisée. En local, suites inchangées (74 tests Pest / 722 assertions, pint PASS 125 fichiers, Larastan sans erreur, `flutter analyze` propre, 24 tests Flutter).

---

## 4. Ce qui bloque, et pourquoi

**Résolus** : la base `soutrali` est migrée (17 tables) et le compte SQL dédié `soutrali_dev` existe avec des droits limités ; `GET /api/v1/listings` répond 200 (T0). Les référentiels sont en base et exposés par l’API (T1). Les décisions D-04, D-05 et D-06 sont validées et les parcours compte / publication / contact / signalement / clôture sont implémentés et vérifiés (22–23 oct.). La modération des signalements a désormais une interface : le back-office `/admin` traite et trace chaque décision depuis le 23 oct. 2026 (10 tests Pest dédiés). L’**identité visuelle embarquée** est en place depuis le 24 oct. 2026 : polices Manrope et Source Sans 3 (licences OFL vérifiées), icônes et favicons générés depuis le logo source — il reste à valider le rendu sur appareils réels et à produire les déclinaisons restantes (§5, étape 7).

| Blocage | Cause vérifiée | Conséquence |
|---|---|---|
| Le tir d’essai T1b est incomplet sur ses volets mesure téléphone | Le parcours navigateur → API → base et la session Sanctum sont observés ; les **mesures locales** (poids du build, FCP, réponse API) ont été relevées le 24 oct. (§2), mais les mesures sur téléphone Android en réseau limité ne sont pas faites : aucun téléphone instrumenté, serveur local sans compression gzip | Les seuils de réussite ne peuvent pas être présentés à la MOA |

---

## 5. Ce qui reste à faire, dans l’ordre

L’ordre suit le plan T0 → T8 de la stack v3. **Ne pas ajouter d’écran avant la fin de T1b.**

**Phase 2 (branche `labo-soutrali-v2`, ordre arrêté le 26 oct. 2026 avec le porteur)** : (1) e-mails réels F-09 ✅ — SMTP Mailjet actif en production, reste la confirmation de réception et la vérification du domaine `soutrali.com` (voir §2, 28 oct.) ; (2) application **desktop Windows tout-en-un** ✅ — `soutrali.exe` compilé le 27 oct. et `dist/Soutrali-win64.zip` (112 Mo) testé par double-clic sur poste sans rien d’installé ; (3) mise en ligne du backend sur hébergement **gratuit** ✅ le 28 oct. 2026 (`https://soutrali.alwaysdata.net`, AlwaysData) ; (4) APK Android signé pointant vers cette API en ligne ✅ le 28 oct. 2026 (`app-release.apk`, 56,3 Mo, `CN=Soutrali`, URL gravée — voir §2).

1. **T0 — débloquer l’environnement : fait le 22 octobre 2026**
   - Compte SQL dédié créé, droits limités à `soutrali`. **Fait.**
   - Migrations exécutées, 17 tables vérifiées. **Fait.**
   - `GET /api/v1/listings` répond 200. **Fait.**
   - Composer retrouvé et chemin exact documenté dans `INSTALLATION.md`. **Fait.**
2. **T1 — données de référence : fait le 22 octobre 2026**
   - Seeder chargé : 14 lignes de communes (D-03 validée), 8 catégories (D-07 validées) +, en local, 2 comptes et 8 annonces fictifs. **Fait.**
   - Routes `GET /api/v1/categories` et `GET /api/v1/communes` écrites et vérifiées par HTTP réel. **Fait.**
   - Filtres Flutter commune et catégorie alimentés par l’API. **Fait.**
   - ~~Hors T1, toujours ouvert : les routes de publication et d’authentification n’existent pas (D-04).~~ **Résolu le 22 oct. 2026** : routes d’authentification et de publication implémentées.
3. **T1b — tir d’essai : en cours**
   - Faire répondre l’API à l’écran Flutter Web avec des données de la base. **Fait le 22 oct. 2026** (requêtes 200 observées, annonce rendue à l’écran).
   - Valider la session Sanctum de bout en bout : connexion, requête mutante avec CSRF, déconnexion, en développement puis sur build servi par la même origine. **Fait le 23 oct. 2026** (inscription, connexion, publication, contact, signalement, clôture observés dans le navigateur et rejoués par API à deux comptes).
   - ~~Mesurer le poids compressé et le temps jusqu’au premier écran utile~~ — **mesures locales faites le 24 oct. 2026** (poids du build gzip calculé, FCP et réponse API relevés dans Chromium, voir §2) ; **mesure sur un téléphone Android courant en réseau limité : à faire. Seuils à fixer avec la MOA ; aucun chiffre inventé.**
   - Si la mesure échoue durablement : évaluer `--wasm`, chargement différé, assets réduits, puis rouvrir T-01 pour le web seul.
4. **T2 — comptes et administration** : comptes, authentification et profil minimal **faits** (22 oct.). Rôles, back-office `/admin`, catégories et communes, traitement des signalements par un modérateur : **faits le 23 octobre 2026**. Création du premier administrateur en production : **faite le 27 octobre 2026** (commande `soutrali:create-admin`, testée).
5. **T3 — annonces** : création, recherche filtrée, détail, modification, clôture avec issue : **faits** (22–23 oct.). Reste à tester sur téléphone et à durcir (contrats API dans la CI).
6. **T4 — confiance et contact** : messagerie interne tracée et signalements **faits** (22 oct.), modération traçable **faite le 23 oct. 2026** (back-office + journal `moderation_actions`), **blocages d’utilisateurs (T-14) et canaux de contact du profil (F-02/F-06) faits le 24 oct. 2026**, transmission à l’administrateur ajoutée le même jour. **T4 complet pour le MVP.**
7. **Identité visuelle** : ~~produire les icônes et favicons ; embarquer Manrope et Source Sans 3~~ **fait le 24 oct. 2026** (icônes/favicons générés par `brand/generate-icons.php`, polices OFL embarquées). Reste : déclinaisons restantes du logo (SVG, monochrome, inversée, §15.7), validation du rendu sur appareils réels, confirmation du logo et de la palette (D-02).
8. **Tests** : permissions du back-office couvertes depuis le 23 oct. (10 tests d’accès et de modération), **contrat API, migrations, blocages, canaux de contact et publication programmée couverts depuis le 24 oct.** Reste : exécuter ces suites dans la CI à chaque dépôt (workflow existant) et tester le parcours complet sur téléphone.

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
