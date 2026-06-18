import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/food_feed_item.dart';
import '../models/group_decision.dart';
import '../models/group_session.dart';
import '../models/recommendation.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/friends_provider.dart';
import '../providers/group_provider.dart';
import '../providers/onboarding_provider.dart';
import '../providers/preferences_provider.dart';
import '../providers/reels_provider.dart';
import '../services/feed_image_loader.dart';
import '../services/food_feed_builder.dart';
import '../services/group_service.dart';
import '../services/recommendation_service.dart';
import '../theme/app_colors.dart';
import '../widgets/feed/food_feed_card.dart';
import '../widgets/ui/app_ui_widgets.dart';
import 'admin_dashboard_screen.dart';
import 'dish_detail_screen.dart';
import 'group_decision_screen.dart';
import 'group_recommendations_screen.dart';
import 'menu_upload_screen.dart';
import '../widgets/cart_icon_button.dart';
import '../widgets/social/notification_hub_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onRecommendationsTap});

  final VoidCallback? onRecommendationsTap;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _recommendations = RecommendationService();
  final _groups = GroupService();
  final _imageLoader = FeedImageLoader();

  List<FoodFeedItem> feedItems = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CartProvider>().load();
    });
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final recResults = await Future.wait([
        _recommendations.list(),
        _recommendations.trending(limit: 10),
      ]);
      final personalized = recResults[0];
      final trending = recResults[1];

      if (!mounted) return;
      final groupProvider = context.read<GroupProvider>();
      await groupProvider.fetchGroups(force: true);
      final sessions = groupProvider.groups;

      final groupDecisions =
          await _loadGroupDecisions(sessions.where((s) => s.isActive).take(3));

      final dishIds = <int>{
        ...personalized.map((r) => r.dishId),
        ...trending.map((r) => r.dishId),
        ...groupDecisions
            .map((e) => e.decision.dishId)
            .whereType<int>(),
      };

      final images = await _imageLoader.loadImages(dishIds);

      if (!mounted) return;
      setState(() {
        feedItems = FoodFeedBuilder.build(
          personalized: personalized,
          trending: trending,
          groupDecisions: groupDecisions,
          dishImages: images,
        );
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<List<({GroupSession session, GroupDecision decision})>> _loadGroupDecisions(
    Iterable<GroupSession> sessions,
  ) async {
    final results = <({GroupSession session, GroupDecision decision})>[];

    await Future.wait(sessions.map((session) async {
      try {
        final decision = await _groups.getDecision(session.id);
        if (_isInterestingDecision(decision)) {
          results.add((session: session, decision: decision));
        }
      } catch (_) {
        // Skip groups without a decision endpoint response.
      }
    }));

    results.sort((a, b) {
      int rank(GroupDecision d) {
        if (d.isAgreed) return 0;
        if (d.isConsidering) return 1;
        if (d.isPending) return 2;
        return 3;
      }

      return rank(a.decision).compareTo(rank(b.decision));
    });

    return results;
  }

  bool _isInterestingDecision(GroupDecision decision) {
    return decision.isPending ||
        decision.isConsidering ||
        decision.isAgreed ||
        decision.dishId != null;
  }

  void _openDiscover() {
    if (widget.onRecommendationsTap != null) {
      widget.onRecommendationsTap!();
    }
  }

  void _onFeedTap(FoodFeedItem item) {
    switch (item.kind) {
      case FoodFeedKind.recommended:
      case FoodFeedKind.trending:
        if (item.dishId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DishDetailScreen(dishId: item.dishId!),
            ),
          );
        }
        break;
      case FoodFeedKind.groupDecision:
        if (item.groupSessionId == null) return;
        if (item.groupAgreed) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GroupDecisionScreen(
                sessionId: item.groupSessionId!,
                groupName: item.groupName,
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GroupRecommendationsScreen(
                sessionId: item.groupSessionId!,
                groupName: item.groupName,
              ),
            ),
          );
        }
        break;
      case FoodFeedKind.discover:
        _openDiscover();
        break;
      case FoodFeedKind.friendPlaceholder:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.user?['full_name']?.toString() ?? 'Guest';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Popal Eats'),
        actions: [
          const NotificationHubButton(),
          const CartIconButton(),
          if (auth.user?['role'] == 'admin')
            IconButton(
              icon: const Icon(Icons.dashboard),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
              ),
            ),
          if (auth.user?['role'] == 'admin')
            IconButton(
              icon: const Icon(Icons.upload_file),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MenuUploadScreen()),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (!context.mounted) return;
              context.read<CartProvider>().reset();
              context.read<OnboardingProvider>().reset();
              context.read<FriendsProvider>().reset();
              context.read<GroupProvider>().reset();
              context.read<PreferencesProvider>().reset();
              context.read<ReelsProvider>().reset();
            },
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        EmptyState(
                          icon: Icons.cloud_off_outlined,
                          title: 'Could not load your feed',
                          subtitle: error,
                        ),
                        const SizedBox(height: 12),
                        TextButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.gold,
                  child: ListView(
                    padding: const EdgeInsets.all(AppColors.screenPadding),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, $name',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(color: AppColors.gold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your food feed',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      if (feedItems.isEmpty)
                        const ModernCard(
                          child: EmptyState(
                            icon: Icons.restaurant_outlined,
                            title: 'Nothing in your feed yet',
                            subtitle: 'Pull to refresh or explore Discover for picks.',
                          ),
                        )
                      else
                        ...feedItems.map((item) {
                          final tappable = item.kind == FoodFeedKind.discover ||
                              item.kind == FoodFeedKind.recommended ||
                              item.kind == FoodFeedKind.trending ||
                              item.kind == FoodFeedKind.groupDecision;

                          return FoodFeedCard(
                            item: item,
                            onTap: tappable ? () => _onFeedTap(item) : null,
                          );
                        }),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
    );
  }
}
