import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_screen_widgets.dart';
import '../widgets/ui/app_ui_widgets.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool? _usernameAvailable;
  bool _checkingUsername = false;
  Timer? _usernameDebounce;

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _phone.dispose();
    _city.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _scheduleUsernameCheck(String value) {
    _usernameDebounce?.cancel();
    final trimmed = value.trim().toLowerCase();
    if (trimmed.length < 3) {
      setState(() {
        _usernameAvailable = null;
        _checkingUsername = false;
      });
      return;
    }
    setState(() {
      _checkingUsername = true;
      _usernameAvailable = null;
    });
    _usernameDebounce = Timer(const Duration(milliseconds: 450), () async {
      final available = await context.read<AuthProvider>().checkUsernameAvailable(trimmed);
      if (!mounted) return;
      setState(() {
        _checkingUsername = false;
        _usernameAvailable = available;
      });
    });
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final username = _username.text.trim().toLowerCase();
    final email = _email.text.trim();
    final password = _password.text;
    final confirm = _confirmPassword.text;

    if (name.isEmpty) {
      _snack('Enter your full name');
      return;
    }
    if (username.length < 3) {
      _snack('Choose a username (3+ characters)');
      return;
    }
    if (_usernameAvailable == false) {
      _snack('Username is already taken');
      return;
    }
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      _snack('Use a valid email like you@example.com');
      return;
    }
    if (password.length < 6) {
      _snack('Password must be at least 6 characters');
      return;
    }
    if (password != confirm) {
      _snack('Passwords do not match');
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      fullName: name,
      username: username,
      email: email,
      password: password,
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      city: _city.text.trim().isEmpty ? null : _city.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      _snack(auth.error ?? 'Registration failed');
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Sign up')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppColors.screenPadding),
          children: [
            const AuthBrandedHeader(
              title: 'Create your account',
              subtitle: 'Join the food community',
            ),
            const SizedBox(height: 16),
            AuthFormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Register', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _name,
                    decoration: authInputDecoration(
                      label: 'Full name',
                      icon: Icons.person_outline,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _username,
                    decoration: authInputDecoration(
                      label: 'Username',
                      icon: Icons.alternate_email,
                      hint: 'foodie_lahore',
                    ).copyWith(
                      suffixIcon: _checkingUsername
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : _usernameAvailable == true
                              ? const Icon(Icons.check_circle, color: AppColors.green)
                              : _usernameAvailable == false
                                  ? const Icon(Icons.cancel_outlined, color: AppColors.error)
                                  : null,
                      helperText: _usernameAvailable == false
                          ? 'Username taken'
                          : _usernameAvailable == true
                              ? 'Username available'
                              : 'Letters, numbers, underscores',
                    ),
                    onChanged: _scheduleUsernameCheck,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _email,
                    decoration: authInputDecoration(
                      label: 'Email',
                      icon: Icons.email_outlined,
                      hint: 'you@example.com',
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phone,
                    decoration: authInputDecoration(
                      label: 'Phone number',
                      icon: Icons.phone_outlined,
                      hint: '+92 300 1234567',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _city,
                    decoration: authInputDecoration(
                      label: 'City',
                      icon: Icons.location_city_outlined,
                      hint: 'Lahore',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    decoration: authInputDecoration(
                      label: 'Password',
                      icon: Icons.lock_outline,
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmPassword,
                    decoration: authInputDecoration(
                      label: 'Confirm password',
                      icon: Icons.lock_outline,
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 18),
                  GoldActionButton(
                    label: 'Create Account',
                    icon: Icons.person_add_outlined,
                    loading: auth.loading,
                    onPressed: auth.loading ? null : _submit,
                  ),
                  if (auth.googleSignInAvailable) ...[
                    const SizedBox(height: 14),
                    const AuthDivider(label: 'or'),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: auth.loading
                          ? null
                          : () async {
                              final ok = await auth.loginWithGoogle();
                              if (!context.mounted) return;
                              if (ok) {
                                Navigator.of(context).popUntil((route) => route.isFirst);
                              } else if (auth.error != null) {
                                _snack(auth.error!);
                              }
                            },
                      icon: const Icon(Icons.g_mobiledata, size: 22),
                      label: const Text('Sign up with Google'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
