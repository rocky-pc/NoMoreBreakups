import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:no_more_breakups/core/utils/date_formatter.dart';
import 'package:no_more_breakups/features/feed/models/post_model.dart';
import '../../profile/screens/profile_screen.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final Function(ReactionType) onReact;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback? onMore;
  final double? height;

  const PostCard({
    super.key,
    required this.post,
    required this.onReact,
    required this.onComment,
    required this.onShare,
    this.onMore,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final isHeartbreak = post.userReaction == ReactionType.heartbreak;
    final isHealing = post.userReaction == ReactionType.healing;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: height ?? 650,
      ),
      color: colorScheme.surface,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── HEADER ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileScreen(userId: post.userId),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      backgroundImage: post.authorAvatarUrl != null
                          ? CachedNetworkImageProvider(post.authorAvatarUrl!)
                          : null,
                      child: post.authorAvatarUrl == null
                          ? Icon(
                        Icons.person,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileScreen(userId: post.userId),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.authorName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            post.postType == PostType.advice ? '💡 Advice' : '📖 Story',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: post.postType == PostType.advice
                                  ? Colors.teal
                                  : Colors.deepOrange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    icon: Icon(
                      Icons.more_horiz,
                      size: 22,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onMore,
                  ),
                ],
              ),
            ),

            // ─── MEDIA ────────────────────────────────────────────────
            if (post.mediaUrl != null)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: height != null ? (height! * 0.6) : 400,
                ),
                child: CachedNetworkImage(
                  imageUrl: post.mediaUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 320,
                    color: colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),

            // ─── ACTIONS ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 2),
              child: Row(
                children: [
                  // Heartbreak → changes to pink heart when selected
                  _ActionButton(
                    onTap: () => onReact(ReactionType.heartbreak),
                    child: Icon(
                      isHeartbreak
                          ? Icons.favorite_rounded          // ← filled heart
                          : Icons.heart_broken_rounded,     // ← broken heart
                      size: 24,
                      color: isHeartbreak
                          ? const Color(0xFFFF2D55)         // ← Instagram-style pink
                          : colorScheme.onSurface,
                    ),
                  ),

                  // Healing
                  _ActionButton(
                    onTap: () => onReact(ReactionType.healing),
                    child: Icon(
                      Icons.healing_rounded,
                      size: 24,
                      color: isHealing
                          ? Colors.teal
                          : colorScheme.onSurface,
                    ),
                  ),

                  // Comment
                  _ActionButton(
                    onTap: onComment,
                    child: Icon(
                      Icons.chat_outlined,
                      size: 22,
                      color: colorScheme.onSurface,
                    ),
                  ),

                  // Share
                  _ActionButton(
                    onTap: onShare,
                    child: Icon(
                      Icons.rocket_launch_outlined,
                      size: 23,
                      color: colorScheme.onSurface,
                    ),
                  ),

                  const Spacer(),

                  // Bookmark
                  IconButton(
                    icon: Icon(
                      Icons.bookmark_border_rounded,
                      size: 24,
                      color: colorScheme.onSurface,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // ─── COUNTS ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  if (post.heartbreakCount > 0 || post.healingCount > 0) ...[
                    Text(
                      '${post.heartbreakCount + post.healingCount} reactions',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  GestureDetector(
                    onTap: onComment,
                    child: Text(
                      post.commentCount > 0
                          ? 'View all ${post.commentCount} comments'
                          : 'Add a comment...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── CAPTION ──────────────────────────────────────────────
            if (post.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                child: RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      height: 1.35,
                    ),
                    children: [
                      TextSpan(
                        text: '${post.authorName}  ',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: post.content),
                    ],
                  ),
                ),
              ),

            // ─── TIMESTAMP ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
              child: Text(
                // DateFormatter.timeAgo(post.createdAt).toUpperCase(),
                '2 HOURS AGO',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  letterSpacing: 0.3,
                ),
              ),
            ),

            // Subtle divider
            Divider(
              height: 1,
              thickness: 0.6,
              color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _ActionButton({
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: child,
      ),
    );
  }
}