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

  Stream<List<ConversationModel>> streamConversations() {
    final userId = _supabase.auth.currentUser!.id;
    return _supabase
        .from('conversations')
        .stream(primaryKey: ['id'])
        // Note: .or() is not supported on .stream(). 
        // We rely on Row Level Security (RLS) to filter conversations for the current user.
        .asyncMap((data) async {
          if (data.isEmpty) return [];

          // Filter in Dart as a fallback if RLS is not fully restrictive
          final myConversations = data.where((json) => 
            json['participant1'] == userId || json['participant2'] == userId
          ).toList();

          if (myConversations.isEmpty) return [];

          // Fetch all unique other user IDs
          final otherUserIds = myConversations.map((json) {
            final isUser1 = json['participant1'] == userId;
            return (isUser1 ? json['participant2'] : json['participant1']).toString();
          }).toSet().toList();

          // Fetch all profiles in one go for efficiency
          final profilesResponse = await _supabase
              .from('profiles')
              .select()
              .inFilter('id', otherUserIds);
          
          final profilesMap = {
            for (var p in (profilesResponse as List)) p['id'] as String: p
          };

          final List<ConversationModel> conversations = [];
          for (var json in myConversations) {
            final isUser1 = json['participant1'] == userId;
            final otherUserId = isUser1 ? json['participant2'] : json['participant1'];
            final profile = profilesMap[otherUserId];
            
            conversations.add(ConversationModel(
              id: json['id'].toString(),
              otherUserId: otherUserId,
              otherUserName: profile?['display_name'] ?? profile?['username'] ?? 'User',
              otherUserAvatar: profile?['avatar_url'],
              lastMessage: json['last_message'] ?? '',
              updatedAt: DateTime.parse(json['updated_at']),
            ));
          }
          
          // Sort by updated_at descending (latest first)
          conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return conversations;
        });
  }

  Future<String> getOrCreateConversation(String otherUserId) async {
    final myId = _supabase.auth.currentUser!.id;
    
    // Check if conversation exists (myId as participant1)
    var existing = await _supabase
        .from('conversations')
        .select()
        .eq('participant1', myId)
        .eq('participant2', otherUserId)
        .maybeSingle();
    
    if (existing == null) {
      // Check if conversation exists (myId as participant2)
      existing = await _supabase
          .from('conversations')
          .select()
          .eq('participant1', otherUserId)
          .eq('participant2', myId)
          .maybeSingle();
    }
    
    if (existing != null) {
      return existing['id'].toString();
    }
    
    // Create new conversation
    final response = await _supabase.from('conversations').insert({
      'participant1': myId,
      'participant2': otherUserId,
      'updated_at': DateTime.now().toIso8601String(),
      'last_message': '',
    }).select().single();
    
    return response['id'].toString();
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
    
    // Update conversation timestamp and last message
    await _supabase.from('conversations').update({
      'updated_at': DateTime.now().toIso8601String(),
      'last_message': content,
    }).eq('id', conversationId);
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
