import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/post.dart';
import '../models/story.dart';
import '../providers/auth_provider.dart';
import '../services/content_service.dart';
import '../theme/app_colors.dart';
import '../utils/recommendation_copy.dart';
import '../widgets/feed/feed_loading_skeleton.dart';
import '../widgets/feed/feed_stories_row.dart';
import '../widgets/feed/home_reels_entry.dart';
import '../widgets/feed/post_comments_sheet.dart';
import '../widgets/feed/social_post_card.dart';
import '../widgets/social/notification_hub_button.dart';
import 'dish_detail_screen.dart';
import 'main_shell.dart';
import 'reels_screen.dart';
import 'restaurant_detail_screen.dart';
import 'story_viewer_screen.dart';

/// Social content discovery — reels, stories, and restaurant posts only.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _content = ContentService();

  List<Post> posts = [];
  List<StoryGroup> storyGroups = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final results = await Future.wait([
        _content.fetchHomeFeed(limit: 20),
        _content.fetchStories().catchError((_) => <StoryGroup>[]),
      ]);
      if (!mounted) return;
      setState(() {
        posts = results[0] as List<Post>;
        storyGroups = results[1] as List<StoryGroup>;
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

  void _updatePost(Post updated) {
    setState(() {
      posts = posts.map((p) => p.id == updated.id ? updated : p).toList();
    });
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
    final text = '${post.authorName}: ${post.caption ?? post.displayTitle}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied to clipboard')),
    );
  }

  void _followRestaurant(Post post) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Following ${post.restaurantName ?? 'restaurant'}')),
    );
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

  void _openReels() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReelsScreen()),
    );
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userId = auth.user?['id'] as int?;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Popal Eats'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.slow_motion_video_outlined),
            tooltip: 'Reels',
            onPressed: _openReels,
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: _openProfile,
          ),
          const NotificationHubButton(),
        ],
      ),
      body: loading
          ? const FeedLoadingSkeleton()
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        TextButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.accent,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                          child: FeedStoriesRow(
                            groups: storyGroups,
                            currentUserId: userId,
                            onGroupTap: _openStoryGroup,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(child: HomeReelsEntry(onTap: _openReels)),
                      if (posts.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(child: Text('No posts yet — check back soon')),
                        )
                      else
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
    );
  }
}

/// Bundled interaction callbacks for a feed post.
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
