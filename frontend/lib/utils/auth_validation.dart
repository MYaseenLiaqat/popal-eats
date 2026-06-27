import 'package:flutter/material.dart';

/// Client-side auth validation (mirrors backend rules; server is authoritative).
class AuthValidation {
  AuthValidation._();

  static const reservedUsernames = {
    'admin',
    'administrator',
    'support',
    'system',
    'api',
    'null',
    'root',
  };

  static String? validateFirstName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Enter your first name';
    return null;
  }

  static String? validateLastName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Enter your last name';
    return null;
  }

  static String? validateUsername(String? value) {
    final trimmed = value?.trim().toLowerCase() ?? '';
    if (trimmed.length < 3) return 'Username must be at least 3 characters';
    if (trimmed.length > 30) return 'Username must be at most 30 characters';
    final pattern = RegExp(r'^[a-z][a-z0-9_.]{2,29}$');
    if (!pattern.hasMatch(trimmed)) {
      return 'Use letters, numbers, underscores, and periods';
    }
    if (reservedUsernames.contains(trimmed)) return 'That username is reserved';
    return null;
  }

  static String? validateEmail(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Enter your email';
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(trimmed)) return 'Enter a valid email address';
    return null;
  }

  static String? validatePhone(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Enter your phone number';
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8 || digits.length > 15) {
      return 'Enter a valid international phone number';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    final password = value ?? '';
    if (password.length < 8) return 'Password must be at least 8 characters';
    if (password.length > 128) return 'Password must be at most 128 characters';
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Include at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Include at least one lowercase letter';
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return 'Include at least one number';
    }
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      return 'Include at least one special character';
    }
    return null;
  }

  static String? validateConfirmPassword(String? password, String? confirm) {
    if (confirm == null || confirm.isEmpty) return 'Confirm your password';
    if (confirm != password) return 'Passwords do not match';
    return null;
  }

  static String? validateDateOfBirth(DateTime? dob) {
    if (dob == null) return 'Select your date of birth';
    final today = DateTime.now();
    if (dob.isAfter(today)) return 'Date of birth cannot be in the future';
    var age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    if (age < 13) return 'You must be at least 13 years old';
    if (age > 120) return 'Enter a valid date of birth';
    return null;
  }
}

enum SignupRole { customer, restaurant, homeChef }

extension SignupRoleApi on SignupRole {
  String get apiValue {
    switch (this) {
      case SignupRole.customer:
        return 'customer';
      case SignupRole.restaurant:
        return 'restaurant';
      case SignupRole.homeChef:
        return 'home_chef';
    }
  }

  String get label {
    switch (this) {
      case SignupRole.customer:
        return 'Customer';
      case SignupRole.restaurant:
        return 'Restaurant';
      case SignupRole.homeChef:
        return 'Home Chef';
    }
  }

  String get description {
    switch (this) {
      case SignupRole.customer:
        return 'Order food, get recommendations, and join the community';
      case SignupRole.restaurant:
        return 'List your restaurant and reach hungry customers';
      case SignupRole.homeChef:
        return 'Share homemade meals from your kitchen';
    }
  }

  IconData get icon {
    switch (this) {
      case SignupRole.customer:
        return Icons.person_outline;
      case SignupRole.restaurant:
        return Icons.storefront_outlined;
      case SignupRole.homeChef:
        return Icons.soup_kitchen_outlined;
    }
  }
}
