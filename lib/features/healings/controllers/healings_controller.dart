import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:no_more_breakups/features/notifications/controllers/notifications_controller.dart';
import '../models/healing_model.dart';

final healingsProvider = StateNotifierProvider<HealingsNotifier, AsyncValue<List<HealingModel>>>((ref) {
  return HealingsNotifier();
});

class HealingsNotifier extends StateNotifier<AsyncValue<List<HealingModel>>> {
  HealingsNotifier() : super(const AsyncValue.loading()) {
    fetchHealings();
  }

  final _supabase = Supabase.instance.client;

  Future<void> fetchHealings() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      final response = await _supabase
          .from('healings')
          .select('*, profiles(display_name, username, avatar_url), healing_reactions(user_id)')
          .order('created_at', ascending: false);

      final healings = (response as List)
          .map((json) => HealingModel.fromJson(json, currentUserId: currentUserId))
          .toList();

      state = AsyncValue.data(healings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createHealing({
    required String content,
    required String mood,
    File? imageFile,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    String? mediaUrl;
    if (imageFile != null) {
      final fileExt = imageFile.path.split('.').last;
      final fileName = 'healing_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '${user.id}/$fileName';

      await _supabase.storage.from('post-images').upload(
        filePath,
        imageFile,
        fileOptions: const FileOptions(upsert: true),
      );
      mediaUrl = _supabase.storage.from('post-images').getPublicUrl(filePath);
    }

    await _supabase.from('healings').insert({
      'user_id': user.id,
      'content': content,
      'mood': mood,
      'media_url': mediaUrl,
    });

    await fetchHealings();
  }

  Future<void> toggleReaction(String healingId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Optimistic UI update
    state.whenData((healings) {
      state = AsyncValue.data(healings.map((h) {
        if (h.id == healingId) {
          final isReacted = !h.hasReacted;
          return HealingModel(
            id: h.id,
            userId: h.userId,
            authorName: h.authorName,
            authorAvatarUrl: h.authorAvatarUrl,
            content: h.content,
            mediaUrl: h.mediaUrl,
            mood: h.mood,
            reactionsCount: isReacted ? h.reactionsCount + 1 : (h.reactionsCount > 0 ? h.reactionsCount - 1 : 0),
            hasReacted: isReacted,
            createdAt: h.createdAt,
          );
        }
        return h;
      }).toList());
    });

    // Database sync
    final existing = await _supabase
        .from('healing_reactions')
        .select()
        .eq('healing_id', healingId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (existing != null) {
      await _supabase.from('healing_reactions').delete().eq('id', existing['id']);
    } else {
      await _supabase.from('healing_reactions').insert({
        'healing_id': healingId,
        'user_id': user.id,
        'reaction_type': 'healing',
      });

      // Trigger notification
      state.whenData((healings) {
        final item = healings.firstWhere((h) => h.id == healingId);
        NotificationController.sendNotification(
          receiverId: item.userId,
          type: 'heal',
          healingId: healingId,
        );
      });
    }
  }
}
