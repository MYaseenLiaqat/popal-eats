/// Role helpers for navigation gating.
class AppRoles {
  AppRoles._();

  static const customer = 'customer';
  static const restaurant = 'restaurant';
  static const restaurantOwner = 'restaurant_owner';
  static const homeChef = 'home_chef';
  static const admin = 'admin';

  static String? roleOf(Map<String, dynamic>? user) =>
      user?['role']?.toString().toLowerCase();

  static String? accountStatusOf(Map<String, dynamic>? user) =>
      user?['account_status']?.toString().toLowerCase();

  static bool isAdmin(Map<String, dynamic>? user) => roleOf(user) == admin;

  static bool isCustomer(Map<String, dynamic>? user) =>
      roleOf(user) == customer;

  static bool isRestaurant(Map<String, dynamic>? user) {
    final role = roleOf(user);
    return role == restaurant || role == restaurantOwner || role == admin;
  }

  /// Restaurant role only (excludes admin) for owner dashboard routing.
  static bool isRestaurantRoleOnly(Map<String, dynamic>? user) {
    final role = roleOf(user);
    return role == restaurant || role == restaurantOwner;
  }

  static bool isActiveRestaurantOwner(Map<String, dynamic>? user) =>
      isRestaurantRoleOnly(user) && isActive(user);

  static bool isActiveHomeChef(Map<String, dynamic>? user) =>
      isHomeChef(user) && isActive(user);

  /// Customers use MainShell; business roles use dedicated shells.
  static bool canUseCustomerApp(Map<String, dynamic>? user) =>
      isCustomer(user);

  /// Home feed creation is for approved business accounts only.
  static bool canCreateHomeFeedContent(Map<String, dynamic>? user) =>
      (isRestaurantRoleOnly(user) || isHomeChef(user)) && isActive(user);

  static bool isHomeChef(Map<String, dynamic>? user) =>
      roleOf(user) == homeChef;

  static bool isRestaurantOwner(Map<String, dynamic>? user) => isRestaurant(user);

  static bool isPending(Map<String, dynamic>? user) =>
      accountStatusOf(user) == 'pending';

  static bool isRejected(Map<String, dynamic>? user) =>
      accountStatusOf(user) == 'rejected';

  static bool isSuspended(Map<String, dynamic>? user) =>
      accountStatusOf(user) == 'suspended';

  static bool isActive(Map<String, dynamic>? user) =>
      accountStatusOf(user) == 'active' || accountStatusOf(user) == null;

  static bool isBusinessAccount(Map<String, dynamic>? user) =>
      isRestaurant(user) || isHomeChef(user);

  static bool needsBusinessStatusGate(Map<String, dynamic>? user) {
    if (!isBusinessAccount(user)) return false;
    final status = accountStatusOf(user);
    return status == 'pending' || status == 'rejected' || status == 'suspended';
  }

  static String businessRoleLabel(Map<String, dynamic>? user) {
    if (isHomeChef(user)) return 'home chef';
    if (isRestaurant(user)) return 'restaurant';
    return 'business';
  }
}
