import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_screen_widgets.dart';
import '../widgets/ui/app_ui_widgets.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;

    if (email.isEmpty || !email.contains('@')) {
      _snack('Enter a valid email');
      return;
    }
    if (password.length < 8) {
      _snack('Password must be at least 8 characters');
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.login(email, password);
    if (!mounted) return;
    if (!ok) {
      _snack(auth.error ?? 'Login failed');
    } else if (auth.lastLoginMessage != null) {
      _snack(auth.lastLoginMessage!);
    }
  }

  Future<void> _googleSignIn() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.loginWithGoogle();
    if (!mounted) return;
    if (!ok && auth.error != null) {
      _snack(auth.error!);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppColors.screenPadding),
          children: [
            const SizedBox(height: 12),
            const AuthBrandedHeader(
              title: 'Welcome back',
              subtitle: 'Discover food you\'ll love from people you trust',
            ),
            const SizedBox(height: 20),
            AuthFormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Sign in', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _email,
                    decoration: authInputDecoration(
                      context,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      hint: 'you@example.com',
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _password,
                    decoration: authInputDecoration(
                      context,
                      label: 'Password',
                      icon: Icons.lock_outline,
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  GoldActionButton(
                    label: 'Login',
                    icon: Icons.login,
                    loading: auth.loading,
                    onPressed: auth.loading ? null : _submit,
                  ),
                  if (auth.googleSignInAvailable) ...[
                    const SizedBox(height: 16),
                    const AuthDivider(label: 'or'),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: auth.loading ? null : _googleSignIn,
                      icon: Image.network(
                        'https://www.google.com/favicon.ico',
                        width: 18,
                        height: 18,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.g_mobiledata, size: 22),
                      ),
                      label: const Text('Continue with Google'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: AppColors.surfaceLight.withValues(alpha: 0.6)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Don't have an account?", style: Theme.of(context).textTheme.bodyMedium),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                  ),
                  child: const Text('Create account'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
