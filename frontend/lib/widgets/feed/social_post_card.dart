import 'package:flutter/material.dart';

import '../../models/post.dart';
import '../../theme/app_colors.dart';
import '../../utils/media_url.dart';
import '../community_avatar.dart';
import '../ui/app_ui_widgets.dart';

typedef PostInteractionCallback = void Function(Post post);

/// User-generated content card for the home feed.
class SocialPostCard extends StatelessWidget {
  const SocialPostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onSave,
    this.onComment,
    this.onTap,
  });

  final Post post;
  final PostInteractionCallback? onLike;
  final PostInteractionCallback? onSave;
  final PostInteractionCallback? onComment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = post.images.isNotEmpty ? resolveMediaUrl(post.images.first) : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: ModernCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                children: [
                  CommunityAvatar(name: post.authorName, size: 40),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          post.typeLabel,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (imageUrl != null)
              GestureDetector(
                onTap: onTap,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.surfaceLight,
                      child: const Icon(Icons.broken_image_outlined, size: 48),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          post.likedByMe ? Icons.favorite : Icons.favorite_border,
                          color: post.likedByMe ? Colors.redAccent : null,
                        ),
                        onPressed: onLike == null ? null : () => onLike!(post),
                      ),
                      IconButton(
                        icon: const Icon(Icons.mode_comment_outlined),
                        onPressed: onComment == null ? null : () => onComment!(post),
                      ),
                      IconButton(
                        icon: Icon(
                          post.savedByMe ? Icons.bookmark : Icons.bookmark_border,
                          color: post.savedByMe ? AppColors.gold : null,
                        ),
                        onPressed: onSave == null ? null : () => onSave!(post),
                      ),
                      const Spacer(),
                      if (post.likeCount > 0)
                        Text(
                          '${post.likeCount} likes',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                  if (post.postType == PostType.recipe && post.title != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        post.title!,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  if (post.caption != null && post.caption!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium,
                          children: [
                            TextSpan(
                              text: '${post.authorName} ',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            TextSpan(text: post.caption),
                          ],
                        ),
                      ),
                    ),
                  if (post.restaurantName != null || post.dishName != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          if (post.restaurantName != null)
                            Chip(
                              label: Text(post.restaurantName!),
                              visualDensity: VisualDensity.compact,
                            ),
                          if (post.dishName != null)
                            Chip(
                              label: Text(post.dishName!),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    ),
                  if (post.commentCount > 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                      child: TextButton(
                        onPressed: onComment == null ? null : () => onComment!(post),
                        child: Text('View all ${post.commentCount} comments'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
