import 'package:flutter/material.dart';

class UserProfile {
  final String id;
  final String username;
  final String? avatarUrl;
  final String bio;
  final String relationshipStatus;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.bio,
    required this.relationshipStatus,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'],
      bio: json['bio'] as String? ?? '',
      relationshipStatus: json['relationship_status'] as String? ?? 'Healing',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
