<?php

/**
 * Assemble les livrables de test dans ./livrables :
 *  - paquet desktop Soutrali-win64 découpé en 3 zip (backend / runtime /
 *    programme+data), chaque partie restant sous la limite de 100 Mo des
 *    fichiers Git ;
 *  - l'APK Android signé.
 *
 * Usage : php build-livrables.php
 */

declare(strict_types=1);

$racine = __DIR__;
$source = $racine.'/dist/Soutrali-win64';
$sortie = $racine.'/livrables';

if (! is_dir($source)) {
    fwrite(STDERR, "Paquet desktop absent : {$source}\n");
    exit(1);
}

@mkdir($sortie, 0777, true);

/**
 * Zippe un dossier ; le chemin conservé à l'intérieur est relatif à
 * $baseRel (dossier fantôme « Soutrali-win64/ » pour retrouver
 * l'arborescence d'origine en extrayant à côté).
 */
function zipDossier(string $dossier, string $zip, string $prefixe): int
{
    $z = new ZipArchive();
    if ($z->open($zip, ZipArchive::CREATE | ZipArchive::OVERWRITE) !== true) {
        throw new RuntimeException("Ouverture impossible : {$zip}");
    }

    $base = dirname($dossier);
    $it = new RecursiveIteratorIterator(
        new RecursiveDirectoryIterator($dossier, FilesystemIterator::SKIP_DOTS),
        RecursiveIteratorIterator::SELF_FIRST,
    );
    foreach ($it as $f) {
        $rel = str_replace('\\', '/', substr($f->getPathname(), strlen($base) + 1));
        if ($f->isDir()) {
            $z->addEmptyDir($prefixe.$rel);
        } else {
            $z->addFile($f->getPathname(), $prefixe.$rel);
        }
    }

    if (! $z->close()) {
        throw new RuntimeException("Fermeture impossible : {$zip}");
    }

    return (int) filesize($zip);
}

function zipFichiers(array $fichiers, string $zip, string $prefixe): int
{
    $z = new ZipArchive();
    if ($z->open($zip, ZipArchive::CREATE | ZipArchive::OVERWRITE) !== true) {
        throw new RuntimeException("Ouverture impossible : {$zip}");
    }
    foreach ($fichiers as $abs) {
        $rel = $prefixe.basename($abs);
        if (is_dir($abs)) {
            $it = new RecursiveIteratorIterator(
                new RecursiveDirectoryIterator($abs, FilesystemIterator::SKIP_DOTS),
                RecursiveIteratorIterator::SELF_FIRST,
            );
            foreach ($it as $f) {
                $sousRel = str_replace('\\', '/', substr($f->getPathname(), strlen($abs)));
                $cible = $rel.$sousRel;
                $f->isDir() ? $z->addEmptyDir($cible) : $z->addFile($f->getPathname(), $cible);
            }
            continue;
        }
        $z->addFile($abs, $rel);
    }
    if (! $z->close()) {
        throw new RuntimeException("Fermeture impossible : {$zip}");
    }

    return (int) filesize($zip);
}

$p = 'Soutrali-win64/';
$limite = 100_000_000; // limite GitHub par fichier (100 Mo)
$resultats = [];

$resultats["{$p}backend/  (API Laravel + vendor)"] =
    zipDossier($source.'/backend', $sortie.'/Soutrali-win64-1-backend.zip', $p);
$resultats["{$p}runtime/  (PHP portable)"] =
    zipDossier($source.'/runtime', $sortie.'/Soutrali-win64-2-runtime.zip', $p);

$racineFichiers = [];
foreach (scandir($source) ?: [] as $nom) {
    if ($nom === '.' || $nom === '..' || $nom === 'backend' || $nom === 'runtime') {
        continue;
    }
    $racineFichiers[] = $source.'/'.$nom;
}
$resultats["{$p}programme + data/  (soutrali.exe, DLL, data/)"] =
    zipFichiers($racineFichiers, $sortie.'/Soutrali-win64-3-programme.zip', $p);

// APK : simple copie (déjà signé et vérifié).
$apk = $racine.'/app/build/app/outputs/flutter-apk/app-release.apk';
$dest = $sortie.'/soutrali-android.apk';
if (! copy($apk, $dest)) {
    throw new RuntimeException("Copie APK impossible : {$apk}");
}
$resultats['soutrali-android.apk'] = (int) filesize($dest);

echo str_pad('Partie', 46).'  '.str_pad('Taille', 14)."\n";
foreach ($resultats as $nom => $octets) {
    $mo = number_format($octets / 1_000_000, 1, ',', ' ');
    $flag = $octets > $limite ? '  ⚠ DÉPASSE 100 Mo' : '';
    echo str_pad($nom, 46).'  '.str_pad($mo.' Mo', 14).$flag."\n";
}
