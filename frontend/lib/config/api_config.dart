/// Backend API configuration.
class ApiConfig {
  /// Android emulator: use 10.0.2.2:8000 — desktop/web: 127.0.0.1:8000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const Duration timeout = Duration(seconds: 30);
}
