import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/post.dart';
import '../../theme/app_colors.dart';
import '../../utils/post_caption.dart';
import '../../utils/date_display.dart';
import '../../utils/media_url.dart';
import '../community_avatar.dart';
import 'feed_constants.dart';
import 'feed_media_frame.dart';
import 'post_fullscreen_viewer.dart';

typedef PostInteractionCallback = void Function(Post post);

/// Instagram-style social post card for the home feed.
class SocialPostCard extends StatefulWidget {
  const SocialPostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onSave,
    this.onComment,
    this.onRepost,
    this.onShare,
    this.onFollow,
    this.onViewRestaurant,
    this.onViewDish,
  });

  final Post post;
  final PostInteractionCallback? onLike;
  final PostInteractionCallback? onSave;
  final PostInteractionCallback? onComment;
  final PostInteractionCallback? onRepost;
  final PostInteractionCallback? onShare;
  final PostInteractionCallback? onFollow;
  final PostInteractionCallback? onViewRestaurant;
  final PostInteractionCallback? onViewDish;

  @override
  State<SocialPostCard> createState() => _SocialPostCardState();
}

class _SocialPostCardState extends State<SocialPostCard>
    with SingleTickerProviderStateMixin {
  bool _showHeart = false;
  late AnimationController _heartController;
  late Animation<double> _heartScale;

  bool get _isVideo =>
      widget.post.videoUrl != null && widget.post.videoUrl!.trim().isNotEmpty;

  String? get _thumbnailUrl {
    if (widget.post.images.isNotEmpty) {
      return resolveMediaUrl(widget.post.images.first);
    }
    if (_isVideo) return resolveMediaUrl(widget.post.videoUrl);
    return null;
  }

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _heartController, curve: Curves.easeOutCubic));
    _heartController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _showHeart = false);
        _heartController.reset();
      }
    });
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _triggerHeart() {
    setState(() => _showHeart = true);
    _heartController.forward(from: 0);
  }

  void _onDoubleTap() {
    if (!widget.post.likedByMe) {
      widget.onLike?.call(widget.post);
    }
    _triggerHeart();
  }

  Future<void> _openFullscreen() async {
    await openPostFullscreenViewer(
      context,
      post: widget.post,
      onLike: widget.onLike,
      onSave: widget.onSave,
      onComment: widget.onComment,
      onRepost: widget.onRepost,
      onShare: widget.onShare,
      onFollow: widget.onFollow,
      onViewRestaurant: widget.onViewRestaurant,
      onViewDish: widget.onViewDish,
    );
  }

  void _handleShare() {
    if (widget.onShare != null) {
      widget.onShare!(widget.post);
      return;
    }
    _handleRepost();
  }

  void _handleRepost() {
    if (widget.onRepost != null) {
      widget.onRepost!(widget.post);
      return;
    }
    Clipboard.setData(
      ClipboardData(text: widget.post.caption ?? widget.post.displayTitle),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Caption copied')),
    );
  }

  void _showMoreMenu() {
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
              leading: const Icon(Icons.link),
              title: const Text('Copy link'),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: 'post:${widget.post.id}'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final timeLabel =
        post.createdAt != null ? DateDisplay.formatRelativeUpdated(post.createdAt!) : null;

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 10),
          child: Row(
            children: [
              CommunityAvatar(name: post.authorName, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (timeLabel != null)
                      Text(
                        timeLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz),
                onPressed: _showMoreMenu,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            FeedMediaFrame(
              imageUrl: _thumbnailUrl,
              isVideo: _isVideo,
              heroTag: FeedConstants.heroTagForPost(post.id),
              onTap: _openFullscreen,
              onDoubleTap: _onDoubleTap,
            ),
            if (_showHeart)
              IgnorePointer(
                child: ScaleTransition(
                  scale: _heartScale,
                  child: Icon(
                    Icons.favorite,
                    color: Colors.white.withValues(alpha: 0.92),
                    size: 88,
                    shadows: const [Shadow(color: Colors.black54, blurRadius: 12)],
                  ),
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  post.likedByMe ? Icons.favorite : Icons.favorite_border,
                  color: post.likedByMe ? Colors.redAccent : null,
                ),
                onPressed: widget.onLike == null ? null : () => widget.onLike!(post),
              ),
              IconButton(
                icon: const Icon(Icons.mode_comment_outlined),
                onPressed: widget.onComment == null ? null : () => widget.onComment!(post),
              ),
              IconButton(
                icon: Icon(widget.onShare != null ? Icons.share_outlined : Icons.repeat_rounded),
                onPressed: _handleShare,
              ),
              IconButton(
                icon: Icon(
                  post.savedByMe ? Icons.bookmark : Icons.bookmark_border,
                  color: post.savedByMe ? AppColors.accent : null,
                ),
                onPressed: widget.onSave == null ? null : () => widget.onSave!(post),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.north_east),
                onPressed: _openFullscreen,
              ),
            ],
          ),
        ),
        if (post.likeCount > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(
              '${post.likeCount} like${post.likeCount == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
            ),
          ),
        if (post.postType == PostType.recipe && post.title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(
              post.title!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15),
            ),
          ),
        if (hasVisibleCaption(post.caption))
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: RichText(
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35),
                children: [
                  TextSpan(
                    text: '${post.authorName} ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: displayPostCaption(post.caption)),
                ],
              ),
            ),
          ),
        if (post.restaurantName != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
            child: Text(
              post.restaurantName!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        if (post.commentCount > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: GestureDetector(
              onTap: widget.onComment == null ? null : () => widget.onComment!(post),
              child: Text(
                'View all ${post.commentCount} comments',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
          ),
        if (widget.onViewRestaurant != null ||
            widget.onViewDish != null ||
            widget.onFollow != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (widget.onViewRestaurant != null)
                  OutlinedButton.icon(
                    onPressed: () => widget.onViewRestaurant!(post),
                    icon: const Icon(Icons.storefront_outlined, size: 18),
                    label: const Text('View Restaurant'),
                  ),
                if (widget.onViewDish != null)
                  OutlinedButton.icon(
                    onPressed: () => widget.onViewDish!(post),
                    icon: const Icon(Icons.restaurant_menu_outlined, size: 18),
                    label: const Text('View Dish'),
                  ),
                if (widget.onFollow != null && post.restaurantId != null)
                  TextButton.icon(
                    onPressed: () => widget.onFollow!(post),
                    icon: const Icon(Icons.person_add_outlined, size: 18),
                    label: const Text('Follow'),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Divider(height: 1, color: AppColors.border.withValues(alpha: 0.6)),
        ],
      ),
    );
  }
}
