import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:no_more_breakups/features/feed/models/post_model.dart';
import 'package:no_more_breakups/features/feed/widgets/post_card.dart';
import 'package:no_more_breakups/features/feed/controllers/feed_controller.dart';
import 'package:no_more_breakups/features/notes/controllers/notes_controller.dart';
import 'package:no_more_breakups/features/notes/widgets/notes_carousel.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(feedPostsProvider.notifier).fetchPosts();
      ref.read(notesProvider.notifier).fetchNotes();
    });
  }

  void _handleReact(String postId, ReactionType reaction) {
    if (reaction == ReactionType.heartbreak) {
      ref.read(feedPostsProvider.notifier).toggleHeartbreak(postId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final posts = ref.watch(feedPostsProvider);
    final notes = ref.watch(notesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('No More Breakups', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(feedPostsProvider.notifier).fetchPosts();
          await ref.read(notesProvider.notifier).fetchNotes();
        },
        child: ListView(
          children: [
            NotesCarousel(
              notes: notes,
              onAddNote: () {
                // Implement add note dialog
              },
            ),
            const SizedBox(height: 12),
            if (posts.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Text('No posts yet. Be the first to share!'),
                ),
              )
            else
              ...posts.map(
                (post) => PostCard(
                  post: post,
                  onReact: (r) => _handleReact(post.id, r),
                  onComment: () {},
                  onShare: () {},
                ),
              ),
          ],
        ),
      ),
    );
  }
}
