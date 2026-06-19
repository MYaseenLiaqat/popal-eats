import 'package:shared_preferences/shared_preferences.dart';

/// Persists first-launch privacy and location onboarding flags.
class AppConsentStorage {
  static const _privacyKey = 'privacy_consent_accepted_v1';
  static const _locationKey = 'location_onboarding_completed_v1';

  static Future<bool> hasPrivacyConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_privacyKey) ?? false;
  }

  static Future<void> setPrivacyConsent(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_privacyKey, value);
  }

  static Future<bool> hasLocationOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_locationKey) ?? false;
  }

  static Future<void> setLocationOnboardingCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_locationKey, value);
  }
}
