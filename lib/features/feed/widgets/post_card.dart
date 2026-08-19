import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:no_more_breakups/core/utils/date_formatter.dart';
import 'package:no_more_breakups/features/feed/models/post_model.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final Function(ReactionType) onReact;
  final VoidCallback onComment;
  final VoidCallback onShare;

  const PostCard({
    super.key,
    required this.post,
    required this.onReact,
    required this.onComment,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: post.authorAvatarUrl != null
                      ? CachedNetworkImageProvider(post.authorAvatarUrl!)
                      : null,
                  child: post.authorAvatarUrl == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      post.postType == PostType.advice ? '💡 Advice' : '📖 Story',
                      style: TextStyle(
                        fontSize: 11,
                        color: post.postType == PostType.advice ? Colors.teal : Colors.deepOrange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(post.content, style: const TextStyle(fontSize: 14, height: 1.4)),
            const SizedBox(height: 10),

            if (post.mediaUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: post.mediaUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 12),
            const Divider(height: 1),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton.icon(
                  onPressed: () => onReact(ReactionType.heartbreak),
                  icon: const Text('💔', style: TextStyle(fontSize: 16)),
                  label: Text(
                    '${post.heartbreakCount}',
                    style: TextStyle(
                      color: post.userReaction == ReactionType.heartbreak ? Colors.red : Colors.grey[700],
                    ),
                  ),
                ),

                TextButton.icon(
                  onPressed: () => onReact(ReactionType.healing),
                  icon: const Text('🩹', style: TextStyle(fontSize: 16)),
                  label: Text(
                    '${post.healingCount}',
                    style: TextStyle(
                      color: post.userReaction == ReactionType.healing ? Colors.teal : Colors.grey[700],
                    ),
                  ),
                ),

                TextButton.icon(
                  onPressed: onComment,
                  icon: const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey),
                  label: Text('${post.commentCount}', style: TextStyle(color: Colors.grey[700])),
                ),

                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 18, color: Colors.grey),
                  onPressed: onShare,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
