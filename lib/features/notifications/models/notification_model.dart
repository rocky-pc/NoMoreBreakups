class NotificationModel {
  final String id;
  final String receiverId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String type; // 'heartbreak', 'heal', 'comment', 'follow'
  final String? postId;
  final String? healingId;
  final String? contentPreview;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.receiverId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.type,
    this.postId,
    this.healingId,
    this.contentPreview,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] ?? json['profiles'];
    return NotificationModel(
      id: json['id'].toString(),
      receiverId: json['receiver_id'].toString(),
      senderId: json['sender_id'].toString(),
      senderName: sender?['display_name'] ?? sender?['username'] ?? 'Anonymous',
      senderAvatar: sender?['avatar_url'],
      type: json['type'] ?? 'like',
      postId: json['post_id']?.toString(),
      healingId: json['healing_id']?.toString(),
      contentPreview: json['content_preview'] as String?,
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
