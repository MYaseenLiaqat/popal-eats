import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/ui/app_ui_widgets.dart';
import 'friend_requests_screen.dart';
import 'budget_preferences_screen.dart';
import 'health_dashboard_screen.dart';
import 'login_screen.dart';
import 'nutrition_preferences_screen.dart';

/// Profile — FYP dark theme layout.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _mockAvgDay = 1840;
  static const _mockGoal = 2100;
  static const _mockProgress = 0.88;
  static const _weekBars = [0.6, 0.75, 0.7, 0.85, 0.65, 0.9, 0.72];

  Future<void> _logout(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    await auth.logout();
    if (!context.mounted) return;
    context.read<CartProvider>().reset();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final name = user?['full_name']?.toString() ?? 'Guest';
    final email = user?['email']?.toString() ?? '—';
    final progressPct = (_mockProgress * 100).round();
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(AppColors.screenPadding),
        children: [
          ModernCard(
            gradient: AppColors.headerGradient,
            borderColor: AppColors.gold.withValues(alpha: 0.4),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
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
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(email, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly analytics',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Calorie overview',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(_weekBars.length, (i) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Flexible(
                                child: FractionallySizedBox(
                                  heightFactor: _weekBars[i],
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          AppColors.green.withValues(alpha: 0.5),
                                          AppColors.gold.withValues(alpha: 0.9),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                days[i],
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              StatChip(
                label: 'Avg/Day',
                value: '$_mockAvgDay kcal',
              ),
              SizedBox(width: 8),
              StatChip(
                label: 'Goal',
                value: '$_mockGoal kcal',
                accent: AppColors.green,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '$progressPct%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.green,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: _mockProgress,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.goldGradient,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Preferences', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ProfileActionCard(
            icon: Icons.monitor_heart_outlined,
            title: 'Health Dashboard',
            subtitle: 'Weekly stats & nutrition insights',
            iconColor: AppColors.green,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const HealthDashboardScreen(),
              ),
            ),
          ),
          ProfileActionCard(
            icon: Icons.restaurant_menu,
            title: 'Nutrition Preferences',
            subtitle: 'Calorie goal, cuisines & diet type',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NutritionPreferencesScreen(),
              ),
            ),
          ),
          ProfileActionCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Budget Preferences',
            subtitle: 'Weekly & monthly spending limits',
            iconColor: AppColors.green,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const BudgetPreferencesScreen(),
              ),
            ),
          ),
          ProfileActionCard(
            icon: Icons.people_outline,
            title: 'Friend Requests',
            subtitle: 'Connect with friends',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FriendRequestsScreen(),
              ),
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
    );
  }
}
