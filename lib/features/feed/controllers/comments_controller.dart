import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/comment_model.dart';

final commentsProvider = StateNotifierProvider.family<CommentsController, AsyncValue<List<CommentModel>>, String>((ref, postId) {
  return CommentsController(postId);
});

class CommentsController extends StateNotifier<AsyncValue<List<CommentModel>>> {
  final String postId;
  final _supabase = Supabase.instance.client;

  CommentsController(this.postId) : super(const AsyncValue.loading()) {
    fetchComments();
  }

  Future<void> fetchComments() async {
    try {
      state = const AsyncValue.loading();
      final response = await _supabase
          .from('post_comments')
          .select('*, profiles(username, display_name, avatar_url)')
          .eq('post_id', postId)
          .order('created_at', ascending: true);
      
      final comments = (response as List).map((json) => CommentModel.fromJson(json)).toList();
      state = AsyncValue.data(comments);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addComment(String content) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('post_comments').insert({
        'post_id': postId,
        'user_id': userId,
        'content': content,
      });
      await fetchComments();
    } catch (e) {
      debugPrint('Error adding comment: $e');
    }
  }
}
