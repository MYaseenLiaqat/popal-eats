import 'package:flutter/foundation.dart';

/// Startup and runtime diagnostics for Google Maps on web.
abstract final class GoogleMapsDiagnostics {
  static bool keyDetected = false;
  static bool jsApiLoaded = false;
  static bool mapsInitialized = false;
  static bool fallbackActivated = false;

  static String? lastError;
  static String? lastHint;

  /// Log a single diagnostic line (visible in debug console / browser devtools).
  static void log(String message) {
    if (kDebugMode) {
      debugPrint('[GoogleMaps] $message');
    }
  }

  static void logWarning(String message) {
    if (kDebugMode) {
      debugPrint('[GoogleMaps] ⚠ $message');
    }
  }

  static void resetForRetry() {
    jsApiLoaded = false;
    mapsInitialized = false;
    lastError = null;
    lastHint = null;
  }

  static void markKeyMissing() {
    keyDetected = false;
    jsApiLoaded = false;
    mapsInitialized = false;
    fallbackActivated = true;
    lastError = 'GOOGLE_MAPS_WEB_API_KEY not provided.';
    log('Google Maps disabled: GOOGLE_MAPS_WEB_API_KEY not provided.');
  }

  static void markKeyDetected() {
    keyDetected = true;
    log('Google Maps API key detected.');
  }

  static void markJsApiLoaded() {
    jsApiLoaded = true;
    log('Maps JavaScript API loaded.');
  }

  static void markMapsInitialized() {
    mapsInitialized = true;
    fallbackActivated = false;
    log('Google Maps initialized successfully.');
  }

  static void markFallback({required String reason, String? hint}) {
    mapsInitialized = false;
    fallbackActivated = true;
    lastError = reason;
    lastHint = hint;
    logWarning(reason);
    if (hint != null && hint.isNotEmpty) {
      log('Hint: $hint');
    }
  }

  static void classifyAndMarkFailure(String rawMessage) {
    final lower = rawMessage.toLowerCase();

    if (_matchesAny(lower, ['invalidkey', 'invalid key', 'invalid api key'])) {
      markFallback(
        reason: 'Invalid Google Maps API key.',
        hint: 'Check GOOGLE_MAPS_WEB_API_KEY and key restrictions in Google Cloud Console.',
      );
      return;
    }

    if (_matchesAny(lower, [
      'apinotactivated',
      'api not activated',
      'not enabled',
      'servicenotenabled',
    ])) {
      markFallback(
        reason: 'Maps JavaScript API is not enabled for this key.',
        hint: 'Enable "Maps JavaScript API" for your project in Google Cloud Console.',
      );
      return;
    }

    if (_matchesAny(lower, [
      'billingnotenabled',
      'billing not enabled',
      'billing',
      'enable billing',
    ])) {
      markFallback(
        reason: 'Google Maps billing is not enabled for this project.',
        hint: 'Link a billing account in Google Cloud Console — Maps requires an active billing account.',
      );
      return;
    }

    if (_matchesAny(lower, ['referernotallowed', 'referer not allowed', 'referrer'])) {
      markFallback(
        reason: 'Google Maps API key referrer restriction blocked this app.',
        hint: 'Add your localhost / deployment origin to the key\'s HTTP referrer allowlist.',
      );
      return;
    }

    markFallback(
      reason: 'Google Maps failed to initialize.',
      hint: rawMessage.isNotEmpty ? rawMessage : 'See browser console for details.',
    );
  }

  static bool _matchesAny(String haystack, List<String> needles) {
    for (final needle in needles) {
      if (haystack.contains(needle)) return true;
    }
    return false;
  }

  /// Prints the startup diagnostic summary requested for developer experience.
  static void logStartupReport() {
    if (!kDebugMode) return;

    log('── Startup diagnostic ──');
    log('Key detected?        ${keyDetected ? 'yes' : 'no'}');
    log('JS API loaded?       ${jsApiLoaded ? 'yes' : 'no'}');
    log('Maps initialized?    ${mapsInitialized ? 'yes' : 'no'}');
    log('Fallback activated?  ${fallbackActivated ? 'yes' : 'no'}');
    if (lastError != null) {
      log('Last error:          $lastError');
    }
    if (lastHint != null) {
      log('Hint:                $lastHint');
    }
    log('──────────────────────');
  }
}
