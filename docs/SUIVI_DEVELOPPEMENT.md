# Soutrali — Suivi de développement

> **Objet :** journal technique étape par étape du socle Soutrali. Il répond à une seule question : *où en est réellement l’implémentation, qu’est-ce qui a été vérifié, qu’est-ce qui bloque, et que reste-t-il à faire ?*
>
> **Ce document n’est pas le cadrage fonctionnel.** Le cadrage (besoins, règles métier, périmètre MVP, décisions D-xx) vit dans [`README.md`](../README.md). L’architecture de référence vit dans [`README_TECHNIQUE.md`](README_TECHNIQUE.md). La procédure de démarrage vit dans [`INSTALLATION.md`](INSTALLATION.md).
>
> **Règle d’or :** chaque entrée décrit un fait observé, jamais une intention. Si une mesure n’a pas été faite, elle est écrite « non mesurée ». Si un seuil n’est pas fixé par la MOA, aucun chiffre n’est proposé.
>
> **Version :** 1.0 · **Dernière mise à jour :** 22 octobre 2026

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

Constats relevés le **22 octobre 2026** sur le poste de développement, par exécution réelle des commandes.

| Élément | Constat vérifié |
|---|---|
| Dépôt distant | `github.com/0Defiance/soutrali`, branche `main`, publique. Contient désormais le code, la documentation et le cadrage |
| Dépôt local | Initialisé le 22 oct. 2026, index aligné sur `main`, arborescence réorganisée |
| Flutter / Dart | 3.47.7 / 3.13.5 installés et fonctionnels (`flutter --version` exécuté) |
| PHP CLI | 8.3.33 installé séparément de XAMPP, fonctionnel (`php -v` exécuté) |
| Composer | **Absent du PATH** de la session de commande (revérifié le 22 oct.). Les dépendances sont pourtant installées (`backend/vendor/` contient 63 paquets) et `composer.lock` existe (452 408 octets) |
| Git | 2.56.0 fonctionnel |
| GitHub CLI | 2.102.1 installée, **non authentifiée** (`gh auth status` : aucune session) |
| MariaDB | 10.4.32 démarrée sur le port 3306 (revérifié le 22 oct. : le port écoute) |
| Base `soutrali` | **Migrée : 17 tables.** `php artisan migrate:status` affiche les 4 migrations « Ran » (revérifié le 22 oct.) |
| Utilisateur SQL `soutrali_dev` | **Créé le 22 oct. 2026**, droits limités à `soutrali.*`. `backend/.env` l’utilise et `php artisan migrate:status` s’y connecte sans erreur |
| `backend/.env` | Présent localement, **correctement ignoré par Git**, non publié |
| Icônes web | `app/web/icons/*` et `app/web/favicon.png` sont les **icônes par défaut du squelette Flutter**, pas la marque Soutrali |
| `backend/public/favicon.ico` | **Fichier vide (0 octet)** |
| Polices | Manrope et Source Sans 3 **non embarquées** ; le thème retombe sur `Arial` |
| Serveurs de développement | Trois processus hérités de la session du 21 oct. ont été arrêtés le 22 oct. (Laravel figé sur 8000, deux serveurs Flutter sur 8081 et 8082). À la reprise de séance : l’API Laravel tourne sur `127.0.0.1:8000` (`php.exe`, PID 7248) et répond HTTP 200 ; aucun serveur Flutter n’est lancé sur 8082 |

**Conclusion :** le socle T1 est partiellement en place et **le tir d’essai T1b n’est pas terminé**. Aucun parcours de bout en bout (navigateur → API → base) n’a encore été observé en fonctionnement.

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

---

## 3. Ce qui est fait et vérifié

### Backend Laravel

- API publique versionnée : `GET /api/v1/listings` (filtres `q`, `commune`, `category`, `type`, `nature`, pagination `page` / `per_page` plafonnée à 24) et `GET /api/v1/listings/{id}`, toutes deux limitées à 60 requêtes/minute.
- Les réponses publiques n’exposent **aucune coordonnée privée** : la ressource ne renvoie que titre, description, type, nature, disponibilité, budget, catégorie, commune et date.
- Migrations des onze tables du modèle conceptuel : `communes`, `users`, `categories`, `listings`, `sessions`, `personal_access_tokens`, `contact_channels`, `user_blocks`, `interactions`, `reports`, `moderation_actions`. Les tables `contact_channels` et `user_blocks` correspondent à la décision T-14.
- Modèles Eloquent avec relations et index de recherche (`status + commune + date`, `status + category + type + nature`).
- Manifeste Composer Laravel 13 + Sanctum 4 + Filament 5, avec Pest, Pint et Larastan en développement. `composer.lock` versionné.
- Workflow CI `.github/workflows/ci.yml` : Pest, Pint, Larastan côté backend ; `flutter analyze`, `flutter test`, build web release côté application.

### Application Flutter

- Page de découverte responsive reliée à l’API, avec filtres et états de chargement / erreur / vide.
- Thème centralisé aux couleurs de la charte v2 (`app/lib/src/theme/soutrali_theme.dart`) : orange `#FE7402`, vert `#037C30`, ivoire `#FFF9F2`. Aucune couleur écrite dans les écrans.
- Configuration française fonctionnelle (délégués Material/Cupertino).
- Cinq tests : parsing du modèle d’annonce et filtres (2), comportement des actions de publication (3).
- Actions « Annonce » et « Prestation de service » avec choix immédiat/programmé et validation de saisie côté interface.

### Vérifications exécutées

- `pest` : 2 tests passés, 2 assertions (PHP 8.3.33, SQLite en mémoire).
- `pint --test` : PASS sur 36 fichiers.
- `phpstan analyse` avec Larastan niveau 5 : aucune erreur.
- `flutter analyze` : **No issues found** (corrigé le 22 oct., voir §2).
- `flutter test` : **5 tests passés**.
- `flutter build web --release` : compilation réussie ; police d’icônes Material réduite de 1 645 184 à 9 996 octets.
- `php artisan migrate` : **17 tables** créées (11 tables du modèle conceptuel + 6 tables d’infrastructure Laravel).
- `GET /api/v1/listings` : **HTTP 200** avec une liste paginée vide — résultat normal tant que le seeder est vide.
- Rendu navigateur contrôlé sur ordinateur et à 390 px : aucun débordement horizontal.
- Contrôle des règles Git d’ignore et scan de secrets : conformes (voir §2, 22 oct.).
- Ces vérifications sont exécutées sur le poste de développement. Leur passage dans la CI GitHub est suivi au §2.

---

## 4. Ce qui bloque, et pourquoi

**Résolus le 22 octobre 2026** : la base `soutrali` est migrée (17 tables) et le compte SQL dédié `soutrali_dev` existe avec des droits limités ; `GET /api/v1/listings` répond 200. Voir §2, étape T0.

| Blocage | Cause vérifiée | Conséquence |
|---|---|---|
| Composer introuvable dans la session de commande | Absent du PATH ; les dépendances sont pourtant déjà installées | `composer install` ne peut pas être relancé tel quel ; `php artisan` fonctionne car `vendor/` existe |
| Le tir d’essai T1b est incomplet | Le parcours navigateur → API → base n’a pas encore été observé avec des données ; les mesures de poids compressé et de temps jusqu’au premier écran utile sur téléphone n’ont pas été faites | Les seuils de réussite ne peuvent pas être présentés à la MOA |
| Les parcours compte / publication / contact / signalement n’existent pas | Les décisions produit D-04 (inscription), D-05 (canal de contact) et D-06 (modération) sont **ouvertes** | Impossible d’implémenter sans trancher ; ne pas inventer |
| Le seeder est vide et les routes de référentiels n’existent pas | Aucune donnée de démonstration chargée ; `GET /api/v1/categories` et `/communes` ne sont pas écrites | Alimenter le seeder n’aurait aucun effet observable tant que ces routes manquent |

---

## 5. Ce qui reste à faire, dans l’ordre

L’ordre suit le plan T0 → T8 de la stack v3. **Ne pas ajouter d’écran avant la fin de T1b.**

1. **T0 — débloquer l’environnement : fait le 22 octobre 2026**, sauf un point.
   - Compte SQL dédié créé, droits limités à `soutrali`. **Fait.**
   - Migrations exécutées, 17 tables vérifiées. **Fait.**
   - `GET /api/v1/listings` répond 200. **Fait.**
   - Reste : rendre Composer disponible dans la session de commande, ou documenter le chemin exact de l’exécutable.
2. **T1 — données de référence**
   - Alimenter le seeder : les communes d’Abidjan (liste D-03 à confirmer) et les catégories proposées (D-07), sans donnée personnelle réelle.
3. **T1b — tir d’essai**
   - Faire répondre l’API à l’écran Flutter Web avec des données réelles de la base.
   - Valider la session Sanctum de bout en bout : connexion, requête mutante avec CSRF, déconnexion, en développement puis sur build servi par la même origine.
   - Mesurer le poids compressé et le temps jusqu’au premier écran utile sur un téléphone Android courant en réseau limité. **Seuils à fixer avec la MOA ; aucun chiffre inventé.**
   - Si la mesure échoue durablement : évaluer `--wasm`, chargement différé, assets réduits, puis rouvrir T-01 pour le web seul.
4. **T2 — comptes et administration** (après avoir tranché D-04) : authentification, profils, rôles, Filament, catégories et communes.
5. **T3 — annonces** : création, recherche filtrée, détail, modification, clôture avec issue.
6. **T4 — confiance et contact** (après D-05, D-06) : canaux de contact, interactions, signalements, modération traçable.
7. **Identité visuelle** : produire les icônes et déclinaisons du logo aux couleurs de la marque, remplacer les icônes Flutter par défaut et régénérer le favicon vide du backend ; embarquer Manrope et Source Sans 3 après vérification de licence.
8. **Tests** : ajouter des tests Pest couvrant le contrat API, les migrations, les permissions et la visibilité des canaux de contact.

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
