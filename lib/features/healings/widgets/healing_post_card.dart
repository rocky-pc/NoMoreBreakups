import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:no_more_breakups/core/constants/app_colors.dart';
import 'package:no_more_breakups/core/utils/date_formatter.dart';
import 'package:no_more_breakups/features/feed/models/post_model.dart';

class HealingPostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onReact;
  final VoidCallback onComment;
  final VoidCallback onShare;

  const HealingPostCard({
    super.key,
    required this.post,
    required this.onReact,
    required this.onComment,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar on the left
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.rose.withOpacity(0.1),
            backgroundImage: post.authorAvatarUrl != null
                ? CachedNetworkImageProvider(post.authorAvatarUrl!)
                : null,
            child: post.authorAvatarUrl == null
                ? const Icon(Icons.person, size: 20, color: AppColors.rose)
                : null,
          ),
          const SizedBox(width: 12),
          // Content on the right
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      post.authorName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '• ${formatRelativeTime(post.createdAt)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  post.content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                    fontSize: 15,
                    color: isDarkMode ? Colors.white.withOpacity(0.9) : Colors.black87,
                  ),
                ),
                
                // Mini size photo concept
                if (post.mediaUrl != null) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: CachedNetworkImage(
                        imageUrl: post.mediaUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey.withOpacity(0.1),
                          height: 150,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                
                // Actions (X-style)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ActionButton(
                      icon: post.userReaction == ReactionType.healing 
                          ? Icons.favorite_rounded 
                          : Icons.favorite_outline_rounded,
                      label: (post.heartbreakCount + post.healingCount).toString(),
                      color: post.userReaction == ReactionType.healing ? AppColors.rose : null,
                      onTap: onReact,
                    ),
                    _ActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: post.commentCount.toString(),
                      onTap: onComment,
                    ),
                    _ActionButton(
                      icon: Icons.ios_share_rounded,
                      onTap: onShare,
                    ),
                    const SizedBox(width: 20), // Spacer
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: color ?? Colors.grey.shade600,
          ),
          if (label != null) ...[
            const SizedBox(width: 4),
            Text(
              label!,
              style: TextStyle(
                fontSize: 13,
                color: color ?? Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
