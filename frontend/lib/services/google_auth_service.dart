import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_options.dart';

/// Firebase + Google Sign-In wrapper for Android and Web.
class GoogleAuthService {
  GoogleAuthService._();

  static final GoogleAuthService instance = GoogleAuthService._();

  bool _initialized = false;

  static bool get isConfigured => DefaultFirebaseOptions.isConfigured;

  Future<void> ensureInitialized() async {
    if (_initialized || !isConfigured) return;
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    _initialized = true;
  }

  GoogleSignIn _googleSignIn() {
    const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
    return GoogleSignIn(
      scopes: const ['email', 'profile'],
      clientId: kIsWeb && webClientId.isNotEmpty ? webClientId : null,
    );
  }

  Future<String?> signInAndGetIdToken() async {
    if (!isConfigured) {
      throw StateError('Firebase is not configured');
    }
    await ensureInitialized();

    final google = _googleSignIn();
    final account = await google.signIn();
    if (account == null) return null;

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken != null && idToken.isNotEmpty) {
      return idToken;
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );
    final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    return userCredential.user?.getIdToken();
  }

  Future<void> signOut() async {
    if (!isConfigured) return;
    try {
      await _googleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      // Best-effort sign out.
    }
  }
}
