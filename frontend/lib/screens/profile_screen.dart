import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/friends_provider.dart';
import '../providers/group_provider.dart';
import '../providers/onboarding_provider.dart';
import '../providers/preferences_provider.dart';
import '../providers/reels_provider.dart';
import '../theme/app_colors.dart';
import '../utils/app_roles.dart';
import '../utils/preference_display.dart';
import '../utils/user_display.dart';
import '../widgets/ui/app_ui_widgets.dart';
import '../widgets/social/notification_hub_button.dart';
import 'friends_list_screen.dart';
import 'groups_screen.dart';
import 'budget_preferences_screen.dart';
import 'nutrition_preferences_screen.dart';
import 'orders_screen.dart';
import 'restaurant_dashboard_screen.dart';
import 'restaurant_register_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_restaurant_approvals_screen.dart';

/// Profile — FYP dark theme layout.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PreferencesProvider>().fetch(force: true);
      context.read<FriendsProvider>().fetchAll(force: true);
      context.read<GroupProvider>().fetchAll(force: true);
    });
  }

  Future<void> _logout(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    await auth.logout();
    if (!context.mounted) return;
    context.read<CartProvider>().reset();
    context.read<OnboardingProvider>().reset();
    context.read<PreferencesProvider>().reset();
    context.read<FriendsProvider>().reset();
    context.read<GroupProvider>().reset();
    context.read<ReelsProvider>().reset();
  }

  String _nutritionSubtitle(PreferencesProvider prefs) {
    if (prefs.loading && prefs.preferences == null) return 'Loading preferences…';
    if (prefs.error != null && prefs.preferences == null) return 'Tap to retry loading';
    final data = prefs.preferences;
    if (data == null) return 'Calorie goal, cuisines & diet type';
    final diet = PreferenceDisplay.dietLabelFromBackend(data.dietaryPreferences);
    final cuisines = PreferenceDisplay.summarizeCuisines(data.favoriteCuisines);
    return '$diet · $cuisines';
  }

  String _budgetSubtitle(PreferencesProvider prefs) {
    if (prefs.loading && prefs.preferences == null) return 'Loading preferences…';
    if (prefs.error != null && prefs.preferences == null) return 'Tap to retry loading';
    final data = prefs.preferences;
    if (data == null) return 'Weekly & monthly spending limits';
    return PreferenceDisplay.budgetLabelFromBackend(data.budgetLevel);
  }

  Widget _preferencesSummary(PreferencesProvider prefs) {
    if (prefs.loading && prefs.preferences == null) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Center(
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
          ),
        ),
      );
    }

    if (prefs.error != null && prefs.preferences == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ModernCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Could not load preferences',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(prefs.error!, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => prefs.fetch(force: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final data = prefs.preferences;
    if (data == null) return const SizedBox.shrink();

    final allergyText = data.allergies.isEmpty
        ? 'None'
        : data.allergies.map(PreferenceDisplay.allergyLabel).join(', ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ModernCard(
        borderColor: AppColors.gold.withValues(alpha: 0.25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your food preferences',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _summaryRow('Cuisines', PreferenceDisplay.summarizeCuisines(data.favoriteCuisines, max: 5)),
            _summaryRow('Diet', PreferenceDisplay.dietLabelFromBackend(data.dietaryPreferences)),
            _summaryRow('Budget', PreferenceDisplay.budgetLabelFromBackend(data.budgetLevel)),
            _summaryRow('Allergies', allergyText),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final prefs = context.watch<PreferencesProvider>();
    final friends = context.watch<FriendsProvider>();
    final groups = context.watch<GroupProvider>();
    final name = user?['full_name']?.toString() ?? 'Guest';
    final handle = UserDisplay.handle(
      username: user?['username']?.toString(),
      email: user?['email']?.toString(),
      userId: user?['id'] as int?,
    );
    final city = UserDisplay.cityLine(user?['city']?.toString());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: const [NotificationHubButton()],
      ),
      body: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: () async {
          await prefs.fetch(force: true);
          await friends.fetchAll(force: true);
          if (!mounted) return;
          await context.read<GroupProvider>().fetchAll(force: true);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppColors.screenPadding),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            ModernCard(
              gradient: AppColors.headerGradient,
              borderColor: AppColors.gold.withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      gradient: AppColors.goldGradient,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: const Color(0xFF1A1400),
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 2),
                        Text(
                          handle,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        if (city != null) ...[
                          const SizedBox(height: 2),
                          Text(city, style: Theme.of(context).textTheme.bodySmall),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          friends.loadingFriends && friends.friendsCount == 0
                              ? 'Loading friends…'
                              : '${friends.friendsCount} friends',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.green,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('Orders', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            ProfileActionCard(
              icon: Icons.receipt_long_outlined,
              title: 'My Orders',
              subtitle: 'View order history and track status',
              iconColor: AppColors.gold,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrdersScreen()),
              ),
            ),
            const SizedBox(height: 12),
            Text('Social', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            ProfileActionCard(
              icon: Icons.people,
              title: 'Friends',
              subtitle: friends.loadingFriends && friends.friendsCount == 0
                  ? 'Loading…'
                  : '${friends.friendsCount} connected',
              iconColor: AppColors.green,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FriendsListScreen()),
              ).then((_) => friends.fetchFriends(force: true)),
            ),
            ProfileActionCard(
              icon: Icons.groups,
              title: 'Group Sessions',
              subtitle: groups.loadingGroups && groups.groupCount == 0
                  ? 'Loading…'
                  : '${groups.groupCount} active · ${groups.incomingInvitationCount} invites in Activity',
              iconColor: AppColors.green,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GroupsScreen()),
              ).then((_) => groups.fetchAll(force: true)),
            ),
            const SizedBox(height: 12),
            if (AppRoles.isRestaurantOwner(user)) ...[
              Text('Business', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              ProfileActionCard(
                icon: Icons.storefront_outlined,
                title: 'Restaurant Dashboard',
                subtitle: 'Manage menu, dishes, and view stats',
                iconColor: AppColors.gold,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RestaurantDashboardScreen()),
                ),
              ),
              ProfileActionCard(
                icon: Icons.add_business_outlined,
                title: 'Register Restaurant',
                subtitle: 'Submit a new restaurant for approval',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RestaurantRegisterScreen()),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (AppRoles.isAdmin(user)) ...[
              Text('Admin', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              ProfileActionCard(
                icon: Icons.dashboard_outlined,
                title: 'Admin Dashboard',
                subtitle: 'Platform analytics and moderation',
                iconColor: AppColors.gold,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                ),
              ),
              ProfileActionCard(
                icon: Icons.approval_outlined,
                title: 'Restaurant Approvals',
                subtitle: 'Review pending restaurant submissions',
                iconColor: AppColors.green,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminRestaurantApprovalsScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text('Preferences', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            _preferencesSummary(prefs),
            ProfileActionCard(
              icon: Icons.restaurant_menu,
              title: 'Nutrition Preferences',
              subtitle: _nutritionSubtitle(prefs),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NutritionPreferencesScreen(),
                ),
              ).then((_) => prefs.fetch(force: true)),
            ),
            ProfileActionCard(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Budget Preferences',
              subtitle: _budgetSubtitle(prefs),
              iconColor: AppColors.green,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BudgetPreferencesScreen(),
                ),
              ).then((_) => prefs.fetch(force: true)),
            ),
            ProfileActionCard(
              icon: Icons.logout,
              title: 'Logout',
              subtitle: 'Sign out of your account',
              destructive: true,
              onTap: () => _logout(context),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
