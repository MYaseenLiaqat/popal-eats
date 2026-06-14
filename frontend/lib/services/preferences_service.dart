import 'api_client.dart';
import '../models/onboarding_option.dart';

class PreferencesService {
  PreferencesService({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<OnboardingOptions> getOnboardingOptions() async {
    final response = await _client.get('/preferences/onboarding/options');
    _client.throwIfError(response);
    return OnboardingOptions.fromJson(_client.decodeJson(response));
  }

  Future<OnboardingStatus> getOnboardingStatus() async {
    final response = await _client.get('/preferences/onboarding/status');
    _client.throwIfError(response);
    return OnboardingStatus.fromJson(_client.decodeJson(response));
  }

  Future<OnboardingStatus> skipOnboarding() async {
    final response = await _client.post('/preferences/onboarding/skip');
    _client.throwIfError(response);
    return OnboardingStatus.fromJson(_client.decodeJson(response));
  }

  Future<OnboardingStatus> completeOnboarding({
    required List<String> favoriteCuisines,
    required List<String> allergies,
  }) async {
    final response = await _client.post(
      '/preferences/onboarding',
      body: {
        'favorite_cuisines': favoriteCuisines,
        'allergies': allergies,
      },
    );
    _client.throwIfError(response);
    final json = _client.decodeJson(response);
    return OnboardingStatus(completed: json['completed'] == true);
  }
}
