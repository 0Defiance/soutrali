# Livrables de test Soutrali

Prêts à l'emploi, **sans rien installer**. Le paquet desktop fonctionne en
local ; l'APK Android pointe vers l'API en ligne
`https://soutrali.alwaysdata.net`.

> **Téléchargement :** les archives ne sont **plus versionnées dans le dépôt**
> (165 Mo, corrigé le 6 nov. 2026). Elles sont publiées dans les
> **Releases GitHub** du projet :
> <https://github.com/0Defiance/soutrali/releases/latest>.
> Ne pas committer d'archive ici : `livrables/*.zip` et `livrables/*.apk`
> sont ignorés par Git.

| Fichier | Taille | Contenu |
|---|---|---|
| [`Soutrali-win64-1-backend.zip`](https://github.com/0Defiance/soutrali/releases/latest/download/Soutrali-win64-1-backend.zip) | 61,9 Mo | Backend Laravel complet (`backend/` : API + back-office `/admin`, vendor compris) |
| [`Soutrali-win64-2-runtime.zip`](https://github.com/0Defiance/soutrali/releases/latest/download/Soutrali-win64-2-runtime.zip) | 35,3 Mo | PHP portable (`runtime/php/`) : aucun PHP à installer |
| [`Soutrali-win64-3-programme.zip`](https://github.com/0Defiance/soutrali/releases/latest/download/Soutrali-win64-3-programme.zip) | 13,4 Mo | `soutrali.exe`, ses DLL et `data/` (interface Flutter) |
| [`soutrali-android.apk`](https://github.com/0Defiance/soutrali/releases/latest/download/soutrali-android.apk) | 59,0 Mo | Application Android signée (`CN=Soutrali`), compilée avec l'API en ligne gravée |

> Le paquet desktop est découpé en 3 zip pour rester sous la limite de
> 100 Mo par fichier de GitHub. Les 3 parties se complètent : extraites
> dans le même dossier, elles reconstituent exactement le paquet d'origine
> (vérifié le 28 oct. 2026 : 18 577 fichiers, empreintes SHA-256
> identiques à `dist/Soutrali-win64/`).

## Tester le desktop (Windows, sans rien installer)

1. Créer un dossier vide, par exemple `C:\Soutrali`.
2. **Extraire les 3 zip dans ce dossier** (clic droit → « Tout extraire »,
   répéter pour chaque zip) : l'arborescence `Soutrali-win64/` se
   complète à chaque extraction.
3. Ouvrir le dossier `Soutrali-win64` et double-cliquer sur
   **`soutrali.exe`**.
4. L'application démarre : le backend local (PHP embarqué + base SQLite
   pré-migrée) répond en quelques secondes, puis l'interface s'affiche.

Première exécution : Windows SmartScreen peut afficher un avertissement
(exécutable non signé) → **Plus d'informations → Exécuter quand même**.

Le paquet ne contient **aucun compte de démonstration** : l'administrateur du
back-office se crée à la première utilisation avec
`php artisan soutrali:create-admin <email>` (mot de passe saisi masqué).

## Tester l'APK Android

1. Copier `soutrali-android.apk` sur le téléphone (câble, Bluetooth ou
   téléversement) et ouvrir le fichier.
2. Autoriser les « sources inconnues » si Android le demande.
3. L'application se connecte à `https://soutrali.alwaysdata.net` : le
   parcours inscription → recherche → publication se fait contre la base
   en ligne.

## Régénérer les livrables

```bash
# Paquet desktop (nécessite dist/Soutrali-win64/ assemblé au préalable
# par desktop/build-package.ps1)
php build-livrables.php

# APK (API en ligne gravée)
cd app && flutter build apk --release --dart-define=API_BASE_URL=https://soutrali.alwaysdata.net
```

`build-livrables.php` recrée les 3 zip et recopie l'APK dans `livrables/` ;
ces fichiers sont ignorés par Git et se joignent à une **Release** :
`gh release create v0.2.0 livrables/*.zip livrables/*.apk` (ou
**Releases → Draft a new release** sur GitHub).
