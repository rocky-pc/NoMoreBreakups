import 'package:flutter/material.dart';

enum PostType { story, advice }

enum ReactionType { heartbreak, healing }

class PostModel {
  final String id;
  final String userId;
  final String authorName;
  final String? authorAvatarUrl;
  final PostType postType;
  final String content;
  final String? mediaUrl;
  final List<String> tags;
  final int heartbreakCount;
  final int healingCount;
  final int commentCount;
  final ReactionType? userReaction;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.userId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.postType,
    required this.content,
    this.mediaUrl,
    this.tags = const [],
    this.heartbreakCount = 0,
    this.healingCount = 0,
    this.commentCount = 0,
    this.userReaction,
    required this.createdAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    // Handle user reaction from join if available
    String? userReactionRaw = json['user_reaction'] as String?;
    if (userReactionRaw == null && json['post_reactions'] != null) {
      final reactions = json['post_reactions'] as List;
      if (reactions.isNotEmpty) {
        userReactionRaw = reactions.first['reaction_type'] as String?;
      }
    }

    return PostModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      authorName: json['profiles']?['display_name'] ?? json['profiles']?['username'] ?? 'Anonymous',
      authorAvatarUrl: json['profiles']?['avatar_url'],
      postType: json['post_type'] == 'advice' ? PostType.advice : PostType.story,
      content: json['content'] as String,
      mediaUrl: json['media_url'],
      tags: List<String>.from(json['tags'] ?? []),
      heartbreakCount: json['heartbreak_count'] ?? 0,
      healingCount: json['healing_count'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      userReaction: userReactionRaw == 'heartbreak' 
          ? ReactionType.heartbreak 
          : (userReactionRaw == 'healing' ? ReactionType.healing : null),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
