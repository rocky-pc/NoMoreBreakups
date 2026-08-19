import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:no_more_breakups/features/feed/models/post_model.dart';

final feedPostsProvider = StateNotifierProvider<FeedController, List<PostModel>>((ref) {
  return FeedController();
});

class FeedController extends StateNotifier<List<PostModel>> {
  FeedController() : super([]);

  Future<void> fetchPosts() async {
    try {
      // Fetch posts with profiles and counts
      final response = await Supabase.instance.client
          .from('posts')
          .select('*, profiles(username, display_name, avatar_url)')
          .order('created_at', ascending: false);
      
      final posts = (response as List).map((json) => PostModel.fromJson(json)).toList();
      state = posts;
    } catch (e) {
      debugPrint('Error fetching posts: $e');
    }
  }

  Future<void> toggleHeartbreak(String postId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Check if already reacted
      final existing = await Supabase.instance.client
          .from('post_reactions')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        // Remove reaction
        await Supabase.instance.client
            .from('post_reactions')
            .delete()
            .eq('id', existing['id']);
      } else {
        // Add heartbreak reaction
        await Supabase.instance.client.from('post_reactions').insert({
          'post_id': postId,
          'user_id': userId,
          'reaction_type': 'heartbreak',
        });
      }
      
      // Refresh posts to update counts in UI
      await fetchPosts();
    } catch (e) {
      debugPrint('Error toggling heartbreak: $e');
    }
  }

  void updatePostReaction(String postId, ReactionType reaction) {
    state = state.map((post) {
      if (post.id != postId) return post;

      final newReaction = post.userReaction == reaction ? null : reaction;
      int heartbreak = post.heartbreakCount;
      int healing = post.healingCount;

      if (post.userReaction == ReactionType.heartbreak) heartbreak--;
      if (post.userReaction == ReactionType.healing) healing--;

      if (newReaction == ReactionType.heartbreak) heartbreak++;
      if (newReaction == ReactionType.healing) healing++;

      return PostModel(
        id: post.id,
        userId: post.userId,
        authorName: post.authorName,
        authorAvatarUrl: post.authorAvatarUrl,
        postType: post.postType,
        content: post.content,
        mediaUrl: post.mediaUrl,
        tags: post.tags,
        heartbreakCount: heartbreak,
        healingCount: healing,
        commentCount: post.commentCount,
        userReaction: newReaction,
        createdAt: post.createdAt,
      );
    }).toList();
  }
}
