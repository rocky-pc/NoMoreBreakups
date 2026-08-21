import '../../feed/models/post_model.dart';

class HealingModel {
  final String id;
  final String userId;
  final String authorName;
  final String? authorAvatarUrl;
  final String content;
  final String? mediaUrl;
  final int reactionsCount;
  final int commentCount;
  final ReactionType? userReaction;
  final DateTime createdAt;

  HealingModel({
    required this.id,
    required this.userId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.content,
    this.mediaUrl,
    this.reactionsCount = 0,
    this.commentCount = 0,
    this.userReaction,
    required this.createdAt,
  });

  factory HealingModel.fromJson(Map<String, dynamic> json) {
    String? userReactionRaw = json['user_reaction'] as String?;
    if (userReactionRaw == null && json['healing_reactions'] != null) {
      final reactions = json['healing_reactions'] as List;
      if (reactions.isNotEmpty) {
        userReactionRaw = reactions.first['reaction_type'] as String?;
      }
    }

    return HealingModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      authorName: json['profiles']?['display_name'] ?? json['profiles']?['username'] ?? 'Anonymous',
      authorAvatarUrl: json['profiles']?['avatar_url'],
      content: json['content'] as String,
      mediaUrl: json['media_url'],
      reactionsCount: json['reactions_count'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      userReaction: userReactionRaw == 'healing' 
          ? ReactionType.healing 
          : (userReactionRaw == 'heartbreak' ? ReactionType.heartbreak : null),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
