import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:no_more_breakups/features/notes/models/note_model.dart';

class NotesCarousel extends StatelessWidget {
  final List<NoteModel> notes;
  final VoidCallback onAddNote;
  final Function(NoteModel)? onNoteTap;

  const NotesCarousel({
    super.key,
    required this.notes,
    required this.onAddNote,
    this.onNoteTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 118,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: notes.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildAddNoteButton(context);
          }
          final note = notes[index - 1];
          return _buildNoteItem(context, note);
        },
      ),
    );
  }

  // ────────────────────────────────────────────────
  // ADD NOTE BUTTON
  // ────────────────────────────────────────────────
  Widget _buildAddNoteButton(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Try to get current user's avatar
    final user = Supabase.instance.client.auth.currentUser;
    final avatarUrl = user?.userMetadata?['avatar_url'];

    return GestureDetector(
      onTap: onAddNote,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.25)
                    : Colors.grey.shade400,
                width: 1.8,
              ),
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.grey.shade100,
                      image: avatarUrl != null 
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(avatarUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: avatarUrl == null 
                        ? Icon(
                            Icons.person_rounded,
                            size: 28,
                            color: isDark ? Colors.white70 : Colors.black87,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Your Note',
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────
  // NOTE ITEM
  // ────────────────────────────────────────────────
  Widget _buildNoteItem(BuildContext context, NoteModel note) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => onNoteTap?.call(note),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Gradient ring
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFF58529),
                      Color(0xFFDD2A7B),
                      Color(0xFF8134AF),
                      Color(0xFF515BD4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2.8),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.surface,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2.2),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        backgroundImage: note.avatarUrl != null
                            ? CachedNetworkImageProvider(note.avatarUrl!)
                            : null,
                        child: note.avatarUrl == null
                            ? Icon(
                          Icons.person_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                        )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),

              // Note bubble (only this small floating bubble, no big rectangle)
              Positioned(
                top: -6,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 92, minWidth: 40),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    note.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          // Username
          SizedBox(
            width: 68,
            child: Text(
              note.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}