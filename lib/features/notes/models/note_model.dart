class NoteModel {
  final String id;
  final String userId;
  final String username;
  final String? avatarUrl;
  final String content;
  final DateTime expiresAt;

  const NoteModel({
    required this.id,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.content,
    required this.expiresAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      username: json['users']?['username'] ?? 'User',
      avatarUrl: json['users']?['avatar_url'],
      content: json['content'] as String,
      expiresAt: DateTime.parse(json['expires_at']),
    );
  }
}
