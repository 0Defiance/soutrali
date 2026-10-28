<?php

/**
 * Génère les icônes et favicons de la marque à partir du logo source
 * (README §15.7) : icônes web Flutter, favicon du back-office (PNG et
 * ICO multi-tailles).
 *
 * Usage : php brand/generate-icons.php
 *
 * Couvre le web, le back-office et les icônes de lancement Android
 * (app/android/.../mipmap-*).
 *
 * Le symbole (le « S » entrelacé) est extrait automatiquement : c’est la
 * variante exigée par la charte §15.2 pour les petites zones (le mot-
 * symbole complet serait illisible sous 140 px). Le fond ivoire reprend
 * la couleur de page de la charte (#FFF9F2).
 *
 * À relancer si le logo source est retravaillé (D-02).
 */

declare(strict_types=1);

$root = dirname(__DIR__);
$source = $root.'/brand/logo/soutrali-logo-couleurs.png';

if (! is_file($source)) {
    fwrite(STDERR, "Logo source introuvable : {$source}\n");
    exit(1);
}

$logo = imagecreatefrompng($source);
if ($logo === false) {
    fwrite(STDERR, "Lecture du logo impossible.\n");
    exit(1);
}

$width = imagesx($logo);
$height = imagesy($logo);
$corner = imagecolorat($logo, 0, 0);
$cornerTransparent = (($corner >> 24) & 0x7F) > 100;

/** Un pixel porte-t-il du contenu (par rapport au fond de coin) ? */
$hasContent = static function (int $x, int $y) use ($logo, $corner, $cornerTransparent): bool {
    $pixel = imagecolorat($logo, $x, $y);
    $alpha = ($pixel >> 24) & 0x7F;

    if ($alpha > 100) {
        return false; // pixel transparent : rien à dessiner.
    }

    if ($cornerTransparent) {
        return $alpha < 60; // contenu opaque sur fond transparent.
    }

    $dr = abs((($pixel >> 16) & 0xFF) - (($corner >> 16) & 0xFF));
    $dg = abs((($pixel >> 8) & 0xFF) - (($corner >> 8) & 0xFF));
    $db = abs(($pixel & 0xFF) - ($corner & 0xFF));

    return ($dr + $dg + $db) > 40;
};

// Cadrage du symbole : les rangées supérieures jusqu’au mot-symbole,
// qui commence à ~53,4 % de la hauteur du logo source. Mesuré sur le
// logo du 19 oct. 2026 ; à remesurer si le logo est retravaillé.
$scanLimit = (int) ($height * 0.534);
$left = $width;
$right = 0;
$top = $height;
$bottom = 0;

for ($y = 0; $y < $scanLimit; $y++) {
    for ($x = 0; $x < $width; $x++) {
        if ($hasContent($x, $y)) {
            $left = min($left, $x);
            $right = max($right, $x);
            $top = min($top, $y);
            $bottom = max($bottom, $y);
        }
    }
}

if ($right <= $left || $bottom <= $top) {
    fwrite(STDERR, "Aucun contenu détecté dans le haut du logo.\n");
    exit(1);
}

if (($right - $left) > ($width * 0.7)) {
    // Filet de sécurité : le cadrage déborde sur le mot-symbole →
    // le seuil de 53,4 % doit être remesuré sur le nouveau logo.
    fwrite(STDERR, "Le cadrage du symbole déborde (".($right - $left)." px sur {$width}) : seuil à remesurer.\n");
    exit(1);
}

$symbol = imagecrop($logo, [
    'x' => $left,
    'y' => $top,
    'width' => $right - $left + 1,
    'height' => $bottom - $top + 1,
]);

if ($symbol === false) {
    fwrite(STDERR, "Extraction du symbole impossible.\n");
    exit(1);
}

// Le logo source a un fond blanc cassé (#FEFEFE) : on le recolore en
// ivoire de charte (#FFF9F2) pour éviter un rectangle blanc visible.
for ($y = 0; $y < imagesy($symbol); $y++) {
    for ($x = 0; $x < imagesx($symbol); $x++) {
        $pixel = imagecolorat($symbol, $x, $y);
        $distance = abs((($pixel >> 16) & 0xFF) - 0xFE)
            + abs((($pixel >> 8) & 0xFF) - 0xFE)
            + abs(($pixel & 0xFF) - 0xFE);

        if ($distance <= 30) {
            imagesetpixel($symbol, $x, $y, 0xFFF9F2);
        }
    }
}

printf(
    "Symbole extrait : %dx%d dans un logo de %dx%d.\n",
    imagesx($symbol),
    imagesy($symbol),
    $width,
    $height,
);

/**
 * Carré ivoire + symbole centré, sans déformation.
 *
 * @return GdImage
 */
$render = static function (int $size, float $ratio) use ($symbol): GdImage {
    $canvas = imagecreatetruecolor($size, $size);
    $ivory = imagecolorallocate($canvas, 0xFF, 0xF9, 0xF2);
    imagefilledrectangle($canvas, 0, 0, $size, $size, $ivory);

    $box = (int) round($size * $ratio);
    $scale = min($box / imagesx($symbol), $box / imagesy($symbol));
    $drawWidth = (int) round(imagesx($symbol) * $scale);
    $drawHeight = (int) round(imagesy($symbol) * $scale);
    $drawX = (int) round(($size - $drawWidth) / 2);
    $drawY = (int) round(($size - $drawHeight) / 2);

    imagecopyresampled(
        $canvas,
        $symbol,
        $drawX,
        $drawY,
        0,
        0,
        $drawWidth,
        $drawHeight,
        imagesx($symbol),
        imagesy($symbol),
    );

    return $canvas;
};

$targets = [
    // [chemin, taille, ratio du symbole] — 64 % icône classique,
    // 54 % sous masque circulaire (zone de sécurité), 80 % favicon.
    [$root.'/app/web/favicon.png', 64, 0.80],
    [$root.'/app/web/icons/Icon-192.png', 192, 0.64],
    [$root.'/app/web/icons/Icon-512.png', 512, 0.64],
    [$root.'/app/web/icons/Icon-maskable-192.png', 192, 0.54],
    [$root.'/app/web/icons/Icon-maskable-512.png', 512, 0.54],
    [$root.'/backend/public/favicon.png', 64, 0.80],
    // Lanceur Android (plateforme ajoutée le 28 oct. 2026) : les cinq
    // densités mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi. Android arrondit l’icône
    // lui-même (forme « ronde » par défaut) : pas de cadrage circulaire
    // à prévoir ici.
    [$root.'/app/android/app/src/main/res/mipmap-mdpi/ic_launcher.png', 48, 0.64],
    [$root.'/app/android/app/src/main/res/mipmap-hdpi/ic_launcher.png', 72, 0.64],
    [$root.'/app/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png', 96, 0.64],
    [$root.'/app/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png', 144, 0.64],
    [$root.'/app/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png', 192, 0.64],
];

foreach ($targets as [$path, $size, $ratio]) {
    $image = $render($size, $ratio);

    if (! imagepng($image, $path)) {
        fwrite(STDERR, "Écriture impossible : {$path}\n");
        exit(1);
    }

    imagedestroy($image);
    echo basename($path)." ({$size} px)\n";
}

// ICO (conteneur PNG, accepté par tous les navigateurs modernes) :
// 32 px et 16 px pour onglets et raccourcis.
$icoSizes = [32, 16];
$blobs = [];

foreach ($icoSizes as $size) {
    $image = $render($size, 0.84);
    ob_start();
    imagepng($image);
    $blobs[] = (string) ob_get_clean();
    imagedestroy($image);
}

$ico = pack('vvv', 0, 1, count($icoSizes));
$offset = 6 + (16 * count($icoSizes));

foreach ($icoSizes as $index => $size) {
    $entry = $size >= 256 ? 0 : $size;
    $ico .= pack('CCCC', $entry, $entry, 0, 0)
        .pack('vv', 1, 32)
        .pack('VV', strlen($blobs[$index]), $offset);
    $offset += strlen($blobs[$index]);
}

foreach ($blobs as $blob) {
    $ico .= $blob;
}

$icoPath = $root.'/backend/public/favicon.ico';

if (file_put_contents($icoPath, $ico) === false) {
    fwrite(STDERR, "Écriture impossible : {$icoPath}\n");
    exit(1);
}

echo 'favicon.ico (32 + 16 px, '.strlen($ico)." octets)\n";
