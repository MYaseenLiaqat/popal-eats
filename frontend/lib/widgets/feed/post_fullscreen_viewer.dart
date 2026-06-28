import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../models/post.dart';
import '../../theme/app_colors.dart';
import '../../utils/date_display.dart';
import '../../utils/media_url.dart';
import '../community_avatar.dart';
import 'feed_constants.dart';
import 'feed_shimmer.dart';
import 'post_comments_sheet.dart';

typedef PostAction = void Function(Post post);

/// Opens fullscreen Instagram-style viewer for feed posts (image or video).
Future<Post?> openPostFullscreenViewer(
  BuildContext context, {
  required Post post,
  PostAction? onLike,
  PostAction? onSave,
  PostAction? onComment,
  PostAction? onRepost,
  PostAction? onShare,
  PostAction? onFollow,
  PostAction? onViewRestaurant,
  PostAction? onViewDish,
}) {
  return Navigator.of(context).push<Post>(
    PageRouteBuilder<Post>(
      opaque: true,
      transitionDuration: FeedConstants.animDuration,
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (context, animation, secondaryAnimation) {
        return PostFullscreenViewer(
          post: post,
          onLike: onLike,
          onSave: onSave,
          onComment: onComment,
          onRepost: onRepost,
          onShare: onShare,
          onFollow: onFollow,
          onViewRestaurant: onViewRestaurant,
          onViewDish: onViewDish,
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: FeedConstants.animCurve),
          child: child,
        );
      },
    ),
  );
}

class PostFullscreenViewer extends StatefulWidget {
  const PostFullscreenViewer({
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
  final PostAction? onLike;
  final PostAction? onSave;
  final PostAction? onComment;
  final PostAction? onRepost;
  final PostAction? onShare;
  final PostAction? onFollow;
  final PostAction? onViewRestaurant;
  final PostAction? onViewDish;

  @override
  State<PostFullscreenViewer> createState() => _PostFullscreenViewerState();
}

class _PostFullscreenViewerState extends State<PostFullscreenViewer>
    with SingleTickerProviderStateMixin {
  late Post _post;
  VideoPlayerController? _videoController;
  bool _videoReady = false;
  bool _showHeart = false;
  late AnimationController _heartController;
  late Animation<double> _heartScale;

  bool get _isVideo =>
      widget.post.videoUrl != null && widget.post.videoUrl!.trim().isNotEmpty;

  String? get _imageUrl {
    if (widget.post.images.isNotEmpty) {
      return resolveMediaUrl(widget.post.images.first);
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _post = widget.post;
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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    if (_isVideo) _initVideo();
  }

  Future<void> _initVideo() async {
    final url = resolveMediaUrl(_post.videoUrl);
    if (url == null) return;
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _videoController = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() => _videoReady = true);
      await controller.setLooping(true);
      await controller.play();
    } catch (_) {
      if (mounted) setState(() => _videoReady = false);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _heartController.dispose();
    super.dispose();
  }

  void _triggerHeart() {
    setState(() => _showHeart = true);
    _heartController.forward(from: 0);
  }

  void _onDoubleTap() {
    if (!_post.likedByMe) {
      widget.onLike?.call(_post);
      setState(() {
        _post = _post.copyWith(
          likedByMe: true,
          likeCount: _post.likeCount + 1,
        );
      });
    }
    _triggerHeart();
  }

  void _handleLike() {
    widget.onLike?.call(_post);
    setState(() {
      _post = _post.copyWith(
        likedByMe: !_post.likedByMe,
        likeCount: _post.likedByMe ? _post.likeCount - 1 : _post.likeCount + 1,
      );
    });
  }

  void _handleSave() {
    widget.onSave?.call(_post);
    setState(() {
      _post = _post.copyWith(
        savedByMe: !_post.savedByMe,
        saveCount: _post.savedByMe ? _post.saveCount - 1 : _post.saveCount + 1,
      );
    });
  }

  void _handleRepost() {
    if (widget.onRepost != null) {
      widget.onRepost!(_post);
      return;
    }
    Clipboard.setData(ClipboardData(text: _post.caption ?? _post.displayTitle));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Caption copied')),
    );
  }

  void _showMore() {
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
                Clipboard.setData(ClipboardData(text: 'post:${_post.id}'));
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

  Widget _buildMedia() {
    final heroTag = FeedConstants.heroTagForPost(_post.id);

    Widget content;
    if (_isVideo) {
      if (_videoReady && _videoController != null) {
        content = Center(
          child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
        );
      } else {
        final thumb = _imageUrl ?? resolveMediaUrl(_post.videoUrl);
        content = Center(
          child: thumb != null
              ? Image.network(
                  thumb,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const FeedShimmer(child: SizedBox.expand());
                  },
                )
              : const FeedShimmer(child: SizedBox.expand()),
        );
      }
    } else if (_imageUrl != null) {
      content = InteractiveViewer(
        minScale: 1,
        maxScale: 3,
        child: Image.network(
          _imageUrl!,
          fit: BoxFit.contain,
          width: double.infinity,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const FeedShimmer(child: SizedBox.expand());
          },
          errorBuilder: (_, __, ___) => const Icon(
            Icons.broken_image_outlined,
            color: Colors.white54,
            size: 64,
          ),
        ),
      );
    } else {
      content = const Icon(Icons.image_not_supported_outlined, color: Colors.white54, size: 64);
    }

    return Hero(
      tag: heroTag,
      child: Material(type: MaterialType.transparency, child: content),
    );
  }

  void _close() => Navigator.pop(context, _post);

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final timeLabel = _post.createdAt != null
        ? DateDisplay.formatRelativeUpdated(_post.createdAt!)
        : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.pop(context, _post);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onDoubleTap: _onDoubleTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
            _buildMedia(),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _close,
              ),
            ),
            Positioned(
              right: 12,
              bottom: bottomPad + 120,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SideAction(
                    icon: _post.likedByMe ? Icons.favorite : Icons.favorite_border,
                    color: _post.likedByMe ? Colors.redAccent : Colors.white,
                    count: _post.likeCount,
                    onTap: _handleLike,
                  ),
                  const SizedBox(height: 18),
                  _SideAction(
                    icon: Icons.mode_comment_outlined,
                    count: _post.commentCount,
                    onTap: () {
                      widget.onComment?.call(_post);
                      showPostCommentsSheet(context, _post);
                    },
                  ),
                  const SizedBox(height: 18),
                  _SideAction(
                    icon: Icons.repeat_rounded,
                    onTap: _handleRepost,
                  ),
                  const SizedBox(height: 18),
                  _SideAction(
                    icon: _post.savedByMe ? Icons.bookmark : Icons.bookmark_border,
                    color: _post.savedByMe ? AppColors.accent : Colors.white,
                    count: _post.saveCount,
                    onTap: _handleSave,
                  ),
                  const SizedBox(height: 18),
                  _SideAction(
                    icon: Icons.more_horiz,
                    onTap: _showMore,
                  ),
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 72,
              bottom: bottomPad + 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      CommunityAvatar(name: _post.authorName, size: 36),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _post.authorName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_post.caption != null && _post.caption!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      _post.caption!,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ],
                  if (_post.restaurantName != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 14, color: Colors.white.withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _post.restaurantName!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (timeLabel != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      timeLabel,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (_post.dishName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '#${_post.dishName!.replaceAll(' ', '').toLowerCase()}',
                        style: TextStyle(
                          color: AppColors.accent.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  if (widget.onViewRestaurant != null ||
                      widget.onViewDish != null) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (widget.onViewRestaurant != null)
                          OutlinedButton(
                            onPressed: () => widget.onViewRestaurant!(_post),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                            ),
                            child: const Text('View Restaurant'),
                          ),
                        if (widget.onViewDish != null)
                          OutlinedButton(
                            onPressed: () => widget.onViewDish!(_post),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                            ),
                            child: const Text('View Dish'),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (_showHeart)
              IgnorePointer(
                child: Center(
                  child: ScaleTransition(
                    scale: _heartScale,
                    child: Icon(
                      Icons.favorite,
                      color: Colors.white.withValues(alpha: 0.92),
                      size: 96,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideAction extends StatelessWidget {
  const _SideAction({
    required this.icon,
    this.count,
    this.color = Colors.white,
    required this.onTap,
  });

  final IconData icon;
  final int? count;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          if (count != null && count! > 0) ...[
            const SizedBox(height: 4),
            Text(
              _formatCount(count!),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
