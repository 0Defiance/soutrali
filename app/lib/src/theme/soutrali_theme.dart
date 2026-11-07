import 'package:flutter/material.dart';

abstract final class SoutraliColors {
  static const orange = Color(0xFFFE7402);
  static const green = Color(0xFF037C30);
  static const deepGreen = Color(0xFF0B5A2A);
  static const orangeText = Color(0xFFB24A00);
  static const ivory = Color(0xFFFFF9F2);
  static const ink = Color(0xFF1F2A24);
  static const muted = Color(0xFF5A6B62);
  static const paleGreen = Color(0xFFE8F5EC);
  static const paleOrange = Color(0xFFFFF0E0);
  static const border = Color(0xFFDCE5DF);
  static const danger = Color(0xFFB3261E);

  // Nuances ajoutées avec la refonte visuelle du 7 nov. 2026 : elles servent
  // aux dégradés et aux halos, jamais au texte sur fond clair.
  static const sun = Color(0xFFFFA45C);
  static const peach = Color(0xFFFFD9BC);
  static const forest = Color(0xFF064D26);
  static const mint = Color(0xFFD8EFE0);
  static const ivoryDeep = Color(0xFFFFF3E6);
}

/// Dégradés de marque partagés par les fonds, boutons et cartes.
abstract final class SoutraliGradients {
  /// Vert profond vers vert : fond du hero et des bandeaux.
  static const hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF053D1F), Color(0xFF0A6B33), Color(0xFF128043)],
    stops: [0, 0.55, 1],
  );

  /// Orange chaud : action principale, annonces « demande ».
  static const warm = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF8A1F), Color(0xFFFFB35C)],
  );

  /// Vert lumineux : prestations, offres.
  static const forest = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A6B33), Color(0xFF16A054)],
  );
}

/// Ombres douces : une seule gamme pour que les cartes se ressemblent.
abstract final class SoutraliShadows {
  static List<BoxShadow> soft({double alpha = 0.06, double blur = 26, double y = 12}) => [
        BoxShadow(
          color: SoutraliColors.ink.withValues(alpha: alpha),
          blurRadius: blur,
          offset: Offset(0, y),
        ),
      ];

  static List<BoxShadow> brand(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.28),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];
}

abstract final class SoutraliTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: SoutraliColors.green,
      brightness: Brightness.light,
      primary: SoutraliColors.green,
      secondary: SoutraliColors.orange,
      surface: Colors.white,
      error: SoutraliColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: SoutraliColors.ivory,
      // Charte §15.4 : Source Sans 3 au corps, Manrope pour les titres,
      // repli Arial/Helvetica obligatoire.
      fontFamily: 'Source Sans 3',
      fontFamilyFallback: const ['Arial', 'Helvetica', 'sans-serif'],
      textTheme: const TextTheme(
        displayMedium: TextStyle(
          fontFamily: 'Manrope',
          color: SoutraliColors.ink,
          fontSize: 44,
          height: 1.04,
          letterSpacing: -1.2,
          fontWeight: FontWeight.w800,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Manrope',
          color: SoutraliColors.ink,
          fontSize: 38,
          height: 1.08,
          letterSpacing: -0.8,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Manrope',
          color: SoutraliColors.ink,
          fontSize: 26,
          height: 1.16,
          letterSpacing: -0.4,
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Manrope',
          color: SoutraliColors.ink,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Manrope',
          color: SoutraliColors.ink,
          fontSize: 18,
          height: 1.25,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Manrope',
          color: SoutraliColors.ink,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(color: SoutraliColors.ink, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: SoutraliColors.muted, fontSize: 14, height: 1.45),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.1),
      ),
      // Champs arrondis : lignes douces plutôt que boîtes à angles vifs.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: SoutraliColors.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: SoutraliColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: SoutraliColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: SoutraliColors.green, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: SoutraliColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: SoutraliColors.danger, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: const BorderSide(color: SoutraliColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      // Dialogs (publication, profil, choix) : coins généreux, ombre neutre.
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      // Bandeaux : plus de ligne d’ombre Material, la marque porte l’ombre.
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: SoutraliColors.deepGreen,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontFamily: 'Manrope',
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: SoutraliColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      dividerTheme: const DividerThemeData(
        color: SoutraliColors.border,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: SoutraliColors.green,
        linearTrackColor: SoutraliColors.mint,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: SoutraliColors.ink,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12.5),
      ),
    );
  }
}