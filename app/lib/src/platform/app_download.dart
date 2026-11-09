import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/discover/listings_repository.dart';

/// Adresse de l’APK Android, servi par le site lui-même : même origine que
/// l’API, donc aucun service tiers à joindre pour installer l’application.
///
/// Le fichier vit dans `backend/public/downloads/` sur le serveur ; il n’entre
/// jamais dans le dépôt (voir `livrables/README.md`).
const apkDownloadUrl = '$apiBaseUrl/downloads/soutrali.apk';

/// Ouvre le téléchargement de l’APK dans le navigateur (web) ou la boutique de
/// fichiers du système. Rend `false` si aucun gestionnaire ne répond, pour que
/// l’écran puisse le dire au lieu de ne rien faire.
Future<bool> openApkDownload() async {
  try {
    return await launchUrl(
      Uri.parse(apkDownloadUrl),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    return false;
  }
}

/// Ouverture du téléchargement, remplaçable en test : les suites n’ont pas de
/// navigateur à ouvrir, mais elles vérifient bien l’adresse et le geste.
typedef ApkDownloader = Future<bool> Function();

final apkDownloaderProvider = Provider<ApkDownloader>((ref) => openApkDownload);
