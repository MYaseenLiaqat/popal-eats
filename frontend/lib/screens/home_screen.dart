import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/food_feed_item.dart';
import '../models/group_decision.dart';
import '../models/group_session.dart';
import '../models/post.dart';
import '../models/recommendation.dart';
import '../models/story.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/group_provider.dart';
import '../services/content_service.dart';
import '../services/feed_image_loader.dart';
import '../services/food_feed_builder.dart';
import '../services/group_service.dart';
import '../services/recommendation_service.dart';
import '../theme/app_colors.dart';
import '../utils/recommendation_copy.dart';
import '../widgets/feed/feed_stories_row.dart';
import '../widgets/feed/food_feed_card.dart';
import '../widgets/feed/post_comments_sheet.dart';
import '../widgets/feed/social_post_card.dart';
import '../widgets/ui/app_ui_widgets.dart';
import '../widgets/cart_icon_button.dart';
import '../widgets/social/notification_hub_button.dart';
import 'create_post_screen.dart';
import 'create_recipe_screen.dart';
import 'dish_detail_screen.dart';
import 'group_decision_screen.dart';
import 'group_recommendations_screen.dart';
import 'story_viewer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onRecommendationsTap});

  final VoidCallback? onRecommendationsTap;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _recommendations = RecommendationService();
  final _groups = GroupService();
  final _content = ContentService();
  final _imageLoader = FeedImageLoader();

  List<FoodFeedItem> feedItems = [];
  List<Post> socialPosts = [];
  List<StoryGroup> storyGroups = [];
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
        _content.fetchHomeFeed(limit: 15).catchError((_) => <Post>[]),
        _content.fetchStories().catchError((_) => <StoryGroup>[]),
      ]);
      final personalized = recResults[0] as List<Recommendation>;
      final trending = recResults[1] as List<Recommendation>;
      final posts = recResults[2] as List<Post>;
      final stories = recResults[3] as List<StoryGroup>;

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
        socialPosts = posts;
        storyGroups = stories;
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
        error = RecommendationCopy.friendlyError(e);
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
      } catch (_) {}
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
    widget.onRecommendationsTap?.call();
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

  void _showCreateMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.restaurant, color: AppColors.gold),
              title: const Text('Food post'),
              onTap: () async {
                Navigator.pop(ctx);
                final result = await Navigator.push<Post>(
                  context,
                  MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                );
                if (result != null) _load();
              },
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_outlined, color: AppColors.green),
              title: const Text('Recipe'),
              onTap: () async {
                Navigator.pop(ctx);
                final result = await Navigator.push<Post>(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateRecipeScreen()),
                );
                if (result != null) _load();
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_stories_outlined, color: AppColors.gold),
              title: const Text('Story'),
              subtitle: const Text('Visible for 24 hours'),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await showCreateStorySheet(context);
                if (ok == true) _load();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onStoryCreate() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.user?['id'] as int?;
    final ownGroup = userId == null
        ? null
        : storyGroups.where((g) => g.user.id == userId).firstOrNull;

    if (ownGroup != null && ownGroup.stories.isNotEmpty) {
      final choice = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: AppColors.surface,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: const Text('View your story'),
                onTap: () => Navigator.pop(ctx, 'view'),
              ),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Add to story'),
                onTap: () => Navigator.pop(ctx, 'add'),
              ),
            ],
          ),
        ),
      );
      if (choice == 'view' && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StoryViewerScreen(group: ownGroup),
          ),
        );
        return;
      }
    }

    final ok = await showCreateStorySheet(context);
    if (ok == true) _load();
  }

  void _openStoryGroup(StoryGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StoryViewerScreen(group: group)),
    ).then((_) => _load());
  }

  Future<void> _toggleLike(Post post) async {
    try {
      if (post.likedByMe) {
        await _content.unlikePost(post.id);
      } else {
        await _content.likePost(post.id);
      }
      setState(() {
        socialPosts = socialPosts.map((p) {
          if (p.id != post.id) return p;
          return p.copyWith(
            likedByMe: !p.likedByMe,
            likeCount: p.likedByMe ? p.likeCount - 1 : p.likeCount + 1,
          );
        }).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(RecommendationCopy.friendlyError(e))),
      );
    }
  }

  Future<void> _toggleSave(Post post) async {
    try {
      if (post.savedByMe) {
        await _content.unsavePost(post.id);
      } else {
        await _content.savePost(post.id);
      }
      setState(() {
        socialPosts = socialPosts.map((p) {
          if (p.id != post.id) return p;
          return p.copyWith(
            savedByMe: !p.savedByMe,
            saveCount: p.savedByMe ? p.saveCount - 1 : p.saveCount + 1,
          );
        }).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(RecommendationCopy.friendlyError(e))),
      );
    }
  }

  List<Widget> _buildMergedFeed() {
    final widgets = <Widget>[];
    var postIdx = 0;
    var feedIdx = 0;

    while (postIdx < socialPosts.length || feedIdx < feedItems.length) {
      if (postIdx < socialPosts.length) {
        final post = socialPosts[postIdx++];
        widgets.add(
          SocialPostCard(
            post: post,
            onLike: _toggleLike,
            onSave: _toggleSave,
            onComment: (p) => showPostCommentsSheet(context, p),
          ),
        );
      }
      for (var i = 0; i < 2 && feedIdx < feedItems.length; i++) {
        final item = feedItems[feedIdx++];
        final tappable = item.kind == FoodFeedKind.discover ||
            item.kind == FoodFeedKind.recommended ||
            item.kind == FoodFeedKind.trending ||
            item.kind == FoodFeedKind.groupDecision;
        widgets.add(
          FoodFeedCard(
            item: item,
            onTap: tappable ? () => _onFeedTap(item) : null,
          ),
        );
      }
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.user?['full_name']?.toString() ?? 'Guest';
    final userId = auth.user?['id'] as int?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Popal Eats'),
        actions: [
          IconButton(
            tooltip: 'Create post',
            icon: const Icon(Icons.add_box_outlined),
            onPressed: _showCreateMenu,
          ),
          const NotificationHubButton(),
          const CartIconButton(),
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
                          subtitle: RecommendationCopy.friendlyError(error),
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
                      FeedStoriesRow(
                        groups: storyGroups,
                        currentUserId: userId,
                        onCreateTap: _onStoryCreate,
                        onGroupTap: _openStoryGroup,
                      ),
                      const SizedBox(height: 12),
                      if (socialPosts.isEmpty && feedItems.isEmpty)
                        const ModernCard(
                          child: EmptyState(
                            icon: Icons.restaurant_outlined,
                            title: 'Nothing in your feed yet',
                            subtitle: 'Create a post or pull to refresh for picks.',
                          ),
                        )
                      else
                        ..._buildMergedFeed(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
    );
  }
}

