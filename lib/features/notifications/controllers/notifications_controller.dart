import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

final notificationsProvider =
    StateNotifierProvider<NotificationController, AsyncValue<List<NotificationModel>>>((ref) {
  return NotificationController();
});

// Stream unread count for the app bar bell badge
final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return Stream.value(0);

  return Supabase.instance.client
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('receiver_id', userId)
      .map((events) => events.where((e) => e['is_read'] == false).length);
});

class NotificationController extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  NotificationController() : super(const AsyncValue.loading()) {
    fetchNotifications();
  }

  final _supabase = Supabase.instance.client;

  Future<void> fetchNotifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('notifications')
          .select('*, sender:sender_id(display_name, username, avatar_url)')
          .eq('receiver_id', userId)
          .order('created_at', ascending: false);

      final list = (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();

      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> markAllAsRead() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('receiver_id', userId)
        .eq('is_read', false);

    await fetchNotifications();
  }

  static Future<void> sendNotification({
    required String receiverId,
    required String type,
    String? postId,
    String? healingId,
    String? contentPreview,
  }) async {
    final supabase = Supabase.instance.client;
    final senderId = supabase.auth.currentUser?.id;
    if (senderId == null || senderId == receiverId) return;

    try {
      await supabase.from('notifications').insert({
        'receiver_id': receiverId,
        'sender_id': senderId,
        'type': type,
        'post_id': postId,
        'healing_id': healingId,
        'content_preview': contentPreview,
      });
    } catch (e) {
      print('Error sending in-app notification: $e');
    }
  }
}
