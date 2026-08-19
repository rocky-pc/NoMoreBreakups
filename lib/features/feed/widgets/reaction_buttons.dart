import 'package:flutter/material.dart';

class ReactionButtons extends StatelessWidget {
  final int heartbreakCount;
  final int healingCount;
  final int commentCount;
  final bool? isHeartbreakActive;
  final bool? isHealingActive;
  final VoidCallback? onHeartbreak;
  final VoidCallback? onHealing;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  const ReactionButtons({
    super.key,
    required this.heartbreakCount,
    required this.healingCount,
    required this.commentCount,
    this.isHeartbreakActive,
    this.isHealingActive,
    this.onHeartbreak,
    this.onHealing,
    this.onComment,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        TextButton.icon(
          onPressed: onHeartbreak,
          icon: const Text('💔', style: TextStyle(fontSize: 16)),
          label: Text(
            '$heartbreakCount',
            style: TextStyle(
              color: isHeartbreakActive == true ? Colors.red : Colors.grey[700],
            ),
          ),
        ),

        TextButton.icon(
          onPressed: onHealing,
          icon: const Text('🩹', style: TextStyle(fontSize: 16)),
          label: Text(
            '$healingCount',
            style: TextStyle(
              color: isHealingActive == true ? Colors.teal : Colors.grey[700],
            ),
          ),
        ),

        TextButton.icon(
          onPressed: onComment,
          icon: const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey),
          label: Text('$commentCount', style: TextStyle(color: Colors.grey[700])),
        ),

        IconButton(
          icon: const Icon(Icons.share_outlined, size: 18, color: Colors.grey),
          onPressed: onShare,
        ),
      ],
    );
  }
}
