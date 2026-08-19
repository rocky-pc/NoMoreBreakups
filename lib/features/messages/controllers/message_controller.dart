import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_model.dart';

final messageControllerProvider = Provider((ref) => MessageController());

class MessageController {
  final _supabase = Supabase.instance.client;

  Stream<List<MessageModel>> streamMessages(String conversationId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((data) => data.map((json) => MessageModel.fromJson(json)).toList());
  }

  Future<void> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
  }) async {
    final senderId = _supabase.auth.currentUser!.id;

    await _supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
    });
    
    // Also update conversation timestamp if needed
    // await _supabase.from('conversations').update({'updated_at': DateTime.now().toIso8601String()}).eq('id', conversationId);
  }

  Future<List<ConversationModel>> fetchConversations() async {
    final userId = _supabase.auth.currentUser!.id;
    
    // This is a complex query depending on schema. 
    // Simplified version assuming a conversations view or similar:
    try {
      final response = await _supabase
          .from('conversations')
          .select('*, user1:participant1(id, display_name, avatar_url), user2:participant2(id, display_name, avatar_url)')
          .or('participant1.eq.$userId,participant2.eq.$userId')
          .order('updated_at', ascending: false);

      return (response as List).map((json) {
        final isUser1 = json['participant1'] == userId;
        final otherUser = isUser1 ? json['user2'] : json['user1'];
        
        return ConversationModel(
          id: json['id'].toString(),
          otherUserId: otherUser['id'],
          otherUserName: otherUser['display_name'] ?? 'User',
          otherUserAvatar: otherUser['avatar_url'],
          lastMessage: json['last_message'] ?? '',
          updatedAt: DateTime.parse(json['updated_at']),
        );
      }).toList();
    } catch (e) {
      print('Error fetching conversations: $e');
      return [];
    }
  }
}
