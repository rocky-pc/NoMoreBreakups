import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/note_model.dart';

final notesProvider = StateNotifierProvider<NotesController, List<NoteModel>>((ref) {
  return NotesController();
});

class NotesController extends StateNotifier<List<NoteModel>> {
  NotesController() : super([]);

  Future<void> fetchNotes() async {
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      final now = DateTime.now().toIso8601String();
      
      // 1. Fetch followed user IDs if logged in
      List<String> followedIds = [];
      if (currentUserId != null) {
        final followsResponse = await Supabase.instance.client
            .from('follows')
            .select('following_id')
            .eq('follower_id', currentUserId);
        followedIds = (followsResponse as List).map((f) => f['following_id'] as String).toList();
      }

      // 2. Fetch active notes
      final response = await Supabase.instance.client
          .from('notes')
          .select('*, profiles(username, avatar_url)')
          .gt('expires_at', now)
          .order('created_at', ascending: false);
      
      final allNotes = (response as List).map((json) {
        final mappedJson = Map<String, dynamic>.from(json);
        mappedJson['users'] = json['profiles'];
        return NoteModel.fromJson(mappedJson);
      }).toList();

      // 3. Sort logic: Followers first, then others (both sorted by recency within their group)
      final List<NoteModel> sortedNotes = [];
      
      // Filter out current user's note from this list if we want it to be special, 
      // but usually users see their own note in the list too.
      
      // Followers notes
      final followersNotes = allNotes.where((n) => followedIds.contains(n.userId) && n.userId != currentUserId).toList();
      sortedNotes.addAll(followersNotes);

      // Other notes
      final otherNotes = allNotes.where((n) => !followedIds.contains(n.userId) && n.userId != currentUserId).toList();
      sortedNotes.addAll(otherNotes);
      
      // If current user has a note, it could go at the very beginning or end of their friend list
      // In Instagram, your own note is usually integrated or at the start.
      final myNote = allNotes.where((n) => n.userId == currentUserId).toList();
      if (myNote.isNotEmpty) {
        sortedNotes.insert(0, myNote.first);
      }

      state = sortedNotes;
    } catch (e) {
      debugPrint('Error fetching notes: $e');
    }
  }

  Future<void> addNote(String content) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final expiresAt = DateTime.now().add(const Duration(hours: 24)).toIso8601String();
      
      // Delete existing active notes for this user first
      await Supabase.instance.client
          .from('notes')
          .delete()
          .eq('user_id', userId);
      
      await Supabase.instance.client.from('notes').insert({
        'user_id': userId,
        'content': content,
        'expires_at': expiresAt,
      });
      
      await fetchNotes();
    } catch (e) {
      debugPrint('Error adding note: $e');
    }
  }
}
