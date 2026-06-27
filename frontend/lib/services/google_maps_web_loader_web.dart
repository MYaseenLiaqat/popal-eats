import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;

import 'package:flutter/foundation.dart';

import '../config/google_maps_config.dart';
import 'google_maps_diagnostics.dart';

/// Loads the Google Maps JavaScript API once on web from [GoogleMapsConfig].
class GoogleMapsWebLoader {
  GoogleMapsWebLoader._();

  static bool _available = false;
  static bool _attempted = false;
  static Completer<void>? _inFlight;
  static bool _handlersInstalled = false;
  static StreamSubscription<html.Event>? _errorSubscription;

  static bool get isAvailable => _available;

  static Future<void> ensureLoaded({bool force = false}) async {
    if (!force && _attempted) {
      await (_inFlight?.future ?? Future.value());
      return;
    }

    if (force) {
      _attempted = false;
      _available = false;
      GoogleMapsDiagnostics.resetForRetry();
    }

    _attempted = true;
    _inFlight = Completer<void>();

    try {
      if (!GoogleMapsConfig.isWebKeyConfigured) {
        GoogleMapsDiagnostics.markKeyMissing();
        _available = false;
        return;
      }

      GoogleMapsDiagnostics.markKeyDetected();
      _installErrorHandlers();

      if (_isGoogleMapsReady()) {
        _available = true;
        GoogleMapsDiagnostics.markJsApiLoaded();
        GoogleMapsDiagnostics.markMapsInitialized();
        return;
      }

      final scriptUrl = GoogleMapsConfig.webMapsScriptUrl;
      if (scriptUrl == null) {
        GoogleMapsDiagnostics.markFallback(
          reason: 'Google Maps disabled: GOOGLE_MAPS_WEB_API_KEY not provided.',
        );
        _available = false;
        return;
      }

      final loaded = await _injectScript(scriptUrl);
      _available = loaded;

      if (loaded) {
        GoogleMapsDiagnostics.markJsApiLoaded();
        GoogleMapsDiagnostics.markMapsInitialized();
      } else if (!GoogleMapsDiagnostics.fallbackActivated) {
        GoogleMapsDiagnostics.markFallback(
          reason: 'Google Maps JavaScript API did not load in time.',
          hint: 'Check network connectivity and browser console for blocked requests.',
        );
      }
    } catch (e, st) {
      _available = false;
      GoogleMapsDiagnostics.classifyAndMarkFailure(e.toString());
      if (kDebugMode) {
        GoogleMapsDiagnostics.log('Unexpected loader error: $e\n$st');
      }
    } finally {
      if (!_available && !GoogleMapsDiagnostics.fallbackActivated) {
        GoogleMapsDiagnostics.markFallback(
          reason: 'Google Maps is unavailable — using fallback map.',
        );
      }
      _inFlight?.complete();
      _inFlight = null;
    }
  }

  static void _installErrorHandlers() {
    if (_handlersInstalled) return;
    _handlersInstalled = true;

    html.window.addEventListener('popal-gmaps-auth-failure', (html.Event _) {
      if (GoogleMapsDiagnostics.fallbackActivated) return;
      _available = false;
      GoogleMapsDiagnostics.markFallback(
        reason: 'Google Maps authentication failed.',
        hint: 'Common causes: invalid API key, Maps JavaScript API disabled, or billing not enabled.',
      );
    });

    final hook = html.ScriptElement()
      ..type = 'text/javascript'
      ..text = '''
(function() {
  window.gm_authFailure = function() {
    window.dispatchEvent(new Event('popal-gmaps-auth-failure'));
  };
})();
''';
    html.document.head?.append(hook);

    _errorSubscription ??= html.window.onError.listen((html.Event event) {
      if (event is! html.ErrorEvent) return;
      final message = event.message ?? '';
      if (!_looksLikeMapsError(message)) return;
      if (GoogleMapsDiagnostics.mapsInitialized) return;
      GoogleMapsDiagnostics.classifyAndMarkFailure(message);
      _available = false;
    });
  }

  static bool _looksLikeMapsError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('google maps') ||
        lower.contains('maps javascript api') ||
        lower.contains('invalidkey') ||
        lower.contains('apinotactivated') ||
        lower.contains('billing') ||
        lower.contains('gm_authfailure');
  }

  static bool _isGoogleMapsReady() {
    try {
      if (!js.context.hasProperty('google')) return false;
      final google = js.context['google'];
      if (google == null || google is! js.JsObject) return false;
      return google.hasProperty('maps');
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _injectScript(String url) async {
    final existing = html.document.querySelector('script[data-popal-google-maps]');
    if (existing != null) {
      return _waitForGoogleMaps();
    }

    final completer = Completer<bool>();
    final script = html.ScriptElement()
      ..src = url
      ..type = 'text/javascript'
      ..defer = true
      ..setAttribute('data-popal-google-maps', 'true');

    script.onLoad.listen((_) async {
      try {
        completer.complete(await _waitForGoogleMaps());
      } catch (_) {
        if (!completer.isCompleted) completer.complete(false);
      }
    });
    script.onError.listen((_) {
      if (completer.isCompleted) return;
      GoogleMapsDiagnostics.markFallback(
        reason: 'Failed to load Google Maps JavaScript API script.',
        hint: 'Verify the API key and that maps.googleapis.com is not blocked.',
      );
      completer.complete(false);
    });

    html.document.head?.append(script);

    try {
      return await completer.future.timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          if (!GoogleMapsDiagnostics.fallbackActivated) {
            GoogleMapsDiagnostics.markFallback(
              reason: 'Google Maps JavaScript API load timed out.',
              hint: 'The script may be blocked or the API key may be invalid.',
            );
          }
          return false;
        },
      );
    } catch (e) {
      GoogleMapsDiagnostics.classifyAndMarkFailure(e.toString());
      return false;
    }
  }

  static Future<bool> _waitForGoogleMaps() async {
    for (var i = 0; i < 40; i++) {
      if (_isGoogleMapsReady()) return true;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return false;
  }
}
