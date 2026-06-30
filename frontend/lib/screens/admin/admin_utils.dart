import 'package:flutter/material.dart';

String adminAccountTitle(Map<String, dynamic> account) {
  final restaurant = account['restaurant'] as Map<String, dynamic>?;
  final chef = account['home_chef'] as Map<String, dynamic>?;
  if (restaurant != null) return restaurant['name']?.toString() ?? 'Restaurant';
  if (chef != null) return chef['display_name']?.toString() ?? 'Home Chef';
  return account['full_name']?.toString() ?? 'Business account';
}

String? adminAccountSubtitle(Map<String, dynamic> account) {
  final restaurant = account['restaurant'] as Map<String, dynamic>?;
  final chef = account['home_chef'] as Map<String, dynamic>?;
  if (restaurant != null) {
    return [restaurant['address'], restaurant['cuisine_type']].whereType<String>().join(' · ');
  }
  if (chef != null) {
    return [chef['kitchen_address'], chef['cuisine_specialty']].whereType<String>().join(' · ');
  }
  return account['email']?.toString();
}

String adminFormatDate(String? raw) {
  if (raw == null || raw.isEmpty) return '—';
  final dt = DateTime.tryParse(raw);
  if (dt == null) return raw;
  final local = dt.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}

bool adminIsRestaurantRole(Map<String, dynamic> account) {
  final role = account['role']?.toString() ?? '';
  return role == 'restaurant' || role == 'restaurant_owner';
}

bool adminIsHomeChefRole(Map<String, dynamic> account) {
  return account['role']?.toString() == 'home_chef';
}

String? adminMapStr(Map<String, dynamic>? map, String key) {
  if (map == null) return null;
  return map[key]?.toString();
}

Future<void> adminShowSnack(BuildContext context, String message, {bool error = false}) async {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? Colors.red.shade800 : null,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

Future<bool?> adminConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirm = 'Confirm',
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(confirm)),
      ],
    ),
  );
}
