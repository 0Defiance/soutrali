import 'dart:async';
import 'dart:js_interop';

import 'geolocation.dart';

@JS('navigator.geolocation')
external _Geolocation? get _navigatorGeolocation;

extension type _Geolocation._(JSObject _) implements JSObject {
  external void getCurrentPosition(JSFunction success, JSFunction error, JSAny options);
}

extension type _Coordinates._(JSObject _) implements JSObject {
  external double get latitude;
  external double get longitude;
  external double get accuracy;
}

extension type _Position._(JSObject _) implements JSObject {
  external _Coordinates get coords;
}

/// Position du navigateur (API `navigator.geolocation`).
///
/// Le navigateur demande l’accord de l’utilisateur ; un refus, une position
/// indisponible ou un délai dépassé renvoie `null` — l’application continue
/// sans localisation, sans jamais bloquer l’affichage des annonces.
class GeolocationService {
  const GeolocationService();

  bool get isSupported => _navigatorGeolocation != null;

  Future<GeoPosition?> current() {
    if (_navigatorGeolocation == null) {
      return Future.value(null);
    }

    final completer = Completer<GeoPosition?>();

    final options = {
      'enableHighAccuracy': true,
      'timeout': 12000,
      'maximumAge': 300000,
    }.jsify()!;

    _navigatorGeolocation!.getCurrentPosition(
      ((JSObject position) {
        if (completer.isCompleted) {
          return;
        }

        final coords = _Position._(position).coords;
        completer.complete(GeoPosition(
          latitude: coords.latitude,
          longitude: coords.longitude,
          accuracyMeters: coords.accuracy,
        ));
      }).toJS,
      ((JSObject _) {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      }).toJS,
      options,
    );

    return completer.future;
  }
}

GeolocationService createGeolocationService() => const GeolocationService();
