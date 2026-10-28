# Livrables de test Soutrali

Prêts à l'emploi, **sans rien installer**. Le paquet desktop fonctionne en
local ; l'APK Android pointe vers l'API en ligne
`https://soutrali.alwaysdata.net`.

| Fichier | Taille | Contenu |
|---|---|---|
| `Soutrali-win64-1-backend.zip` | 61,9 Mo | Backend Laravel complet (`backend/` : API + back-office `/admin`, vendor compris) |
| `Soutrali-win64-2-runtime.zip` | 35,3 Mo | PHP portable (`runtime/php/`) : aucun PHP à installer |
| `Soutrali-win64-3-programme.zip` | 13,4 Mo | `soutrali.exe`, ses DLL et `data/` (interface Flutter) |
| `soutrali-android.apk` | 59,0 Mo | Application Android signée (`CN=Soutrali`), compilée avec l'API en ligne gravée |

> Le paquet desktop est découpé en 3 zip pour respecter la limite de
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

`build-livrables.php` recrée les 3 zip et recopie l'APK ; chaque partie
restant sous 100 Mo, elle est committée telle quelle.
