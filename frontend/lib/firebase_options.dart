import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase options loaded from `--dart-define` at build time.
///
/// Example:
/// flutter run --dart-define=FIREBASE_API_KEY=... --dart-define=FIREBASE_APP_ID=...
class DefaultFirebaseOptions {
  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const _messagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const _storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const _webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  static bool get isConfigured =>
      _apiKey.isNotEmpty && _appId.isNotEmpty && _projectId.isNotEmpty;

  static FirebaseOptions get currentPlatform {
    if (!isConfigured) {
      throw UnsupportedError(
        'Firebase is not configured. Pass FIREBASE_* dart-defines or use email signup.',
      );
    }

    if (kIsWeb) {
      return FirebaseOptions(
        apiKey: _apiKey,
        appId: _appId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        authDomain: _authDomain.isNotEmpty ? _authDomain : '$_projectId.firebaseapp.com',
        storageBucket: _storageBucket.isNotEmpty ? _storageBucket : '$_projectId.appspot.com',
      );
    }

    return FirebaseOptions(
      apiKey: _apiKey,
      appId: _appId,
      messagingSenderId: _messagingSenderId,
      projectId: _projectId,
      storageBucket: _storageBucket.isNotEmpty ? _storageBucket : '$_projectId.appspot.com',
      androidClientId: _webClientId.isNotEmpty ? _webClientId : null,
    );
  }
}
