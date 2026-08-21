import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_model.dart';

final messageControllerProvider = Provider((ref) => MessageController());

final conversationsStreamProvider = StreamProvider<List<ConversationModel>>((ref) {
  return ref.watch(messageControllerProvider).streamConversations();
});

final messagesStreamProvider = StreamProvider.family<List<MessageModel>, String>((ref, conversationId) {
  return ref.watch(messageControllerProvider).streamMessages(conversationId);
});

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
        .asyncMap((data) async {
          if (data.isEmpty) return [];

          final myConversations = data.where((json) => 
            json['participant1'] == userId || json['participant2'] == userId
          ).toList();

          if (myConversations.isEmpty) return [];

          final otherUserIds = myConversations.map((json) {
            final isUser1 = json['participant1'] == userId;
            return (isUser1 ? json['participant2'] : json['participant1']).toString();
          }).toSet().toList();

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
          
          conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return conversations;
        });
  }

  Future<String> getOrCreateConversation(String otherUserId) async {
    final myId = _supabase.auth.currentUser!.id;
    
    var existing = await _supabase
        .from('conversations')
        .select()
        .eq('participant1', myId)
        .eq('participant2', otherUserId)
        .maybeSingle();
    
    if (existing == null) {
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
    MessageType messageType = MessageType.text,
    String? mediaUrl,
  }) async {
    final senderId = _supabase.auth.currentUser!.id;

    await _supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'message_type': messageType.name,
      'media_url': mediaUrl,
    });
    
    await _updateConversation(conversationId, content, messageType);
  }

  Future<void> sendMediaMessage({
    required String conversationId,
    required String receiverId,
    required File file,
    MessageType messageType = MessageType.image,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final fileExt = file.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'chat/$conversationId/$fileName';

      // 1. Upload to Supabase 'messages' storage bucket
      await _supabase.storage.from('messages').upload(
        filePath,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      // 2. Get Public URL
      final mediaUrl = _supabase.storage.from('messages').getPublicUrl(filePath);

      final content = messageType == MessageType.image ? '📷 Photo' : (messageType == MessageType.audio ? '🎤 Voice message' : '📎 Media');

      // 3. Insert record into messages table
      await _supabase.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': user.id,
        'receiver_id': receiverId,
        'content': content,
        'message_type': messageType.name,
        'media_url': mediaUrl,
      });

      await _updateConversation(conversationId, content, messageType);
    } catch (e) {
      print('Error sending media message: $e');
    }
  }

  Future<void> _updateConversation(String conversationId, String content, MessageType messageType) async {
    await _supabase.from('conversations').update({
      'updated_at': DateTime.now().toIso8601String(),
      'last_message': content,
    }).eq('id', conversationId);
  }

  // Deprecated: use sendMediaMessage
  Future<String?> uploadMedia(File file, String bucket) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final path = 'chat/$fileName';
      await _supabase.storage.from(bucket).upload(path, file);
      return _supabase.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      print('Error uploading media: $e');
      return null;
    }
  }

  Future<List<ConversationModel>> fetchConversations() async {
    final userId = _supabase.auth.currentUser!.id;
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
