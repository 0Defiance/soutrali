/// Plateforme de l'application :
/// - **web** : `runtime_stub.dart` — le navigateur gère les cookies de
///   session et l'en-tête `Origin` de lui-même, aucun backend embarqué ;
/// - **desktop / Android** (`dart:io`) : `runtime_io.dart` — démarrage du
///   backend local embarqué (phase 2 tout-en-un), cookies de session
///   persistants et en-tête `Origin` explicite (Sanctum ne démarre une
///   session que pour les domaines « stateful »).
library;

export 'runtime_stub.dart'
    if (dart.library.io) 'runtime_io.dart';
