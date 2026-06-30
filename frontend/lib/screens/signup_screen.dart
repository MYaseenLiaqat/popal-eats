import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/cuisine_catalog.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../utils/auth_validation.dart';
import '../widgets/auth_screen_widgets.dart';
import '../widgets/onboarding/selection_card.dart';
import '../widgets/registration_image_picker.dart';
import '../widgets/ui/app_ui_widgets.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  static const _fieldGap = 12.0;
  static const _formMaxWidth = 520.0;

  int _step = 0;
  SignupRole _role = SignupRole.customer;

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _customerEmail = TextEditingController();
  final _customerPhone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  final _restaurantName = TextEditingController();
  final _restaurantEmail = TextEditingController();
  final _businessPhone = TextEditingController();
  final _restaurantAddress = TextEditingController();
  final _businessReg = TextEditingController();
  final _restaurantDescription = TextEditingController();
  String? _restaurantCuisine;
  String _venueType = 'restaurant';
  PlatformFile? _logoImage;
  PlatformFile? _coverImage;

  final _chefDisplayName = TextEditingController();
  final _chefEmail = TextEditingController();
  final _chefPhone = TextEditingController();
  final _kitchenAddress = TextEditingController();
  final _chefBiography = TextEditingController();
  String? _chefCuisine;
  PlatformFile? _chefProfileImage;
  PlatformFile? _foodLicenseFile;

  DateTime? _dateOfBirth;

  @override
  void dispose() {
    for (final c in [
      _firstName,
      _lastName,
      _customerEmail,
      _customerPhone,
      _password,
      _confirmPassword,
      _restaurantName,
      _restaurantEmail,
      _businessPhone,
      _restaurantAddress,
      _businessReg,
      _restaurantDescription,
      _chefDisplayName,
      _chefEmail,
      _chefPhone,
      _kitchenAddress,
      _chefBiography,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _gap() => const SizedBox(height: _fieldGap);

  String _venueLabel(String type) => switch (type) {
        'food_chain' => 'Food chain / hotel',
        'home_kitchen' => 'Home kitchen',
        _ => 'Restaurant / dine-in',
      };

  String _venueDescription() {
    final custom = _restaurantDescription.text.trim();
    final prefix = 'Venue type: ${_venueLabel(_venueType)}.';
    if (custom.isEmpty) return prefix;
    return '$prefix $custom';
  }

  Widget _venueTypeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _venueType,
      isExpanded: true,
      decoration: authInputDecoration(context,
        label: 'How do you operate?',
        icon: Icons.store_mall_directory_outlined,
      ),
      items: const [
        DropdownMenuItem(value: 'restaurant', child: Text('Restaurant / dine-in')),
        DropdownMenuItem(value: 'food_chain', child: Text('Food chain / hotel')),
        DropdownMenuItem(value: 'home_kitchen', child: Text('Home kitchen')),
      ],
      onChanged: (v) {
        if (v != null) setState(() => _venueType = v);
      },
    );
  }

  Widget _stepHeader(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _cuisineDropdown({
    required String? value,
    required String label,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      isDense: true,
      decoration: authInputDecoration(context,
        label: label,
        icon: Icons.restaurant_menu_outlined,
      ),
      hint: Text(
        'Select cuisine',
        style: Theme.of(context).textTheme.bodyMedium,
        overflow: TextOverflow.ellipsis,
      ),
      items: CuisineCatalog.cuisines
          .map(
            (c) => DropdownMenuItem<String>(
              value: c.key,
              child: Text(c.name, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _passwordFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _password,
          decoration: authInputDecoration(context,
            label: 'Password',
            icon: Icons.lock_outline,
            hint: '8+ chars with upper, lower, number, symbol',
          ),
          obscureText: true,
        ),
        _gap(),
        TextField(
          controller: _confirmPassword,
          decoration: authInputDecoration(context,
            label: 'Confirm password',
            icon: Icons.lock_outline,
          ),
          obscureText: true,
        ),
      ],
    );
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

  bool _validatePasswordFields() {
    final checks = <String?>[
      AuthValidation.validatePassword(_password.text),
      AuthValidation.validateConfirmPassword(
          _password.text, _confirmPassword.text),
    ];
    final error = checks.firstWhere((e) => e != null, orElse: () => null);
    if (error != null) {
      _snack(error);
      return false;
    }
    return true;
  }

  bool _validateCustomerStep() {
    final checks = <String?>[
      AuthValidation.validateFirstName(_firstName.text),
      AuthValidation.validateLastName(_lastName.text),
      AuthValidation.validateEmail(_customerEmail.text),
      AuthValidation.validatePhone(_customerPhone.text),
      AuthValidation.validateDateOfBirth(_dateOfBirth),
    ];
    final error = checks.firstWhere((e) => e != null, orElse: () => null);
    if (error != null) {
      _snack(error);
      return false;
    }
    return _validatePasswordFields();
  }

  bool _validateRestaurantStep() {
    final checks = <String?>[
      _restaurantName.text.trim().isEmpty ? 'Enter your restaurant name' : null,
      AuthValidation.validateEmail(_restaurantEmail.text),
      AuthValidation.validatePhone(_businessPhone.text),
      _restaurantAddress.text.trim().isEmpty
          ? 'Enter your restaurant address'
          : null,
      _restaurantCuisine == null ? 'Select a cuisine' : null,
    ];
    final error = checks.firstWhere((e) => e != null, orElse: () => null);
    if (error != null) {
      _snack(error);
      return false;
    }
    return _validatePasswordFields();
  }

  bool _validateHomeChefStep() {
    final checks = <String?>[
      _chefDisplayName.text.trim().isEmpty ? 'Enter your display name' : null,
      AuthValidation.validateEmail(_chefEmail.text),
      AuthValidation.validatePhone(_chefPhone.text),
      _kitchenAddress.text.trim().isEmpty ? 'Enter your kitchen address' : null,
      _chefCuisine == null ? 'Select a cuisine specialty' : null,
    ];
    final error = checks.firstWhere((e) => e != null, orElse: () => null);
    if (error != null) {
      _snack(error);
      return false;
    }
    return _validatePasswordFields();
  }

  void _next() {
    if (_step == 0) {
      setState(() => _step = 1);
      return;
    }
    if (_step == 1) {
      final valid = switch (_role) {
        SignupRole.customer => _validateCustomerStep(),
        SignupRole.restaurant => _validateRestaurantStep(),
        SignupRole.homeChef => _validateHomeChefStep(),
      };
      if (!valid) return;
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

    String email;
    String phone;
    String? firstName;
    String? lastName;
    DateTime? dateOfBirth;

    if (_role == SignupRole.customer) {
      email = _customerEmail.text.trim();
      phone = _customerPhone.text.trim();
      firstName = _firstName.text.trim();
      lastName = _lastName.text.trim();
      dateOfBirth = _dateOfBirth;
    } else if (_role == SignupRole.restaurant) {
      email = _restaurantEmail.text.trim();
      phone = _businessPhone.text.trim();
      restaurantProfile = {
        'restaurant_name': _restaurantName.text.trim(),
        'restaurant_address': _restaurantAddress.text.trim(),
        'cuisine_type': _restaurantCuisine!,
        if (_businessReg.text.trim().isNotEmpty)
          'business_registration_number': _businessReg.text.trim(),
        'description': _venueDescription(),
      };
    } else {
      email = _chefEmail.text.trim();
      phone = _chefPhone.text.trim();
      homeChefProfile = {
        'chef_display_name': _chefDisplayName.text.trim(),
        'cuisine_specialty': _chefCuisine!,
        'kitchen_address': _kitchenAddress.text.trim(),
        if (_chefBiography.text.trim().isNotEmpty)
          'biography': _chefBiography.text.trim(),
      };
    }

    final ok = await auth.register(
      role: _role,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      dateOfBirth: dateOfBirth,
      password: _password.text,
      confirmPassword: _confirmPassword.text,
      restaurantProfile: restaurantProfile,
      homeChefProfile: homeChefProfile,
      restaurantCoverImage: _coverImage,
      restaurantLogoImage: _logoImage,
      homeChefProfileImage: _chefProfileImage,
      homeChefFoodLicense: _foodLicenseFile,
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _progressDots() {
    return Row(
      children: List.generate(2, (index) {
        final active = index <= _step;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: EdgeInsets.only(right: index < 1 ? 8 : 0),
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
        const SizedBox(height: 14),
        ...SignupRole.values.where((r) => r != SignupRole.homeChef).map((role) {
          final selected = _role == role;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
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

  Widget _customerStep() {
    final dobLabel = _dateOfBirth == null
        ? 'Select date of birth'
        : '${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepHeader(
          'Your details',
          subtitle: 'Create your customer account',
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _firstName,
                decoration: authInputDecoration(context,
                  label: 'First name',
                  icon: Icons.badge_outlined,
                ),
                textCapitalization: TextCapitalization.words,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _lastName,
                decoration: authInputDecoration(context,
                  label: 'Last name',
                  icon: Icons.badge_outlined,
                ),
                textCapitalization: TextCapitalization.words,
              ),
            ),
          ],
        ),
        _gap(),
        TextField(
          controller: _customerEmail,
          decoration:
              authInputDecoration(context,label: 'Email', icon: Icons.email_outlined),
          keyboardType: TextInputType.emailAddress,
        ),
        _gap(),
        TextField(
          controller: _customerPhone,
          decoration: authInputDecoration(context,
            label: 'Phone number',
            icon: Icons.phone_outlined,
            hint: '+92 300 1234567',
          ),
          keyboardType: TextInputType.phone,
        ),
        _gap(),
        OutlinedButton.icon(
          onPressed: _pickDateOfBirth,
          icon: const Icon(Icons.cake_outlined),
          label: Text(dobLabel),
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
        _gap(),
        _passwordFields(),
      ],
    );
  }

  Widget _restaurantStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepHeader(
          'Restaurant registration',
          subtitle: 'Your account will be pending until an admin approves it.',
        ),
        TextField(
          controller: _restaurantName,
          decoration: authInputDecoration(context,
            label: 'Restaurant name',
            icon: Icons.storefront_outlined,
          ),
        ),
        _gap(),
        TextField(
          controller: _restaurantEmail,
          decoration: authInputDecoration(context,
            label: 'Restaurant email',
            icon: Icons.email_outlined,
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        _gap(),
        TextField(
          controller: _businessPhone,
          decoration: authInputDecoration(context,
            label: 'Business phone',
            icon: Icons.phone_outlined,
            hint: '+92 300 1234567',
          ),
          keyboardType: TextInputType.phone,
        ),
        _gap(),
        TextField(
          controller: _restaurantAddress,
          decoration: authInputDecoration(context,
            label: 'Restaurant address',
            icon: Icons.location_on_outlined,
          ),
          maxLines: 2,
          minLines: 1,
        ),
        _gap(),
        _venueTypeDropdown(),
        _gap(),
        _cuisineDropdown(
          value: _restaurantCuisine,
          label: 'Cuisine',
          onChanged: (v) => setState(() => _restaurantCuisine = v),
        ),
        _gap(),
        TextField(
          controller: _restaurantDescription,
          decoration: authInputDecoration(context,
            label: 'Description (optional)',
            icon: Icons.description_outlined,
          ),
          maxLines: 2,
          minLines: 1,
        ),
        _gap(),
        TextField(
          controller: _businessReg,
          decoration: authInputDecoration(context,
            label: 'Registration number (optional)',
            icon: Icons.numbers_outlined,
          ),
        ),
        _gap(),
        RegistrationFilePicker(
          label: 'Logo (optional)',
          file: _logoImage,
          previewHeight: 72,
          onFileSelected: (f) => setState(() => _logoImage = f),
          onClear: () => setState(() => _logoImage = null),
        ),
        _gap(),
        RegistrationFilePicker(
          label: 'Cover image (optional)',
          file: _coverImage,
          previewHeight: 72,
          onFileSelected: (f) => setState(() => _coverImage = f),
          onClear: () => setState(() => _coverImage = null),
        ),
        _gap(),
        _passwordFields(),
      ],
    );
  }

  Widget _homeChefStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepHeader(
          'Home chef registration',
          subtitle: 'Your account will be pending until an admin approves it.',
        ),
        TextField(
          controller: _chefDisplayName,
          decoration: authInputDecoration(context,
            label: 'Display name',
            icon: Icons.person_outline,
          ),
        ),
        _gap(),
        TextField(
          controller: _chefEmail,
          decoration:
              authInputDecoration(context,label: 'Email', icon: Icons.email_outlined),
          keyboardType: TextInputType.emailAddress,
        ),
        _gap(),
        TextField(
          controller: _chefPhone,
          decoration: authInputDecoration(context,
            label: 'Phone',
            icon: Icons.phone_outlined,
            hint: '+92 300 1234567',
          ),
          keyboardType: TextInputType.phone,
        ),
        _gap(),
        TextField(
          controller: _kitchenAddress,
          decoration: authInputDecoration(context,
            label: 'Kitchen address',
            icon: Icons.home_outlined,
          ),
          maxLines: 2,
          minLines: 1,
        ),
        _gap(),
        _cuisineDropdown(
          value: _chefCuisine,
          label: 'Cuisine specialty',
          onChanged: (v) => setState(() => _chefCuisine = v),
        ),
        _gap(),
        TextField(
          controller: _chefBiography,
          decoration: authInputDecoration(context,
            label: 'Biography (optional)',
            icon: Icons.notes_outlined,
          ),
          maxLines: 2,
          minLines: 1,
        ),
        _gap(),
        RegistrationFilePicker(
          label: 'Food license (optional)',
          file: _foodLicenseFile,
          imageOnly: false,
          onFileSelected: (f) => setState(() => _foodLicenseFile = f),
          onClear: () => setState(() => _foodLicenseFile = null),
        ),
        _gap(),
        RegistrationFilePicker(
          label: 'Profile image (optional)',
          file: _chefProfileImage,
          circularPreview: true,
          previewHeight: 72,
          onFileSelected: (f) => setState(() => _chefProfileImage = f),
          onClear: () => setState(() => _chefProfileImage = null),
        ),
        _gap(),
        _passwordFields(),
      ],
    );
  }

  Widget _detailsStep() {
    return switch (_role) {
      SignupRole.customer => _customerStep(),
      SignupRole.restaurant => _restaurantStep(),
      SignupRole.homeChef => _homeChefStep(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final stepTitle = switch (_step) {
      0 => 'Choose your path',
      _ => switch (_role) {
          SignupRole.customer => 'Create your account',
          SignupRole.restaurant => 'Register your restaurant',
          SignupRole.homeChef => 'Register as home chef',
        },
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign up'),
        leading:
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: _back),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _formMaxWidth),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                if (_step == 0) ...[
                  AuthBrandedHeader(
                    title: stepTitle,
                    subtitle: 'Join Popal Eats with one secure account',
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  Text(
                    stepTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Join Popal Eats with one secure account',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 12),
                ],
                _progressDots(),
                const SizedBox(height: 12),
                AuthFormCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_step == 0) _roleStep() else _detailsStep(),
                      const SizedBox(height: 16),
                      GoldActionButton(
                        label: _step == 0 ? 'Continue' : 'Create account',
                        icon: _step == 0
                            ? Icons.arrow_forward
                            : Icons.person_add_outlined,
                        loading: auth.loading,
                        onPressed: auth.loading ? null : _next,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
