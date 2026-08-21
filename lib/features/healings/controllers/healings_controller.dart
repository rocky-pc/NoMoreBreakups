import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../feed/models/post_model.dart';

final healingPostsProvider = StateNotifierProvider<HealingsController, AsyncValue<List<PostModel>>>((ref) {
  return HealingsController();
});

class HealingsController extends StateNotifier<AsyncValue<List<PostModel>>> {
  HealingsController() : super(const AsyncValue.loading()) {
    fetchHealingStories();
  }

  final _supabase = Supabase.instance.client;

  Future<void> fetchHealingStories() async {
    final userId = _supabase.auth.currentUser?.id;
    try {
      state = const AsyncValue.loading();
      
      // Fetch posts of type 'story' (healing stories)
      final response = await _supabase
          .from('posts')
          .select('*, profiles(id, username, display_name, avatar_url), post_reactions(reaction_type)')
          .eq('post_type', 'story')
          .eq('post_reactions.user_id', userId ?? '')
          .order('created_at', ascending: false);
      
      final posts = (response as List).map((json) => PostModel.fromJson(json)).toList();
      state = AsyncValue.data(posts);
    } catch (e, st) {
      debugPrint('Error fetching healing stories: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleReaction(String postId, ReactionType reaction) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final existing = await _supabase
          .from('post_reactions')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        if (existing['reaction_type'] == reaction.name) {
          await _supabase.from('post_reactions').delete().eq('id', existing['id']);
        } else {
          await _supabase.from('post_reactions').update({'reaction_type': reaction.name}).eq('id', existing['id']);
        }
      } else {
        await _supabase.from('post_reactions').insert({
          'post_id': postId,
          'user_id': userId,
          'reaction_type': reaction.name,
        });
      }
      
      // Refresh local state (simplified for now, ideally optimistic update)
      fetchHealingStories();
    } catch (e) {
      debugPrint('Error toggling reaction: $e');
    }
  }
}
