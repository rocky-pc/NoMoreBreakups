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
      final now = DateTime.now().toIso8601String();
      final response = await Supabase.instance.client
          .from('notes')
          .select('*, profiles(username, avatar_url)')
          .gt('expires_at', now)
          .order('created_at', ascending: false);
      
      final notes = (response as List).map((json) {
        // Map profiles to users field for NoteModel compatibility if needed
        // or update NoteModel to use 'profiles'
        final mappedJson = Map<String, dynamic>.from(json);
        mappedJson['users'] = json['profiles'];
        return NoteModel.fromJson(mappedJson);
      }).toList();
      state = notes;
    } catch (e) {
      debugPrint('Error fetching notes: $e');
    }
  }

  Future<void> addNote(String content) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final expiresAt = DateTime.now().add(const Duration(hours: 24)).toIso8601String();
      
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
