import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/theme_mode_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/friends_provider.dart';
import '../providers/group_provider.dart';
import '../providers/home_feed_provider.dart';
import '../providers/onboarding_provider.dart';
import '../providers/preferences_provider.dart';
import '../providers/recommendation_provider.dart';
import '../providers/reels_provider.dart';
import '../theme/app_colors.dart';
import '../utils/app_roles.dart';
import '../utils/preference_display.dart';
import '../utils/user_display.dart';
import '../widgets/profile/profile_health_dashboard_card.dart';
import '../widgets/ui/app_ui_widgets.dart';
import '../widgets/social/notification_hub_button.dart';
import 'budget_preferences_screen.dart';
import 'nutrition_preferences_screen.dart';
import 'orders_screen.dart';
import 'restaurant_register_screen.dart';
import 'saved_posts_screen.dart';
import 'saved_recipes_screen.dart';
import 'admin/admin_shell.dart';
import 'admin/admin_nav.dart';

/// Customer profile — identity, embedded health dashboard, and preferences.
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
      context.read<PreferencesProvider>().fetch(force: false);
      context.read<FriendsProvider>().fetchFriends(force: false);
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
    context.read<RecommendationProvider>().reset();
    context.read<ReelsProvider>().reset();
    context.read<HomeFeedProvider>().reset();
  }

  String _nutritionSubtitle(PreferencesProvider prefs) {
    if (prefs.loading && prefs.preferences == null) return 'Loading…';
    if (prefs.error != null && prefs.preferences == null) return 'Tap to retry';
    final data = prefs.preferences;
    if (data == null) return 'Calorie goal, cuisines & diet type';
    final diet = PreferenceDisplay.dietLabelFromBackend(data.dietaryPreferences);
    final cuisines = PreferenceDisplay.summarizeCuisines(data.favoriteCuisines);
    return '$diet · $cuisines';
  }

  String _budgetSubtitle(PreferencesProvider prefs) {
    if (prefs.loading && prefs.preferences == null) return 'Loading…';
    if (prefs.error != null && prefs.preferences == null) return 'Tap to retry';
    final data = prefs.preferences;
    if (data == null) return 'Weekly & monthly spending limits';
    return PreferenceDisplay.budgetLabelFromBackend(data.budgetLevel);
  }

  String _dietSubtitle(PreferencesProvider prefs) {
    final data = prefs.preferences;
    if (data == null) return 'Vegetarian, halal, keto, and more';
    return PreferenceDisplay.dietLabelFromBackend(data.dietaryPreferences);
  }

  String _allergiesSubtitle(PreferencesProvider prefs) {
    final data = prefs.preferences;
    if (data == null || data.allergies.isEmpty) return 'None set';
    return data.allergies.map(PreferenceDisplay.allergyLabel).join(', ');
  }

  Widget _statColumn(BuildContext context, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
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
    final name = user?['full_name']?.toString() ?? 'Guest';
    final handle = UserDisplay.handle(
      username: user?['username']?.toString(),
      email: user?['email']?.toString(),
      userId: user?['id'] as int?,
    );
    final following = friends.loadingFriends && friends.friendsCount == 0
        ? '—'
        : '${friends.friendsCount}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: const [NotificationHubButton()],
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () async {
          await prefs.fetch(force: true);
          await friends.fetchFriends(force: true);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppColors.screenPadding),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            ModernCard(
              gradient: AppColors.headerGradient,
              borderColor: AppColors.accent.withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.onAccent,
                          ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(name, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    handle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _statColumn(context, '0', 'Followers'),
                      _statColumn(context, following, 'Following'),
                      _statColumn(context, '0', 'Posts'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const ProfileHealthDashboardCard(),
            const SizedBox(height: 16),
            Text('Preferences', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ProfileActionCard(
              icon: Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              title: 'Appearance',
              subtitle: Theme.of(context).brightness == Brightness.dark
                  ? 'Dark mode · tap for light'
                  : 'Light mode · tap for dark',
              iconColor: Theme.of(context).colorScheme.primary,
              onTap: () {
                final theme = context.read<ThemeModeProvider>();
                final isDark = Theme.of(context).brightness == Brightness.dark;
                theme.setMode(isDark ? ThemeMode.light : ThemeMode.dark);
              },
            ),
            ProfileActionCard(
              icon: Icons.restaurant_menu,
              title: 'Nutrition Preferences',
              subtitle: _nutritionSubtitle(prefs),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NutritionPreferencesScreen()),
              ).then((_) => prefs.fetch(force: true)),
            ),
            ProfileActionCard(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Budget Preferences',
              subtitle: _budgetSubtitle(prefs),
              iconColor: AppColors.accent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BudgetPreferencesScreen()),
              ).then((_) => prefs.fetch(force: true)),
            ),
            ProfileActionCard(
              icon: Icons.eco_outlined,
              title: 'Diet Preferences',
              subtitle: _dietSubtitle(prefs),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NutritionPreferencesScreen()),
              ).then((_) => prefs.fetch(force: true)),
            ),
            ProfileActionCard(
              icon: Icons.health_and_safety_outlined,
              title: 'Allergies',
              subtitle: _allergiesSubtitle(prefs),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NutritionPreferencesScreen()),
              ).then((_) => prefs.fetch(force: true)),
            ),
            ProfileActionCard(
              icon: Icons.menu_book_outlined,
              title: 'Saved Recipes',
              subtitle: 'Recipes you bookmarked from the feed',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavedRecipesScreen()),
              ),
            ),
            ProfileActionCard(
              icon: Icons.bookmark_border,
              title: 'Saved Posts',
              subtitle: 'Posts you saved for later',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavedPostsScreen()),
              ),
            ),
            if (AppRoles.isRestaurantRoleOnly(user)) ...[
              const SizedBox(height: 12),
              Text('Business', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              ProfileActionCard(
                icon: Icons.add_business_outlined,
                title: 'Register Restaurant',
                subtitle: 'Restaurant, food chain, or home kitchen — one business portal',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RestaurantRegisterScreen()),
                ),
              ),
            ],
            if (AppRoles.isAdmin(user)) ...[
              const SizedBox(height: 12),
              Text('Admin', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              ProfileActionCard(
                icon: Icons.dashboard_outlined,
                title: 'Admin Portal',
                subtitle: 'Platform analytics and moderation',
                iconColor: AppColors.accent,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminShell()),
                ),
              ),
              ProfileActionCard(
                icon: Icons.approval_outlined,
                title: 'Business Approvals',
                subtitle: 'Review pending restaurant and home chef accounts',
                iconColor: AppColors.accent,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminShell(initialSection: AdminSection.approvals),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            ProfileActionCard(
              icon: Icons.receipt_long_outlined,
              title: 'My Orders',
              subtitle: 'Order history and delivery status',
              iconColor: AppColors.accent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrdersScreen()),
              ),
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
