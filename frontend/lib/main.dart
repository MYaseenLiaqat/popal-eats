import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/friends_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/preferences_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/preference_onboarding_screen.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        ChangeNotifierProvider(create: (_) => CartProvider()),
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshOnboarding());
  }

  Future<void> _refreshOnboarding() async {
    if (!mounted) return;
    await context.read<OnboardingProvider>().checkStatus(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = context.watch<OnboardingProvider>();

    if (onboarding.completed == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return const MainShell();
  }
}
