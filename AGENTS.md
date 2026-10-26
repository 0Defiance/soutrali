# AGENTS.md — règle de travail sur Soutrali

Ce fichier fixe la **définition de « fait »** appliquée à chaque nouvelle
fonctionnalité de ce dépôt. Aucune intervention n'est considérée terminée tant
que les trois points ci-dessous ne sont pas satisfaits.

## 1. Accessible

Une fonctionnalité n'existe que si l'on y arrive par le chemin normal de
l'utilisateur, sans modifier le code pour l'atteindre :

- **Flutter (`app/`)** : route enregistrée dans `app/lib/src/app.dart` **et**
  point d'entrée visible (menu, bouton, lien) depuis un écran déjà
  accessible ; l'écran s'affiche sans flag de debug ni activation manuelle.
- **API (`backend/`)** : route déclarée dans `backend/routes/api.php` et
  appelable en HTTP avec les mêmes paramètres que ceux que l'app envoie.
- **Back-office** : la ressource Filament est présente dans le menu `/admin`
  et ses actions s'exécutent réellement.

Vérification concrète : atteindre la fonctionnalité dans l'app ou avec `curl`
en suivant uniquement les chemins décrits dans `docs/INSTALLATION.md`.

## 2. Testable directement

Chaque nouveau comportement est couvert par un test intégré à la suite
existante — on n'ajoute jamais un second outil de test :

| Couche | Fichier | Commande |
|---|---|---|
| API, modèle, back-office | `backend/tests/Feature/…Test.php` | `cd backend && composer test` |
| Écrans et logique Flutter | `app/test/…_test.dart` | `cd app && flutter test` |

Le test reproduit l'usage réel : un appel HTTP authentifié sur la route avec
assertions de statut **et** de contenu, ou un parcours de widgets qui
navigue jusqu'à l'écran. Un test d'une fonction privée sans route ni écran
ne suffit pas.

## 3. Vérifier, documenter, commiter

Mêmes commandes que la CI (`.github/workflows/ci.yml`), à exécuter avant
chaque commit :

```bash
cd backend && composer test && composer format:check && composer analyse
cd app && flutter analyze && flutter test
```

Vérification visuelle : après `cd app && flutter build web --release` servi par
`python -m http.server 8082 --directory app/build/web`, le serveur statique
n'envoie aucun en-tête `Cache-Control` — le navigateur conserve donc l'ancien
bundle. **Ctrl+F5 après chaque recompilation**, sinon l'on regarde une version
antérieure du site.

Documentation : entrée dans `docs/SUIVI_DEVELOPPEMENT.md` (fait / vérifié /
reste) et, si la liste des fonctionnalités change, `README.md` §6.1.

Commit : sujet en français à l'impératif, dans le style de `git log`
(`Implémenter …`, `Ajouter …`, `Documenter …`), puis pousser sur `origin/main`
— l'objectif permanent reste un dépôt local et distant **au même niveau
d'information**.