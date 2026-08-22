import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final callControllerProvider = Provider((ref) => CallController());

class CallController {
  final _supabase = Supabase.instance.client;

  // 1. Initiate a call
  Future<String> startCall({
    required String receiverId,
    required String callType, // 'audio' or 'video'
  }) async {
    final callerId = _supabase.auth.currentUser!.id;
    final channelName = 'call_${DateTime.now().millisecondsSinceEpoch}';

    await _supabase.from('calls').insert({
      'caller_id': callerId,
      'receiver_id': receiverId,
      'channel_name': channelName,
      'call_type': callType,
      'status': 'ringing',
    });

    return channelName;
  }

  // 2. Accept call
  Future<void> acceptCall(String callId) async {
    await _supabase.from('calls').update({'status': 'accepted'}).eq('id', callId);
  }

  // 3. End or Decline call
  Future<void> endCall(String channelName) async {
    await _supabase.from('calls').update({'status': 'ended'}).eq('channel_name', channelName);
  }

  // 4. Stream incoming calls for the current user
  Stream<List<Map<String, dynamic>>> streamIncomingCalls() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();

    return _supabase
        .from('calls')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', userId)
        .order('created_at', ascending: false);
  }
}
