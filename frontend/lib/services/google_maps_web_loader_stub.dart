import 'google_maps_diagnostics.dart';

/// Non-web platforms — Maps JS loader is not used.
class GoogleMapsWebLoader {
  GoogleMapsWebLoader._();

  static bool get isAvailable => false;

  static Future<void> ensureLoaded({bool force = false}) async {
    GoogleMapsDiagnostics.log(
      'Google Maps web loader skipped (native platform — uses google_maps_flutter).',
    );
  }
}
