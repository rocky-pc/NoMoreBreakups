import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:no_more_breakups/features/notes/models/note_model.dart';

class NotesCarousel extends StatelessWidget {
  final List<NoteModel> notes;
  final VoidCallback onAddNote;

  const NotesCarousel({
    super.key,
    required this.notes,
    required this.onAddNote,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 105,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: notes.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildAddNoteButton();
          }
          final note = notes[index - 1];
          return _buildNoteItem(note);
        },
      ),
    );
  }

  Widget _buildAddNoteButton() {
    return GestureDetector(
      onTap: onAddNote,
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey.shade300,
                child: const Icon(Icons.add, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Your Note', style: TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildNoteItem(NoteModel note) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: note.avatarUrl != null
                  ? CachedNetworkImageProvider(note.avatarUrl!)
                  : null,
              child: note.avatarUrl == null ? const Icon(Icons.person) : null,
            ),
            Positioned(
              top: -10,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 80),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Text(
                  note.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(note.username, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
