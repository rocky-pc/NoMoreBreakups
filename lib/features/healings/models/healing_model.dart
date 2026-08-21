import '../../feed/models/post_model.dart';

class HealingModel {
  final String id;
  final String userId;
  final String authorName;
  final String? authorAvatarUrl;
  final String content;
  final String? mediaUrl;
  final String mood;
  final int reactionsCount;
  final int commentCount;
  final bool hasReacted;
  final DateTime createdAt;

  HealingModel({
    required this.id,
    required this.userId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.content,
    this.mediaUrl,
    required this.mood,
    this.reactionsCount = 0,
    this.commentCount = 0,
    this.hasReacted = false,
    required this.createdAt,
  });

  factory HealingModel.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final profile = json['profiles'];
    final reactions = json['healing_reactions'] as List?;
    final hasReacted = currentUserId != null &&
        reactions != null &&
        reactions.any((r) => r['user_id'] == currentUserId);

    return HealingModel(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      authorName: profile?['display_name'] ?? profile?['username'] ?? 'Anonymous',
      authorAvatarUrl: profile?['avatar_url'],
      content: json['content'] as String,
      mediaUrl: json['media_url'],
      mood: json['mood'] ?? 'Healing',
      reactionsCount: json['reactions_count'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      hasReacted: hasReacted,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
