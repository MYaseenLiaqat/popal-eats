import 'google_maps_web_loader_stub.dart'
    if (dart.library.html) 'google_maps_web_loader_web.dart' as impl;

import 'google_maps_diagnostics.dart';

/// Loads Google Maps JavaScript on web; no-op on other platforms.
abstract final class GoogleMapsWebLoader {
  static bool get isAvailable => impl.GoogleMapsWebLoader.isAvailable;

  static Future<void> ensureLoaded({bool force = false}) =>
      impl.GoogleMapsWebLoader.ensureLoaded(force: force);

  /// Read-only startup diagnostic flags for developer tooling.
  static bool get keyDetected => GoogleMapsDiagnostics.keyDetected;

  static bool get jsApiLoaded => GoogleMapsDiagnostics.jsApiLoaded;

  static bool get mapsInitialized => GoogleMapsDiagnostics.mapsInitialized;

  static bool get fallbackActivated => GoogleMapsDiagnostics.fallbackActivated;

  static void logStartupReport() => GoogleMapsDiagnostics.logStartupReport();
}
