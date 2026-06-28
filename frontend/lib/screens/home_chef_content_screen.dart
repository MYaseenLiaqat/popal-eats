import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/content_service.dart';
import '../services/home_chef_owner_service.dart';
import '../theme/app_colors.dart';
import '../utils/recommendation_copy.dart';
import '../widgets/ui/app_ui_widgets.dart';
import 'create_recipe_screen.dart';

/// Home chef content — cooking posts, stories, reels for the home feed.
class HomeChefContentScreen extends StatefulWidget {
  const HomeChefContentScreen({super.key});

  @override
  State<HomeChefContentScreen> createState() => _HomeChefContentScreenState();
}

class _HomeChefContentScreenState extends State<HomeChefContentScreen> {
  final _owner = HomeChefOwnerService();
  final _content = ContentService();
  List<Post> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _posts = await _owner.listPosts();
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
    if (result == null || result.files.isEmpty || result.files.first.bytes == null) return;
    final file = result.files.first;
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

  Future<void> _createChefPost() async {
    final caption = TextEditingController();
    final title = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cooking post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 8),
            TextField(
              controller: caption,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Caption'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Post')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _content.createPost({
        'post_type': 'chef_post',
        if (title.text.trim().isNotEmpty) 'title': title.text.trim(),
        if (caption.text.trim().isNotEmpty) 'caption': caption.text.trim(),
      });
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(RecommendationCopy.friendlyError(e))),
      );
    } finally {
      title.dispose();
      caption.dispose();
    }
  }

  Future<void> _createRecipePost() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateRecipeScreen()),
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
            heroTag: 'chef_story',
            onPressed: _createStory,
            child: const Icon(Icons.auto_stories_outlined),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'chef_recipe',
            onPressed: _createRecipePost,
            child: const Icon(Icons.menu_book_outlined),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'chef_post',
            onPressed: _createChefPost,
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
                          icon: Icons.soup_kitchen_outlined,
                          title: 'No content yet',
                          subtitle:
                              'Share cooking posts, stories, recipes, and tips on the home feed.',
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
                                        post.title ?? post.caption ?? 'Chef post',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => _deletePost(post),
                                    ),
                                  ],
                                ),
                                Text(post.typeLabel, style: Theme.of(context).textTheme.bodySmall),
                                const SizedBox(height: 6),
                                Text(
                                  '${post.likeCount} likes · ${post.commentCount} comments',
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
