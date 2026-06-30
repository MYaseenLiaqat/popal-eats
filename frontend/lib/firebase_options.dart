import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase options — dart-defines override embedded Android values from
/// `android/app/google-services.json` (project popal-eats-16b36).
class DefaultFirebaseOptions {
  // Embedded from google-services.json (com.example.popal_eats)
  static const _embeddedApiKey = 'AIzaSyDENXY90UA0mWWUTDmdpeiddGQ0Oz_B_5E';
  static const _embeddedAppId = '1:427158581376:android:e08914afc33ff7e26f7665';
  static const _embeddedMessagingSenderId = '427158581376';
  static const _embeddedProjectId = 'popal-eats-16b36';
  static const _embeddedStorageBucket = 'popal-eats-16b36.firebasestorage.app';
  static const embeddedWebClientId =
      '427158581376-o1jd1m4bem383gkoj7ji22sdnta6o98t.apps.googleusercontent.com';

  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const _messagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const _storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: embeddedWebClientId,
  );

  static bool get _hasDartDefines =>
      _apiKey.isNotEmpty && _appId.isNotEmpty && _projectId.isNotEmpty;

  static bool get _hasEmbeddedAndroid =>
      _embeddedApiKey.isNotEmpty &&
      _embeddedAppId.isNotEmpty &&
      _embeddedProjectId.isNotEmpty;

  /// True when Firebase can initialize on the current platform.
  static bool get isConfigured {
    if (_hasDartDefines) return true;
    if (!kIsWeb && _hasEmbeddedAndroid) return true;
    return false;
  }

  static String get _resolvedApiKey =>
      _apiKey.isNotEmpty ? _apiKey : _embeddedApiKey;

  static String get _resolvedAppId => _appId.isNotEmpty ? _appId : _embeddedAppId;

  static String get _resolvedMessagingSenderId => _messagingSenderId.isNotEmpty
      ? _messagingSenderId
      : _embeddedMessagingSenderId;

  static String get _resolvedProjectId =>
      _projectId.isNotEmpty ? _projectId : _embeddedProjectId;

  static String get _resolvedStorageBucket => _storageBucket.isNotEmpty
      ? _storageBucket
      : _embeddedStorageBucket;

  static FirebaseOptions get currentPlatform {
    if (!isConfigured) {
      throw UnsupportedError(
        'Firebase is not configured. Pass FIREBASE_* dart-defines (required for web) '
        'or add google-services.json for Android.',
      );
    }

    if (kIsWeb) {
      return FirebaseOptions(
        apiKey: _resolvedApiKey,
        appId: _resolvedAppId,
        messagingSenderId: _resolvedMessagingSenderId,
        projectId: _resolvedProjectId,
        authDomain: _authDomain.isNotEmpty
            ? _authDomain
            : '$_resolvedProjectId.firebaseapp.com',
        storageBucket: _resolvedStorageBucket,
      );
    }

    return FirebaseOptions(
      apiKey: _resolvedApiKey,
      appId: _resolvedAppId,
      messagingSenderId: _resolvedMessagingSenderId,
      projectId: _resolvedProjectId,
      storageBucket: _resolvedStorageBucket,
      androidClientId: webClientId.isNotEmpty ? webClientId : null,
    );
  }
}
