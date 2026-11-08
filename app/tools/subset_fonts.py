"""Réduit les polices embarquées à ce que l’application affiche réellement.

Les deux familles de la charte sont des polices **variables** téléchargées
depuis Google Fonts : Manrope (742 glyphes) et Source Sans 3 (2 478 glyphes).
L’application n’écrit qu’en français, avec des chiffres et de la ponctuation
typographique. Embarquer le jeu complet coûtait 811 Ko à chaque visite ; le
sous-ensemble ci-dessous n’en garde que les caractères utilisés, en conservant
l’axe de graisse (wght 200-800/900) pour que tous les poids restent disponibles.

Usage : `python tools/subset_fonts.py` depuis `app/`.
"""

from pathlib import Path

from fontTools import subset

# Latin de base + latin-1 (accents français, ° ± « » · ×) + Œ/œ/Ÿ,
# apostrophes typographiques, tirets, points de suspension, €, •, → et ÷.
UNICODES = (
    "U+0020-007E,U+00A0-00FF,U+0152-0153,U+0178,U+02BC,"
    "U+2013-2014,U+2018-201D,U+2022,U+2026,U+20AC,U+2192"
)

FONTS = ("assets/fonts/Manrope.ttf", "assets/fonts/SourceSans3.ttf")


def main() -> None:
    for path in FONTS:
        font = Path(path)
        before = font.stat().st_size

        options = subset.Options()
        options.layout_features = ["*"]
        options.name_IDs = ["*"]
        options.notdef_outline = True
        options.recalc_bounds = True
        options.retain_gids = False

        subsetter = subset.Subsetter(options=options)
        subsetter.populate(unicodes=subset.parse_unicodes(UNICODES))
        font_file = subset.load_font(str(font), options)
        subsetter.subset(font_file)
        subset.save_font(font_file, str(font), options)
        font_file.close()

        after = font.stat().st_size
        print(f"{path} : {before} -> {after} octets")


if __name__ == "__main__":
    main()
