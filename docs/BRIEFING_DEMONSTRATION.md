# Briefing — démonstration en direct de Soutrali

**Objet :** préparer la séance de démonstration demandée après l'examen du projet.
**Format annoncé :** ~30 minutes, **sans assistant IA** — tout ce qui est montré doit
être fait à la main, par vous.
**État du dépôt au moment de la rédaction :** `labo-soutrali-v2`, arbre de travail propre,
suite de tests verte (voir §2).

---

## 1. Ce qui est demandé, mot pour mot

| Demande | Critère de réussite | Où c'est traité ici |
|---|---|---|
| Montrer le parcours complet : inscription, annonce, message, signalement, modération | Les 5 étapes s'enchaînent sur une même histoire, sans temps mort, et la modération a un effet visible côté application | §5 |
| Expliquer avec vos mots comment est protégée une conversation privée | 90 secondes, sans jargon non expliqué, avec une **preuve** (test ou refus réel) | §6 |
| Faire devant lui une petite modification (un texte **et** la règle qui va avec), écrire le test, relancer les tests | Test écrit d'abord (rouge), modification, test vert, suite relancée | §7 |

**Piège à éviter :** improviser la modification. Le temps de frappe + un test rouge
inattendu peuvent faire dérailler les 30 minutes. Le texte exact à taper est en §7 — la
séquence y a été **répétée pour de vrai** le 6 nov. 2026 (rouge, vert, fichier complet).

---

## 2. Les 5 corrections à faire **avant** la séance

Elles ont été listées dans le retour d'examen. En laisser une seule en l'état pendant la
démo affaiblit tout le reste. Classement par rapport bénéfice/risque.

| # | Point | Où exactement | Effort | Priorité | Statut |
|---|---|---|---|---|---|
| 1 | « à porter » → « à **portée** » | `app/lib/src/app.dart:43`, `app/lib/src/features/discover/discover_page.dart:1393`, `app/lib/src/features/auth/auth_shell.dart:127`, `app/web/index.html:33`, `app/web/manifest.json:2`, `backend/resources/views/emails/layout.blade.php:16`, `README.md`, `docs/INSTALLATION.md:397`, `docs/SUIVI_DEVELOPPEMENT.md:327` | 20 min + rebuild web | **P0** | **Fait le 6 nov. 2026** (13 occurrences, logo compris ; `docs/archive/` conservé). Bundle web reconstruit dans `app/build/web` : reste le **téléversement** |
| 2 | Sortir les ~165 Mo de livrables du dépôt | `livrables/*.zip`, `livrables/*.apk` étaient versionnés | 30 min | **P0** | **Fait le 6 nov. 2026** (`git rm --cached` + `.gitignore`, notice pointée vers les Releases). Reste : créer la Release `v0.2.0` (voir §2.2) |
| 3 | `vendor` sans outils de dev dans le paquet Windows | `desktop/build-package.ps1` | 20 min | P1 | **Fait le 6 nov. 2026** (étape conditionnelle `composer install --no-dev`) ; s'applique au prochain empaquetage |
| 4 | Compte admin de démo avec mot de passe `password` | `DemoSeeder.php` **et** `desktop/build-package.ps1` (`db:seed` + `APP_ENV=local`) | 20 min | **P0** | **Fait le 6 nov. 2026** : le paquet ne sème plus que le référentiel, aucun compte fictif |
| 5 | `discover_page.dart` : 1 956 lignes | `app/lib/src/features/discover/discover_page.dart` | 1 h 30 | P2 (annoncer le plan) | À faire après la démo |

### 2.1 Coquille « à porter » (P0)

Attention : ce n'est pas qu'un texte d'écran, c'est la **signature de marque** (§15 du
README). Vérifiez aussi que le logo source ne la contient pas en dur
(`brand/logo/*.png`) — si oui, la retouche d'image est un travail séparé, à annoncer.

Ordre d'exécution :

```bash
# 1. remplacer partout (hors docs/archive/, qui est un document daté à conserver tel quel)
# 2. refaire le bundle web et le redéployer, sinon le site en ligne gardera l'ancien texte
cd app && flutter build web --release --dart-define=API_BASE_URL=https://soutrali.alwaysdata.net
# 3. re-uploader app/build/web sur l'hébergement, puis Ctrl+F5 dans le navigateur
```

Sans l'étape 2–3, l'examinateur ouvrira le site et lira encore « à porter » : c'est le
pire scénario possible. **Le texte affiché en ligne doit être le texte corrigé.**

Le bundle est **déjà reconstruit** (`app/build/web`). Il ne reste que le téléversement, dans
`backend/public/` (le site est un lien `www/soutrali → backend/public`) :

```bash
cd app/build/web && scp -r index.html flutter.js flutter_bootstrap.js flutter_service_worker.js \
  main.dart.js manifest.json version.json assets canvaskit icons \
  soutrali@ssh-soutrali.alwaysdata.net:/home/soutrali/soutrali/backend/public/
```

`favicon.png` est volontairement exclu : celui du backend est le favicon du back-office.
Contrôle depuis l'extérieur — la réponse doit porter le nouveau titre, et **Ctrl+F5** dans le
navigateur (le serveur statique n'envoie pas de `Cache-Control`) :

```bash
curl -s https://soutrali.alwaysdata.net/ | grep -o "<title>[^<]*</title>"
```

Les lignes de `docs/SUIVI_DEVELOPPEMENT.md` et `docs/INSTALLATION.md` qui citent l'ancien
titre sont des **relevés de vérification** : mettez-les à jour en même temps que la
re-vérification (elles doivent décrire ce que renvoie réellement le site).

### 2.2 Livrables hors dépôt (P0) — fait, sauf la Release

Déjà exécuté et committé le 6 nov. 2026 (les fichiers restent sur le disque, seuls
l'index Git et la notice changent) :
`git rm --cached` sur les 4 archives, entrées `livrables/*.zip` et `livrables/*.apk` dans
`.gitignore`, et `livrables/README.md` pointe désormais vers
`https://github.com/0Defiance/soutrali/releases/latest`.

L'APK a été **recompilé le 6 nov. 2026** avec le logo et la signature corrigés
(`livrables/soutrali-android.apk`, 56,2 Mo, certificat `CN=Soutrali` **identique** à la version
précédente — donc mise à jour possible sans désinstallation —, SHA-256
`995723cb9736a0b63d82b16dee1e8b3a52a3c0f3693ad8fdeb86901a284490b9`).

Reste à créer la Release — `gh` est installé mais **non authentifié**, donc c'est le geste
du porteur (une fois : `gh auth login`, puis) :

```bash
gh release create v0.2.0 livrables/Soutrali-win64-1-backend.zip livrables/Soutrali-win64-2-runtime.zip \
  livrables/Soutrali-win64-3-programme.zip livrables/soutrali-android.apk \
  --title "v0.2.0 — livrables de test" --notes "Paquet desktop Windows tout-en-un + APK Android signé"
```

Ou par l'interface : **Releases → Draft a new release → tag `v0.2.0`**.
Réécrire l'historique pour purger les 165 Mo n'est **pas** nécessaire ici et reste
destructif : ne le faites pas sans demande explicite.

### 2.3 Paquet Windows sans outils de dev (P1)

`composer` n'est pas dans le `PATH`, mais il est installé :
`php "C:\Users\Abd Al Fattah\AppData\Local\Programs\Composer\composer.phar"` (2.10.3).
`build-package.ps1` exécute désormais `composer install --no-dev --optimize-autoloader`
quand Composer est joignable, et **avertit** sinon (plutôt que de livrer Pest, PHPStan, Pint
et Faker en silence).

À vérifier après le prochain empaquetage : plus de `vendor/bin/pest`, et le paquet démarre
toujours (`soutrali.exe` → catégories 200).

### 2.4 Compte de démonstration `password` (P0)

Le vrai défaut n'est pas le seeder local, c'est le **paquet desktop livré** : `APP_ENV=local`
+ `db:seed` ⇒ `admin.demo` / `password` embarqué chez le destinataire.

Appliqué dans `desktop/build-package.ps1` : `db:seed --class=CommuneSeeder` puis
`--class=CategorySeeder`, jamais `db:seed` (qui appelle `DemoSeeder`). L'administrateur se
crée à la première utilisation :

```powershell
php artisan soutrali:create-admin <email>   # mot de passe saisi masqué
```

**Important :** les paquets déjà distribués contiennent encore ce compte — considérez ce mot
de passe comme compromis. La notice `livrables/README.md` le dit maintenant explicitement.

### 2.5 Découpage de `discover_page.dart` (P2)

Ne le faites pas à la veille de la démo. Annoncez un plan crédible : extraire en 4 fichiers
`hero_section.dart`, `filters_bar.dart`, `listing_card.dart`, `my_activity_sheet.dart`
(annonces + signalements), avec `flutter test` vert à chaque étape. Si vous le faites,
vérifiez `flutter analyze` (0 erreur) et `flutter test` avant de commiter.

---

## 3. Préparer la machine (J-1 puis H-1)

### H-1 — environnement local

```bash
# MySQL de XAMPP démarré (le .env local pointe sur MySQL : DB_DATABASE=soutrali)
cd backend && php artisan serve --host 127.0.0.1 --port 8000
# autre terminal
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8000/api/v1/categories   # attendu : 200
php artisan db:seed        # référentiel + DemoSeeder (local uniquement)
```

**Commandes de contrôle qualité** — `composer` n'est pas dans le `PATH`, mais l'équivalent
direct fonctionne, et le `composer.phar` est joignable :

| Intention | Commande qui fonctionne ici | CI |
|---|---|---|
| Tests serveur | `cd backend && php artisan test` | `composer test` |
| Style | `cd backend && php vendor/bin/pint --test` | `composer format:check` |
| Analyse statique | `cd backend && php vendor/bin/phpstan analyse` | `composer analyse` |
| Équivalent CI complet | `php "C:\Users\Abd Al Fattah\AppData\Local\Programs\Composer\composer.phar" test` | — |
| App | `cd app && flutter analyze && flutter test` (Flutter : `C:\soutrali-android\flutter\bin`) | idem |

État mesuré aujourd'hui : **74 tests, 722 assertions, 116 s** ; Pint **125 fichiers OK** ;
PHPStan niveau 5 **aucune erreur** ; site `https://soutrali.alwaysdata.net` **200**.

### H-1 — comptes et onglets

Préparez **quatre** comptes (deux suffisent techniquement, quatre rendent la démo fluide) :

1. `prestataire` — publie l'offre (auteur de l'annonce) ;
2. `demandeur` — contacte l'auteur, envoie le message ;
3. `tiers` — ni auteur ni contact : c'est lui qui **signale** (et qui sert à la preuve 403) ;
4. `admin` — back-office `/admin` (créé par `soutrali:create-admin`, **pas** `admin.demo`).

Onglets à ouvrir d'avance : le site (prod ou `http://127.0.0.1:8082`), `/admin`, un terminal
dans `backend/`, l'éditeur sur `MyListingController.php` **et** `MyListingTest.php`.
Deux profils de navigateur (ou une fenêtre privée) pour éviter de vous déconnecter en
permanence : un onglet par rôle.

### H-1 — filets de sécurité

- Enregistrez une vidéo du parcours complet (2 min) : si le réseau ou MySQL tombe, vous
  commentez la vidéo au lieu de perdre 10 minutes.
- Vérifiez la veille **et** le matin que `https://soutrali.alwaysdata.net` répond.
- Testez une fois la modification du §7 en entier, chronomètre en main, sur une copie :
  vous devez savoir combien de temps elle prend réellement.

---

## 4. Déroulé minuté (30 min)

| Min | Séquence | Ce que vous faites | Ce que l'examinateur note |
|---|---|---|---|
| 0–2 | Cadre | « Je vous propose 5 parcours, puis la protection d'une conversation, puis je modifie quelque chose devant vous. » | maîtrise du temps |
| 2–5 | Inscription | Compte neuf, mot de passe court refusé, puis inscription valide | la règle est expliquée avant d'être montrée |
| 5–9 | Annonce | Publication d'une annonce, filtres commune + service, apparition en tête | parcours réel, pas de maquette |
| 9–13 | Message | 2ᵉ rôle : « Contacter l'auteur » → message → réponse depuis la messagerie | le fil est privé (annonce-le ici) |
| 13–16 | Signalement | 3ᵉ rôle : « Signaler » → motif → suivi dans « Mes signalements » | l'utilisateur garde la trace |
| 16–21 | Modération | `/admin` → Signalements → Prendre en charge → Traiter (Annonce masquée + justification) → retour app : l'annonce a disparu | la boucle est fermée |
| 21–24 | Conversation privée | Explication 90 s + preuve par le test 403 | vous savez *pourquoi* le code est ainsi |
| 24–29 | Modification live | Test rouge → règle + message → test vert → suite complète | méthode, pas seulement résultat |
| 29–30 | Clôture | Dettes connues, prochaines étapes, questions | honnêteté |

Si vous prenez du retard : **coupez le parcours signalement/modération à 4 minutes**
(l'essentiel est la boucle modération) et **gardez** la modification live : c'est la partie
notée.

---

## 5. Les cinq parcours : clics et phrases

### 5.1 Inscription (`/register`)

Cliquez « S’inscrire » depuis l'accueil. Montrez d'abord un refus : mot de passe de
6 caractères → message d'erreur. Puis inscrivez-vous pour de vrai.

> « Le compte est créé et la session ouverte immédiatement ; le mot de passe est haché
> côté serveur, jamais stocké en clair, et la session est régénérée à l'inscription. »

**Piège :** ne dites pas qu'un e-mail de bienvenue arrive si `MAIL_MAILER` n'est pas
configuré sur la machine que vous montrez. En local, l'e-mail part dans `storage/logs`.
Dites : « l'envoi est journalisé en local, actif en production ».

### 5.2 Annonce

Depuis « Mes annonces » → « Publier l’annonce ». Remplissez : *Recherche plombier pour une
fuite sous l’évier*, catégorie **Plomberie et sanitaire**, commune **Cocody**.

> « Une annonce = un type (demande/offre), une nature (bénévole/rémunérée), un service et
> une commune. La publication est immédiate ; une date future la laisse en brouillon
> jusqu'au jour dit — c'est la commande planifiée. »

Ensuite, sur l'accueil : filtrez par commune puis par service. L'annonce apparaît.

### 5.3 Message

Déconnectez-vous (ou autre profil) → ouvrez l'annonce → « Contacter l’auteur » → message.
Puis « Messagerie » : le fil apparaît avec le compteur de non-lus. Répondez depuis l'autre
rôle pour montrer que c'est bidirectionnel.

> « Le fil est unique par annonce et par personne qui écrit : deux demandeurs différents
> n'ont pas le même fil, et l'auteur les voit séparément. »

### 5.4 Signalement

Troisième rôle → ouvrez la même annonce → « Signaler » → motif *Fausse annonce ou arnaque*,
détails. Puis « Mes signalements » (dans le profil) : statut **Nouveau**.

> « Le signalement n'est pas un bouton décoratif : il crée une ligne en base avec un statut,
> et l'utilisateur suit son état. Le dépôt de son propre signalement sur sa propre annonce
> est refusé par le serveur. »

### 5.5 Modération (`https://soutrali.alwaysdata.net/admin`)

Connexion admin → **Signalements** → le signalement apparaît en rouge « Nouveau » →
action **Prendre en charge** (statut *En cours*) → **Traiter** → décision
**Annonce masquée** + justification → retour sur l'application : **l'annonce a disparu de
la recherche**.

> « Trois choses se passent : le signalement change de statut, l'annonce est masquée, et
> l'action est écrite dans `moderation_actions` avec son auteur, sa décision et sa
> justification. Rien ne se fait sans trace. »

**Piège :** `/admin` ne s'ouvre qu'à un compte `MODERATEUR` ou `ADMINISTRATEUR`
(`User::canAccessPanel`). Testez la connexion admin **avant** la séance : c'est le genre
d'écran qui se bloque au pire moment.

---

## 6. « Comment est protégée une conversation privée » — votre réponse en 90 s

Dites-le dans cet ordre : qui, où, et ce qui ne fuit pas.

**a) Il faut être quelqu'un (authentification).**
Toutes les routes de messagerie sont derrière `auth:sanctum` (`backend/routes/api.php`).
Sans session : 401. Le serveur ne croit jamais un identifiant envoyé par le client — il
lit l'utilisateur de la session.

**b) Même connecté, il faut être l'un des deux (autorisation sur l'objet).**
Avant de lire ou d'écrire, `abort_unless($interaction->involves($user), 403)` dans
`ConversationController`. `involves()` (`app/Models/Interaction.php`) : `true` seulement si
l'utilisateur est **l'initiateur du fil** ou **l'auteur de l'annonce**. Un troisième compte
reçoit **403**, pas une page vide.

**c) On ne peut pas tomber dessus par hasard (pas d'énumération).**
La liste `/api/v1/conversations` est filtrée sur *mes* fils (initiateur ou auteur). Un
identifiant de fil volé ne sert à rien sans être participant.

**d) Le contenu ne sort pas par la bande.**
L'API publique des annonces n'expose jamais les messages ; l'e-mail « vous avez reçu un
message » part uniquement vers **l'autre** participant, jamais vers l'émetteur ; au
back-office, `InteractionPolicy` et `MessagePolicy` donnent une **lecture seule** aux
modérateurs (`create/update/delete` renvoient `false`) et chaque décision est tracée.

**Preuve en direct (10 s) :**

```bash
cd backend && php artisan test --filter="locks a conversation"
```

Le test `locks a conversation to its two participants` montre : le tiers reçoit 403 en
lecture **et** en écriture, et sa propre liste de conversations est vide.

**Deux limites à annoncer vous-même** (elles vous crédibilisent) :

- Le contenu est en clair en base : la confidentialité repose sur l'autorisation et le TLS,
  pas sur du chiffrement de bout en bout (hors périmètre MVP, D-05).
- Un modérateur **peut** lire un fil en cas de litige — c'est délibéré, en lecture seule et
  tracé. Si ce n'est pas le contrat voulu, c'est une décision à prendre avec la MOA.

---

## 7. La modification en direct : un texte **et** sa règle

**Pourquoi ce choix :** il est petit, il a un sens métier, et il met au jour un vrai défaut
que l'examen n'avait pas listé : **l'API renvoie des messages de validation en clé brute**.
Vérifié sur ce dépôt : `trans('validation.min.string')` → `"validation.min.string"` (aucun
fichier `lang/fr` n'est fourni). L'application affiche donc ce texte-là à l'utilisateur
(`apiErrorMessage` remonte le premier message de `errors`).

**La règle :** un titre d'annonce doit faire **au moins 10 caractères** (aujourd'hui 4).
**Le texte :** le message affiché devient une phrase française.

### Étape 1 — écrire le test d'abord (rouge)

À la fin de `backend/tests/Feature/MyListingTest.php` :

```php
it('demande un titre de dix caracteres minimum, avec un message en francais', function () {
    $refs = seededReferences();
    $user = User::factory()->create();

    $this->actingAs($user)
        ->postJson('/api/v1/listings', listingPayload([...$refs, 'title' => 'Plombier']))
        ->assertStatus(422)
        ->assertJsonValidationErrors(['title'])
        ->assertJsonPath('errors.title.0', 'Le titre doit contenir au moins 10 caractères.');

    expect(Listing::where('user_id', $user->id)->exists())->toBeFalse();
});
```

```bash
php artisan test --filter="demande un titre"
```

Attendu : **échec** (l'API renvoie 201, « Plombier » fait 8 caractères mais dépasse le
minimum actuel de 4). C'est le moment de dire : « le test décrit le comportement voulu ;
il échoue parce que le code ne le fait pas encore ».

### Étape 2 — la règle et le texte

Dans `backend/app/Http/Controllers/Api/V1/MyListingController.php` :

1. `rules()` — la règle :

```php
            'title' => ['required', 'string', 'min:10', 'max:140'],
```

2. **les deux** appels de validation (dans `store()` et dans `update()`) :

```php
        $data = $request->validate($this->rules(), $this->messages());
```

3. une méthode privée, à côté de `rules()` :

```php
    /**
     * Messages affichés tels quels par l'application (F-03). Sans eux, le
     * serveur renvoie la clé brute « validation.min.string » : aucun fichier
     * lang/fr n'est fourni dans ce dépôt.
     *
     * @return array<string, string>
     */
    private function messages(): array
    {
        return [
            'title.min' => 'Le titre doit contenir au moins 10 caractères.',
            'title.max' => 'Le titre ne peut pas dépasser 140 caractères.',
        ];
    }
```

### Étape 3 — vert

```bash
php artisan test --filter="demande un titre"     # 1 passed
```

### Étape 4 — la suite entière

Lancez-la **dans un second terminal au début de l'étape 2** (elle prend ~2 min) : vous
continuez à parler pendant qu'elle tourne, puis vous revenez dessus.

```bash
cd backend && php artisan test        # 75 passed
php vendor/bin/pint --test            # style OK (sinon : php vendor/bin/pint)
php vendor/bin/phpstan analyse        # aucune erreur
```

Le test existant `rejects an invalid listing with comprehensible errors` continue de passer :
aucun titre de test n'est plus court que 10 caractères (le plus court fait 14).

**Répétition faite le 6 nov. 2026, chronomètre en main (puis code remis à l'état d'origine) :**
rouge en **2 s** (`Expected response status code [422] but received 201`), vert en **1,4 s**,
fichier `MyListingTest.php` complet **6 tests / 35 assertions en 1,9 s**, `pint --test` et
PHPStan propres sur les deux fichiers. La séquence tient donc en moins de 4 minutes, frappe
comprise — c'est jouable, mais gardez la suite complète pour la fin.

### Variante courte (si le temps manque)

Sautez l'étape « règle » et ne faites que le **message** (`min:4` inchangé + `messages()`).
Le test s'écrit alors avec un titre de 3 caractères (`'Ab'`), et l'histoire reste la même :
« le serveur renvoyait une clé technique, l'utilisateur doit lire une phrase ».

### Variante complète (si on vous pousse côté app)

Cohérence du garde-fou client, dans `app/lib/src/features/account/my_listings_page.dart`
(lignes 408-409) :

```dart
    if (title.length < 10 || description.length < 10) {
      setState(() => _error = 'Titre (10 caractères min.) et description (10 caractères min.) obligatoires.');
```

Puis `cd app && flutter analyze && flutter test`. Ne reconstruisez pas le bundle web pour
ça pendant la séance : le serveur reste la source de vérité.

### Pièges de cette séquence

- **Oublier `update()`** : la règle ne s'appliquerait qu'à la création. Un examinateur
  attentif le verra. Les deux appels, toujours.
- **Écrire le test après le code** : vous perdez la démonstration de la méthode (rouge →
  vert), qui est justement ce qui est évalué.
- **Lancer la suite complète à la fin sans avoir prévenu** : 2 minutes de silence. Prévenez,
  ou lancez-la en parallèle.
- **`composer test`** : indisponible sur ce poste. Utilisez `php artisan test`.

---

## 8. Questions probables, réponses courtes

| Question | Réponse à donner |
|---|---|
| « Pourquoi deux bases ? » | Production = MySQL ; paquet desktop = SQLite embarquée (aucune installation). Même code, même migrations. |
| « Combien de tests ? » | 74 côté serveur (722 assertions), 25 côté Flutter, plus Pint et PHPStan niveau 5. La CI les rejoue à chaque push. |
| « Et si je n'ai pas XAMPP ? » | L'API a besoin d'une base : MySQL, SQLite ou le paquet desktop qui embarque la sienne. Le paquet `Soutrali-win64` ne demande rien. |
| « Les conversations sont-elles chiffrées ? » | En transit oui (TLS) ; en base non — l'accès est contrôlé par autorisation. Le chiffrement de bout en bout n'est pas au périmètre du MVP, et je préfère le dire. |
| « Qui peut lire les messages ? » | Les deux participants. Les modérateurs en lecture seule, pour un litige, avec trace. |
| « Pourquoi un back-office Filament ? » | Modération, référentiels (catégories, communes), comptes. Les fils s'y consultent mais ne s'y modifient pas : la messagerie vit dans l'application. |
| « Pourquoi les livrables ne sont pas dans Git ? » | Ils y étaient — c'est une erreur signalée, corrigée : 165 Mo dans un dépôt, ce n'est pas un dépôt, c'est une archive. Ils passent en Release. |
| « Votre compte admin de démo ? » | Il n'existe qu'en local et ne doit jamais partir dans un livrable ; en production il est créé par `soutrali:create-admin`, mot de passe saisi masqué. |
| « Ce qu'il reste à faire ? » | Maquettes Phase 3, CGU (D-10), sauvegardes, validation DNS Mailjet, découpage de `discover_page.dart`, messages de validation en français sur tous les champs. |
| « Pourquoi `discover_page.dart` si gros ? » | Dette assumée : écran unique de l'accueil. Plan de découpage en 4 widgets, tests verts à chaque étape. |

---

## 9. Incidents et plan B

| Symptôme | Cause probable | Geste |
|---|---|---|
| Port 8000 occupé (`Address already in use`) | ancien `php artisan serve` | `taskkill /PID <n> /T /F` puis relancer |
| `SQLSTATE[HY000] [2002]` | MySQL de XAMPP arrêté | démarrer MySQL, relancer la commande |
| Site en ligne lent ou 500 | hébergement mutualisé | basculer sur `http://127.0.0.1:8082` (bundle local) |
| `/admin` boucle sur le login | mauvais rôle ou cache de session | se connecter avec le compte `ADMINISTRATEUR` créé par `soutrali:create-admin` |
| Un test échoue pendant la démo | modification incomplète | lire l'assertion, corriger devant lui : c'est une démonstration, pas un spectacle |
| Plus de réseau | — | vidéo du parcours enregistrée la veille |

---

## 10. Après la séance

```bash
cd backend && php artisan test && php vendor/bin/pint --test && php vendor/bin/phpstan analyse
cd ../app && flutter analyze && flutter test
```

Puis, selon la règle du dépôt (`AGENTS.md`) :
entrée dans `docs/SUIVI_DEVELOPPEMENT.md` (fait / vérifié / reste), `README.md` §6.1 si la
liste des fonctionnalités change, et commit en français à l'impératif, poussé sur
`origin/main` pour que local et distant restent au même niveau d'information.

---

## 11. À ne pas faire, à ne pas dire

- Ne dites pas « c'est fini » : dites « le MVP est livré, voici les dettes connues ». La
  liste du §2 est votre meilleure preuve de sérieux, pas une faiblesse.
- Ne montrez pas le compte `admin.demo` / `password`.
- Ne lancez pas une commande dont vous ne savez pas ce qu'elle fait : `migrate:fresh`,
  `--force`, `git reset --hard` n'ont rien à faire dans une démo.
- Ne cachez pas un échec de test en le relançant jusqu'à ce qu'il passe : lisez-le.
- Ne parlez pas de l'assistant IA pendant la séance : le cadre est « sans assistant », et
  le sujet est votre maîtrise du code.
