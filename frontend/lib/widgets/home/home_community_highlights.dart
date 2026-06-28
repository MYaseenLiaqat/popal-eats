import 'package:flutter/material.dart';

import '../../models/post.dart';
import '../../theme/app_colors.dart';
import '../../utils/media_url.dart';
import 'home_constants.dart';
import 'home_network_image.dart';
import 'home_section_header.dart';

class HomeCommunityHighlights extends StatelessWidget {
  const HomeCommunityHighlights({
    super.key,
    required this.posts,
    this.onSeeAll,
    this.onPostTap,
  });

  final List<Post> posts;
  final VoidCallback? onSeeAll;
  final ValueChanged<Post>? onPostTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionHeader(
          title: 'Community Highlights',
          subtitle: posts.isEmpty ? 'See what food lovers are sharing' : 'Latest from your community',
          icon: Icons.groups_outlined,
          onSeeAll: onSeeAll,
        ),
        if (posts.isEmpty)
          const HomeSectionEmpty(
            icon: Icons.photo_camera_outlined,
            title: 'No community posts yet',
            subtitle: 'Join the conversation on the Community tab',
          )
        else
          SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: posts.length.clamp(0, 5),
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final post = posts[index];
                return _CommunityPreviewCard(
                  post: post,
                  onTap: () => onPostTap?.call(post),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _CommunityPreviewCard extends StatefulWidget {
  const _CommunityPreviewCard({required this.post, this.onTap});

  final Post post;
  final VoidCallback? onTap;

  @override
  State<_CommunityPreviewCard> createState() => _CommunityPreviewCardState();
}

class _CommunityPreviewCardState extends State<_CommunityPreviewCard> {
  bool _hovered = false;

  String? get _thumb {
    if (widget.post.images.isNotEmpty) {
      return resolveMediaUrl(widget.post.images.first);
    }
    if (widget.post.videoUrl != null && widget.post.videoUrl!.trim().isNotEmpty) {
      return resolveMediaUrl(widget.post.videoUrl);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final lift = _hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Transform.scale(
          scale: lift ? 1.03 : 1.0,
          child: AnimatedContainer(
            duration: HomeConstants.animDuration,
            curve: HomeConstants.animCurve,
            width: 160,
            decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(HomeConstants.cardRadius),
            border: Border.all(
              color: lift
                  ? AppColors.accent.withValues(alpha: 0.4)
                  : AppColors.borderStrong.withValues(alpha: 0.5),
            ),
            boxShadow: lift ? AppColors.cardShadow(elevated: true) : AppColors.cardShadow(),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: HomeNetworkImage(
                  url: _thumb,
                  width: 160,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(HomeConstants.cardRadius),
                  ),
                  fallbackIcon: Icons.image_outlined,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.post.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                    if (widget.post.caption != null && widget.post.caption!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.post.caption!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.favorite, size: 12, color: Colors.redAccent.withValues(alpha: 0.9)),
                        const SizedBox(width: 4),
                        Text('${widget.post.likeCount}', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

/// Reusable compact empty state for home sections.
class HomeSectionEmpty extends StatelessWidget {
  const HomeSectionEmpty({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(HomeConstants.cardRadius),
          border: Border.all(color: AppColors.borderStrong.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.accent, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                  ],
                  if (onRetry != null) ...[
                    const SizedBox(height: 8),
                    TextButton(onPressed: onRetry, child: const Text('Retry')),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
