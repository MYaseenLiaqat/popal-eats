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
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      _name.text.trim(),
      _email.text.trim(),
      _password.text,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Registration failed')),
      );
    }
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
              subtitle: 'Join Popal Eats for smart food recommendations',
            ),
            const SizedBox(height: 20),
            AuthFormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Register',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _name,
                    decoration: authInputDecoration(
                      label: 'Full name',
                      icon: Icons.person_outline,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _email,
                    decoration: authInputDecoration(
                      label: 'Email',
                      icon: Icons.email_outlined,
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _password,
                    decoration: authInputDecoration(
                      label: 'Password',
                      icon: Icons.lock_outline,
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  GoldActionButton(
                    label: 'Create Account',
                    icon: Icons.person_add_outlined,
                    loading: auth.loading,
                    onPressed: auth.loading ? null : _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
