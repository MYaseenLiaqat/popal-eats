/// Central Google Maps configuration for Popal Eats.
///
/// Web: pass at run/build time:
/// `--dart-define=GOOGLE_MAPS_WEB_API_KEY=your_key_here`
///
/// Android/iOS continue to use native `google_maps_flutter` platform keys
/// (AndroidManifest / AppDelegate) — unchanged by this config.
abstract final class GoogleMapsConfig {
  /// Maps JavaScript API key for Flutter web only.
  static const String webApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_WEB_API_KEY',
    defaultValue: '',
  );

  static bool get isWebKeyConfigured =>
      webApiKey.isNotEmpty && webApiKey != 'YOUR_API_KEY';

  /// Core Maps JS endpoint — markers & polylines need no extra libraries.
  static String? get webMapsScriptUrl {
    if (!isWebKeyConfigured) return null;
    return 'https://maps.googleapis.com/maps/api/js?key=$webApiKey';
  }
}
