import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../utils/auth_validation.dart';
import '../widgets/auth_screen_widgets.dart';
import '../widgets/onboarding/selection_card.dart';
import '../widgets/ui/app_ui_widgets.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  int _step = 0;
  SignupRole _role = SignupRole.customer;

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  final _restaurantName = TextEditingController();
  final _restaurantAddress = TextEditingController();
  final _cuisineType = TextEditingController();
  final _businessReg = TextEditingController();
  final _logoUrl = TextEditingController();
  final _coverUrl = TextEditingController();

  final _chefDisplayName = TextEditingController();
  final _chefSpecialty = TextEditingController();
  final _kitchenAddress = TextEditingController();
  final _foodLicense = TextEditingController();
  final _chefImageUrl = TextEditingController();

  DateTime? _dateOfBirth;
  bool? _usernameAvailable;
  bool _checkingUsername = false;
  String? _usernameCheckMessage;
  Timer? _usernameDebounce;
  int _usernameCheckGeneration = 0;

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    for (final c in [
      _firstName,
      _lastName,
      _username,
      _email,
      _phone,
      _password,
      _confirmPassword,
      _restaurantName,
      _restaurantAddress,
      _cuisineType,
      _businessReg,
      _logoUrl,
      _coverUrl,
      _chefDisplayName,
      _chefSpecialty,
      _kitchenAddress,
      _foodLicense,
      _chefImageUrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  int get _maxStep => _role == SignupRole.customer ? 1 : 2;

  void _scheduleUsernameCheck(String value) {
    _usernameDebounce?.cancel();
    final trimmed = value.trim().toLowerCase();
    final generation = ++_usernameCheckGeneration;
    final localError = AuthValidation.validateUsername(trimmed.isEmpty ? null : trimmed);

    if (localError != null || trimmed.length < 3) {
      setState(() {
        _usernameAvailable = localError != null ? false : null;
        _checkingUsername = false;
        _usernameCheckMessage = localError;
      });
      return;
    }

    setState(() {
      _checkingUsername = true;
      _usernameAvailable = null;
      _usernameCheckMessage = null;
    });

    _usernameDebounce = Timer(const Duration(milliseconds: 450), () async {
      try {
        final result =
            await context.read<AuthProvider>().checkUsernameAvailable(trimmed);
        if (!mounted || generation != _usernameCheckGeneration) return;
        setState(() {
          _checkingUsername = false;
          if (!result.succeeded) {
            _usernameAvailable = null;
            _usernameCheckMessage = result.errorMessage;
          } else if (result.validationMessage != null) {
            _usernameAvailable = false;
            _usernameCheckMessage = result.validationMessage;
          } else {
            _usernameAvailable = result.available;
            _usernameCheckMessage = null;
          }
        });
      } catch (_) {
        if (!mounted || generation != _usernameCheckGeneration) return;
        setState(() {
          _checkingUsername = false;
          _usernameAvailable = null;
          _usernameCheckMessage = 'Unable to verify username';
        });
      }
    });
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initial = _dateOfBirth ?? DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 120),
      lastDate: now,
      helpText: 'Date of birth',
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  bool _validateUniversalStep() {
    final checks = <String?>[
      AuthValidation.validateFirstName(_firstName.text),
      AuthValidation.validateLastName(_lastName.text),
      AuthValidation.validateUsername(_username.text),
      AuthValidation.validateEmail(_email.text),
      AuthValidation.validatePhone(_phone.text),
      AuthValidation.validateDateOfBirth(_dateOfBirth),
      AuthValidation.validatePassword(_password.text),
      AuthValidation.validateConfirmPassword(_password.text, _confirmPassword.text),
    ];
    final error = checks.firstWhere((e) => e != null, orElse: () => null);
    if (error != null) {
      _snack(error);
      return false;
    }
    if (_usernameAvailable == false) {
      _snack('Username is already taken');
      return false;
    }
    return true;
  }

  bool _validateRoleStep() {
    if (_role == SignupRole.restaurant) {
      if (_restaurantName.text.trim().isEmpty) {
        _snack('Enter your restaurant name');
        return false;
      }
      if (_restaurantAddress.text.trim().isEmpty) {
        _snack('Enter your restaurant address');
        return false;
      }
      if (_cuisineType.text.trim().isEmpty) {
        _snack('Enter your cuisine type');
        return false;
      }
    } else if (_role == SignupRole.homeChef) {
      if (_chefDisplayName.text.trim().isEmpty) {
        _snack('Enter your chef display name');
        return false;
      }
      if (_chefSpecialty.text.trim().isEmpty) {
        _snack('Enter your cuisine specialty');
        return false;
      }
      if (_kitchenAddress.text.trim().isEmpty) {
        _snack('Enter your kitchen address');
        return false;
      }
    }
    return true;
  }

  void _next() {
    if (_step == 0) {
      setState(() => _step = 1);
      return;
    }
    if (_step == 1) {
      if (!_validateUniversalStep()) return;
      if (_role == SignupRole.customer) {
        _submit();
      } else {
        setState(() => _step = 2);
      }
      return;
    }
    if (_step == 2) {
      if (!_validateRoleStep()) return;
      _submit();
    }
  }

  void _back() {
    if (_step == 0) {
      Navigator.pop(context);
      return;
    }
    setState(() => _step -= 1);
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    Map<String, dynamic>? restaurantProfile;
    Map<String, dynamic>? homeChefProfile;

    if (_role == SignupRole.restaurant) {
      restaurantProfile = {
        'restaurant_name': _restaurantName.text.trim(),
        'restaurant_address': _restaurantAddress.text.trim(),
        'cuisine_type': _cuisineType.text.trim(),
        if (_businessReg.text.trim().isNotEmpty)
          'business_registration_number': _businessReg.text.trim(),
        if (_logoUrl.text.trim().isNotEmpty) 'logo_url': _logoUrl.text.trim(),
        if (_coverUrl.text.trim().isNotEmpty) 'cover_image_url': _coverUrl.text.trim(),
      };
    } else if (_role == SignupRole.homeChef) {
      homeChefProfile = {
        'chef_display_name': _chefDisplayName.text.trim(),
        'cuisine_specialty': _chefSpecialty.text.trim(),
        'kitchen_address': _kitchenAddress.text.trim(),
        if (_foodLicense.text.trim().isNotEmpty) 'food_license': _foodLicense.text.trim(),
        if (_chefImageUrl.text.trim().isNotEmpty)
          'profile_image_url': _chefImageUrl.text.trim(),
      };
    }

    final ok = await auth.register(
      role: _role,
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      username: _username.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      dateOfBirth: _dateOfBirth!,
      password: _password.text,
      confirmPassword: _confirmPassword.text,
      restaurantProfile: restaurantProfile,
      homeChefProfile: homeChefProfile,
    );
    if (!mounted) return;
    if (ok) {
      if (auth.lastLoginMessage != null) {
        _snack(auth.lastLoginMessage!);
      }
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      _snack(auth.error ?? 'Registration failed');
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _progressDots() {
    final total = _maxStep + 1;
    return Row(
      children: List.generate(total, (index) {
        final active = index <= _step;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: EdgeInsets.only(right: index < total - 1 ? 8 : 0),
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              color: active ? AppColors.accent : AppColors.surfaceLight,
            ),
          ),
        );
      }),
    );
  }

  Widget _roleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Continue as', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          'One account for the whole platform — pick how you want to use Popal Eats.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        ...SignupRole.values.map((role) {
          final selected = _role == role;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OnboardingSelectionCard(
              label: role.label,
              icon: role.icon,
              selected: selected,
              onTap: () => setState(() => _role = role),
            ),
          );
        }),
      ],
    );
  }

  Widget _universalStep() {
    final dobLabel = _dateOfBirth == null
        ? 'Select date of birth'
        : '${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Your details', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          'Registering as ${_role.label}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.accent),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _firstName,
                decoration: authInputDecoration(label: 'First name', icon: Icons.badge_outlined),
                textCapitalization: TextCapitalization.words,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _lastName,
                decoration: authInputDecoration(label: 'Last name', icon: Icons.badge_outlined),
                textCapitalization: TextCapitalization.words,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _username,
          decoration: authInputDecoration(
            label: 'Username',
            icon: Icons.alternate_email,
            hint: 'food.lover_01',
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
                    ? const Icon(Icons.check_circle, color: AppColors.accent)
                    : _usernameAvailable == false
                        ? const Icon(Icons.cancel_outlined, color: AppColors.error)
                        : null,
            helperText: _usernameCheckMessage ??
                (_usernameAvailable == true ? 'Username available' : '3–30 chars, letters, numbers, _ .'),
            helperStyle: _usernameCheckMessage != null
                ? TextStyle(color: AppColors.error.withValues(alpha: 0.9))
                : null,
          ),
          onChanged: _scheduleUsernameCheck,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _email,
          decoration: authInputDecoration(label: 'Email', icon: Icons.email_outlined),
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
        OutlinedButton.icon(
          onPressed: _pickDateOfBirth,
          icon: const Icon(Icons.cake_outlined),
          label: Text(dobLabel),
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _password,
          decoration: authInputDecoration(
            label: 'Password',
            icon: Icons.lock_outline,
            hint: '8+ chars with upper, lower, number, symbol',
          ),
          obscureText: true,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirmPassword,
          decoration: authInputDecoration(label: 'Confirm password', icon: Icons.lock_outline),
          obscureText: true,
        ),
      ],
    );
  }

  Widget _roleSpecificStep() {
    if (_role == SignupRole.restaurant) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Restaurant details', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Your account will be pending until an admin approves it.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _restaurantName,
            decoration: authInputDecoration(label: 'Restaurant name', icon: Icons.storefront_outlined),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _restaurantAddress,
            decoration: authInputDecoration(label: 'Restaurant address', icon: Icons.location_on_outlined),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cuisineType,
            decoration: authInputDecoration(label: 'Cuisine type', icon: Icons.restaurant_menu_outlined),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _businessReg,
            decoration: authInputDecoration(
              label: 'Business registration number (optional)',
              icon: Icons.numbers_outlined,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _logoUrl,
            decoration: authInputDecoration(
              label: 'Logo image URL (optional)',
              icon: Icons.image_outlined,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _coverUrl,
            decoration: authInputDecoration(
              label: 'Cover image URL (optional)',
              icon: Icons.photo_outlined,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Home chef profile', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          'Your account will be pending until an admin approves it.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _chefDisplayName,
          decoration: authInputDecoration(label: 'Chef display name', icon: Icons.person_outline),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _chefSpecialty,
          decoration: authInputDecoration(label: 'Cuisine specialty', icon: Icons.restaurant_outlined),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _kitchenAddress,
          decoration: authInputDecoration(label: 'Kitchen address', icon: Icons.home_outlined),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _foodLicense,
          decoration: authInputDecoration(
            label: 'Food license (optional)',
            icon: Icons.verified_outlined,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _chefImageUrl,
          decoration: authInputDecoration(
            label: 'Profile image URL (optional)',
            icon: Icons.image_outlined,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final stepTitle = switch (_step) {
      0 => 'Choose your path',
      1 => 'Create your account',
      _ => _role == SignupRole.restaurant ? 'Restaurant setup' : 'Chef setup',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign up'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _back),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppColors.screenPadding),
          children: [
            AuthBrandedHeader(
              title: stepTitle,
              subtitle: 'Join Popal Eats with one secure account',
            ),
            const SizedBox(height: 16),
            _progressDots(),
            const SizedBox(height: 16),
            AuthFormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_step == 0) _roleStep(),
                  if (_step == 1) _universalStep(),
                  if (_step == 2) _roleSpecificStep(),
                  const SizedBox(height: 20),
                  GoldActionButton(
                    label: _step < _maxStep ? 'Continue' : 'Create account',
                    icon: _step < _maxStep ? Icons.arrow_forward : Icons.person_add_outlined,
                    loading: auth.loading,
                    onPressed: auth.loading ? null : _next,
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
