/// Role helpers for navigation gating.
class AppRoles {
  AppRoles._();

  static bool isAdmin(Map<String, dynamic>? user) =>
      user?['role']?.toString() == 'admin';

  static bool isRestaurantOwner(Map<String, dynamic>? user) {
    final role = user?['role']?.toString();
    return role == 'restaurant_owner' || role == 'admin';
  }
}
