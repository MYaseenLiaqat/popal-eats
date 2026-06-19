import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/friends_provider.dart';
import 'providers/group_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/preferences_provider.dart';
import 'providers/reels_provider.dart';
import 'screens/location_permission_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/preference_onboarding_screen.dart';
import 'screens/privacy_consent_screen.dart';
import 'services/app_consent_storage.dart';
import 'services/google_auth_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (GoogleAuthService.isConfigured) {
    try {
      await GoogleAuthService.instance.ensureInitialized();
    } catch (_) {
      // Firebase dart-defines missing or invalid — email auth still works.
    }
  }
  runApp(const PopalEatsApp());
}

class PopalEatsApp extends StatelessWidget {
  const PopalEatsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(create: (_) => PreferencesProvider()),
        ChangeNotifierProvider(create: (_) => FriendsProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ReelsProvider()),
      ],
      child: MaterialApp(
        title: 'Popal Eats',
        theme: AppTheme.dark,
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.initializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }
    if (!auth.isLoggedIn) return const LoginScreen();
    return const _AuthenticatedGate();
  }
}

class _AuthenticatedGate extends StatefulWidget {
  const _AuthenticatedGate();

  @override
  State<_AuthenticatedGate> createState() => _AuthenticatedGateState();
}

class _AuthenticatedGateState extends State<_AuthenticatedGate> {
  bool? _privacyAccepted;
  bool? _locationOnboardingDone;
  bool _checkingConsent = true;

  @override
  void initState() {
    super.initState();
    _loadConsent();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshOnboarding());
  }

  Future<void> _loadConsent() async {
    final privacy = await AppConsentStorage.hasPrivacyConsent();
    final location = await AppConsentStorage.hasLocationOnboarding();
    if (!mounted) return;
    setState(() {
      _privacyAccepted = privacy;
      _locationOnboardingDone = location;
      _checkingConsent = false;
    });
  }

  Future<void> _refreshOnboarding() async {
    if (!mounted) return;
    await context.read<OnboardingProvider>().checkStatus(forceRefresh: true);
  }

  Future<void> _acceptPrivacy() async {
    await AppConsentStorage.setPrivacyConsent(true);
    if (!mounted) return;
    setState(() => _privacyAccepted = true);
  }

  Future<void> _completeLocationOnboarding() async {
    await AppConsentStorage.setLocationOnboardingCompleted(true);
    if (!mounted) return;
    setState(() => _locationOnboardingDone = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingConsent || _privacyAccepted == null || _locationOnboardingDone == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    if (!_privacyAccepted!) {
      return PrivacyConsentScreen(onAccepted: _acceptPrivacy);
    }

    if (!_locationOnboardingDone!) {
      return LocationPermissionScreen(onCompleted: _completeLocationOnboarding);
    }

    final onboarding = context.watch<OnboardingProvider>();

    if (onboarding.completed == null) {
      if (onboarding.error != null) {
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppColors.screenPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 48, color: AppColors.gold),
                  const SizedBox(height: 16),
                  Text(
                    'Could not verify onboarding status',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    onboarding.error!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: onboarding.loading ? null : _refreshOnboarding,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    if (onboarding.needsOnboarding) {
      return const PreferenceOnboardingScreen();
    }

    return const _MainShellWithPreferences();
  }
}

class _MainShellWithPreferences extends StatefulWidget {
  const _MainShellWithPreferences();

  @override
  State<_MainShellWithPreferences> createState() => _MainShellWithPreferencesState();
}

class _MainShellWithPreferencesState extends State<_MainShellWithPreferences> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PreferencesProvider>().fetch(force: true);
      context.read<FriendsProvider>().fetchAll(force: true);
      context.read<GroupProvider>().fetchAll(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const MainShell();
  }
}
