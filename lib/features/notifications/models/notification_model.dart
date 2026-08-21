enum NotificationType { like, heal, comment, follow }

class NotificationModel {
  final String id;
  final String receiverId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final NotificationType type;
  final String? postId;
  final String? healingId;
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
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final sender = json['profiles'];
    return NotificationModel(
      id: json['id'].toString(),
      receiverId: json['receiver_id'].toString(),
      senderId: json['sender_id'].toString(),
      senderName: sender?['display_name'] ?? sender?['username'] ?? 'Someone',
      senderAvatar: sender?['avatar_url'],
      type: _parseType(json['type']),
      postId: json['post_id']?.toString(),
      healingId: json['healing_id']?.toString(),
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  static NotificationType _parseType(String type) {
    switch (type) {
      case 'like': return NotificationType.like;
      case 'heal': return NotificationType.heal;
      case 'comment': return NotificationType.comment;
      case 'follow': return NotificationType.follow;
      default: return NotificationType.like;
    }
  }
}
