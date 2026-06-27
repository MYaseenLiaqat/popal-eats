import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/content_service.dart';
import '../services/restaurant_owner_service.dart';
import '../theme/app_colors.dart';
import '../utils/recommendation_copy.dart';
import '../widgets/ui/app_ui_widgets.dart';
import 'restaurant_post_screen.dart';

/// Restaurant content management — posts, stories, and reels for the home feed.
class RestaurantContentScreen extends StatefulWidget {
  const RestaurantContentScreen({super.key, required this.restaurantId});

  final int restaurantId;

  @override
  State<RestaurantContentScreen> createState() => _RestaurantContentScreenState();
}

class _RestaurantContentScreenState extends State<RestaurantContentScreen> {
  final _owner = RestaurantOwnerService();
  final _content = ContentService();
  List<Post> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant RestaurantContentScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.restaurantId != widget.restaurantId) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _posts = await _owner.listPosts(restaurantId: widget.restaurantId);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deletePost(Post post) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This will remove the post from the home feed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await _content.deletePost(post.id);
    _load();
  }

  Future<void> _createStory() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    try {
      await _content.createStory(bytes: file.bytes!, filename: file.name);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Story published to home feed')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(RecommendationCopy.friendlyError(e))),
      );
    }
  }

  Future<void> _createReel() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantPostScreen(
          restaurantId: widget.restaurantId,
          initialSubtype: 'promotion',
          reelMode: true,
        ),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'story',
            onPressed: _createStory,
            child: const Icon(Icons.auto_stories_outlined),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'reel',
            onPressed: _createReel,
            child: const Icon(Icons.play_circle_outline),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'post',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RestaurantPostScreen(restaurantId: widget.restaurantId),
                ),
              );
              _load();
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.accent,
              child: _posts.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(AppColors.screenPadding),
                      children: const [
                        SizedBox(height: 40),
                        EmptyState(
                          icon: Icons.campaign_outlined,
                          title: 'No content yet',
                          subtitle:
                              'Create home feed posts, stories, or promotional reels for your restaurant.',
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppColors.screenPadding),
                      itemCount: _posts.length,
                      itemBuilder: (context, index) {
                        final post = _posts[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ModernCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        post.title ?? post.caption ?? 'Restaurant post',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => _deletePost(post),
                                    ),
                                  ],
                                ),
                                if (post.restaurantContentSubtype != null)
                                  Text(
                                    post.typeLabel,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                const SizedBox(height: 6),
                                Text(
                                  '${post.likeCount} likes · ${post.commentCount} comments · ${post.saveCount} saves',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
