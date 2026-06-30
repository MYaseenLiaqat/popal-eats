import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/post.dart';
import '../models/story.dart';
import '../providers/auth_provider.dart';
import '../providers/home_feed_provider.dart';
import '../providers/reels_provider.dart';
import '../services/content_service.dart';
import '../services/restaurant_follow_store.dart';
import '../theme/app_colors.dart';
import '../widgets/app_logo.dart';
import '../utils/app_roles.dart';
import 'reels_screen.dart';
import '../utils/post_caption.dart';
import '../utils/recommendation_copy.dart';
import '../widgets/feed/feed_loading_skeleton.dart';
import '../widgets/feed/post_comments_sheet.dart';
import '../widgets/feed/social_post_card.dart';
import '../widgets/home/home_create_sheet.dart';
import '../widgets/home/home_reels_section.dart';
import '../widgets/home/home_stories_section.dart';
import '../widgets/social/notification_hub_button.dart';
import '../widgets/ui/app_ui_widgets.dart';
import 'dish_detail_screen.dart';
import 'main_shell.dart';
import 'restaurant_detail_screen.dart';
import 'search_users_screen.dart';
import 'story_viewer_screen.dart';

/// Social home feed — stories, reels, friend posts, restaurant dishes, chef recipes.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.isTabActive = true});

  final bool isTabActive;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _content = ContentService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(force: false));
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isTabActive && widget.isTabActive) {
      _load(force: true);
    }
  }

  Future<void> _load({required bool force}) async {
    final feed = context.read<HomeFeedProvider>();
    final reels = context.read<ReelsProvider>();
    await Future.wait([
      feed.fetch(force: force),
      reels.fetch(force: force),
    ]);
  }

  void _openReels() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReelsScreen()),
    );
  }

  Future<void> _openCreate() async {
    final created = await showHomeCreateSheet(context);
    if (!mounted || !created) return;
    await _load(force: true);
    if (!mounted) return;
    context.read<ReelsProvider>().fetch(force: true);
  }

  Future<void> _createStory() async {
    final created = await showCreateStorySheet(context);
    if (!mounted || created != true) return;
    await _load(force: true);
  }

  void _openFindFriends() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchUsersScreen()),
    );
  }

  void _updatePost(Post updated) {
    context.read<HomeFeedProvider>().updatePost(updated);
  }

  Future<void> _toggleLike(Post post) async {
    try {
      if (post.likedByMe) {
        await _content.unlikePost(post.id);
        _updatePost(post.copyWith(
          likedByMe: false,
          likeCount: (post.likeCount - 1).clamp(0, 999999),
        ));
      } else {
        await _content.likePost(post.id);
        _updatePost(post.copyWith(likedByMe: true, likeCount: post.likeCount + 1));
      }
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
        _updatePost(post.copyWith(
          savedByMe: false,
          saveCount: (post.saveCount - 1).clamp(0, 999999),
        ));
      } else {
        await _content.savePost(post.id);
        _updatePost(post.copyWith(savedByMe: true, saveCount: post.saveCount + 1));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(RecommendationCopy.friendlyError(e))),
      );
    }
  }

  void _sharePost(Post post) {
    final caption = displayPostCaption(post.caption);
    final text = '${post.authorName}: ${caption.isNotEmpty ? caption : post.displayTitle}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied to clipboard')),
    );
  }

  Future<void> _followRestaurant(Post post) async {
    final id = post.restaurantId;
    if (id == null) return;
    await RestaurantFollowStore.toggle(id);
  }

  void _viewRestaurant(Post post) {
    final id = post.restaurantId;
    if (id == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RestaurantDetailScreen(restaurantId: id)),
    );
  }

  void _viewDish(Post post) {
    final id = post.dishId;
    if (id == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DishDetailScreen(dishId: id)),
    );
  }

  void _openComments(Post post) {
    showPostCommentsSheet(context, post);
  }

  void _openStoryGroup(StoryGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StoryViewerScreen(group: group)),
    );
  }

  void _openProfile() {
    context.findAncestorStateOfType<MainShellState>()?.navigateToTab(MainShellState.profileTab);
  }

  PostInteraction _postHandlers(Post post) => PostInteraction(
        onLike: _toggleLike,
        onSave: _toggleSave,
        onComment: _openComments,
        onShare: _sharePost,
        onFollow: _followRestaurant,
        onViewRestaurant: post.restaurantId != null ? _viewRestaurant : null,
        onViewDish: post.dishId != null ? _viewDish : null,
      );

  Widget _postsEmptySliver() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
        child: Column(
          children: [
            const EmptyState(
              icon: Icons.people_outline,
              title: 'No posts yet',
              subtitle: 'Follow friends, restaurants, and home chefs to see food in your feed.',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _openCreate,
              icon: const Icon(Icons.add),
              label: const Text('Create your first post'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.onAccent,
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _openFindFriends,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Find Friends'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final feed = context.watch<HomeFeedProvider>();
    final userId = auth.user?['id'] as int?;
    final isCustomer = AppRoles.isCustomer(auth.user);
    final posts = feed.posts;
    final initialLoad = feed.loadingFeed && posts.isEmpty && feed.storyGroups.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const AppLogo(size: 32, showShadow: false),
            const SizedBox(width: 10),
            const Text('Popal Eats'),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: _openProfile,
          ),
          const NotificationHubButton(),
        ],
      ),
      body: initialLoad
          ? const FeedLoadingSkeleton()
          : RefreshIndicator(
              onRefresh: () => _load(force: true),
              color: AppColors.accent,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: HomeStoriesSection(
                      groups: feed.storyGroups,
                      loading: feed.loadingStories,
                      currentUserId: userId,
                      showOwnStorySlot: isCustomer,
                      onCreateTap: isCustomer ? _createStory : null,
                      onGroupTap: _openStoryGroup,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: HomeReelsSection(onOpenReels: _openReels),
                  ),
                  if (feed.feedError != null && posts.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Text(feed.feedError!, textAlign: TextAlign.center),
                            TextButton(
                              onPressed: () => _load(force: true),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (!feed.loadingFeed && posts.isEmpty)
                    _postsEmptySliver()
                  else if (posts.isNotEmpty)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final post = posts[index];
                          final handlers = _postHandlers(post);
                          return SocialPostCard(
                            post: post,
                            onLike: handlers.onLike,
                            onSave: handlers.onSave,
                            onComment: handlers.onComment,
                            onShare: handlers.onShare,
                            onFollow: handlers.onFollow,
                            onViewRestaurant: handlers.onViewRestaurant,
                            onViewDish: handlers.onViewDish,
                          );
                        },
                        childCount: posts.length,
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
      floatingActionButton: isCustomer
          ? FloatingActionButton(
              onPressed: _openCreate,
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.onAccent,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class PostInteraction {
  const PostInteraction({
    this.onLike,
    this.onSave,
    this.onComment,
    this.onShare,
    this.onFollow,
    this.onViewRestaurant,
    this.onViewDish,
  });

  final void Function(Post post)? onLike;
  final void Function(Post post)? onSave;
  final void Function(Post post)? onComment;
  final void Function(Post post)? onShare;
  final void Function(Post post)? onFollow;
  final void Function(Post post)? onViewRestaurant;
  final void Function(Post post)? onViewDish;
}
