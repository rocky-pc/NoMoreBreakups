import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:no_more_breakups/core/constants/app_colors.dart';
import 'package:no_more_breakups/core/utils/date_formatter.dart';
import 'package:no_more_breakups/features/healings/models/healing_model.dart';

class HealingPostCard extends StatelessWidget {
  final HealingModel post;
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.08)
              : AppColors.rose.withOpacity(0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : AppColors.rose.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Author Avatar with Gradient Ring
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.rose.withOpacity(0.8),
                        AppColors.rose.withOpacity(0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
                    backgroundImage: post.authorAvatarUrl != null
                        ? CachedNetworkImageProvider(post.authorAvatarUrl!)
                        : null,
                    child: post.authorAvatarUrl == null
                        ? const Icon(Icons.person, size: 20, color: AppColors.rose)
                        : null,
                  ),
                ),

                const SizedBox(width: 12),

                // 2. Right Content Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author Name, Timestamp & Mood Badge
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              post.authorName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            formatRelativeTime(post.createdAt),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isDarkMode ? Colors.white38 : Colors.black38,
                              fontSize: 11,
                            ),
                          ),
                          const Spacer(),
                          _buildMoodBadge(post.mood, isDarkMode),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Content Body
                      Text(
                        post.content,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.45,
                          fontSize: 14.5,
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.92)
                              : Colors.black87,
                          letterSpacing: 0.1,
                        ),
                      ),

                      // Post Image (Medium Constrained Aspect Ratio)
                      if (post.mediaUrl != null) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.white10
                                    : Colors.black.withOpacity(0.05),
                              ),
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxHeight: 220,
                                minHeight: 120,
                              ),
                              child: CachedNetworkImage(
                                imageUrl: post.mediaUrl!,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  height: 160,
                                  color: isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.04),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.rose,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => const SizedBox(
                                  height: 100,
                                  child: Icon(Icons.broken_image_rounded, color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),

                      // 3. Action Bar with Micro-interactions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Healing / Empathy Heart Button
                          _ActionButton(
                            icon: post.hasReacted
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            label: '${post.reactionsCount}',
                            isActive: post.hasReacted,
                            activeColor: AppColors.rose,
                            onTap: onReact,
                          ),

                          // Comments Button
                          _ActionButton(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: '${post.reactionsCount}', // Or post.commentCount
                            onTap: onComment,
                          ),

                          // Share Button
                          _ActionButton(
                            icon: Icons.share_outlined,
                            onTap: onShare,
                          ),

                          const SizedBox(width: 12),
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

  // Dynamic Mood Tag with matching emoji
  Widget _buildMoodBadge(String mood, bool isDarkMode) {
    String emoji = '🕊️';
    final lower = mood.toLowerCase();
    if (lower.contains('heal')) emoji = '🩹';
    if (lower.contains('hope')) emoji = '✨';
    if (lower.contains('let')) emoji = '🍃';
    if (lower.contains('grat')) emoji = '💖';
    if (lower.contains('reflect')) emoji = '🌙';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppColors.rose.withOpacity(0.18)
            : AppColors.rose.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.rose.withOpacity(0.2),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 10.5)),
          const SizedBox(width: 3.5),
          Text(
            mood,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.rose,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Reusable Action Button with soft hover / tap feedback
// ---------------------------------------------------------------------
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final bool isActive;
  final Color? activeColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    this.label,
    this.isActive = false,
    this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDarkMode ? Colors.white60 : Colors.black45;
    final displayColor = isActive ? (activeColor ?? AppColors.rose) : defaultColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isActive ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutBack,
                child: Icon(
                  icon,
                  size: 18,
                  color: displayColor,
                ),
              ),
              if (label != null && label != '0') ...[
                const SizedBox(width: 5),
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: displayColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}