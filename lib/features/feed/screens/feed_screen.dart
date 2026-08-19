import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:no_more_breakups/features/feed/models/post_model.dart';
import 'package:no_more_breakups/features/feed/widgets/post_card.dart';
import 'package:no_more_breakups/features/feed/controllers/feed_controller.dart';
import 'package:no_more_breakups/features/notes/controllers/notes_controller.dart';
import 'package:no_more_breakups/features/notes/widgets/notes_carousel.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../post_creation/screens/create_post_screen.dart';

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

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: false,
      body: Stack(
        children: [
          // --- Fluid gradient blobs behind everything, for the "fluid design" feel ---
          _buildFluidBackdrop(isDarkMode),

          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: AppColors.rose,
              onRefresh: () async {
                await ref.read(feedPostsProvider.notifier).fetchPosts();
                await ref.read(notesProvider.notifier).fetchNotes();
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // --- Centered fluid-gradient title app bar ---
                  SliverToBoxAdapter(child: _buildAppBar(context, isDarkMode)),

                  // --- Notes / story carousel ---
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: NotesCarousel(
                        notes: notes,
                        onAddNote: () {
                          // Implement add note dialog
                        },
                      ),
                    ),
                  ),
                  // --- Posts ---
                  if (posts.isEmpty)
                    SliverToBoxAdapter(child: _buildEmptyState(isDarkMode))
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final post = posts[index];
                          return Container(
                            color: isDarkMode ? AppColors.darkCharcoal : Colors.white,
                            margin: const EdgeInsets.only(bottom: 10),
                            child: PostCard(
                              post: post,
                              onReact: (r) => _handleReact(post.id, r),
                              onComment: () {},
                              onShare: () {},
                            ),
                          );
                        },
                        childCount: posts.length,
                      ),
                    ),

                  // Bottom breathing room so content clears the floating nav pill
                  const SliverToBoxAdapter(child: SizedBox(height: 110)),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFluidFab(context),
    );
  }

  // ---------------------------------------------------------------------
  // Centered, gradient-text app bar with a bell icon anchored to the right
  // ---------------------------------------------------------------------
  Widget _buildAppBar(BuildContext context, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 12, 5, 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Centered fluid gradient title
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                AppColors.rose,
                AppColors.rose.withAlpha(150),
                AppColors.rose,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Text(
              'No More Breakups',
              textAlign: TextAlign.center,
              style: AppStyles.brandName.copyWith(
                fontSize: 33,
                fontWeight: FontWeight.w800,
                color: Colors.white, // masked by gradient
                letterSpacing: 0.2,
              ),
            ),
          ),

          // Notification bell, pinned right
          Align(
            alignment: Alignment.centerRight,
            child: _iconBubble(
              icon: Icons.lens_blur_outlined,
              isDarkMode: isDarkMode,
              onTap: () {},
              showDot: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBubble({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDarkMode,
    bool showDot = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          // color: isDarkMode ? AppColors.darkCharcoal : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.rose.withAlpha(30),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 20, color: isDarkMode ? Colors.white70 : AppColors.textSecondary),
            if (showDot)
              Positioned(
                top: 10,
                right: 11,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.rose,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Soft blurred gradient blobs behind the whole screen for a fluid feel
  // ---------------------------------------------------------------------
  Widget _buildFluidBackdrop(bool isDarkMode) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: -80,
              left: -60,
              child: _blob(220, AppColors.rose.withAlpha(40)),
            ),
            Positioned(
              top: 40,
              right: -70,
              child: _blob(180, AppColors.rose.withAlpha(25)),
            ),
            Positioned(
              bottom: -60,
              left: -40,
              child: _blob(200, AppColors.rose.withAlpha(20)),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withAlpha(0)],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 40),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.rose.withAlpha(20),
            ),
            child: Icon(
              Icons.favorite_rounded,
              size: 36,
              color: AppColors.rose.withAlpha(128),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No posts yet',
            style: AppStyles.headingLarge.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            'Be the first to share your story',
            textAlign: TextAlign.center,
            style: AppStyles.caption,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Gradient FAB, lifted above the floating pill nav bar
  // ---------------------------------------------------------------------
  Widget _buildFluidFab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 76), // clears the floating nav pill
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [AppColors.rose, AppColors.rose.withAlpha(190)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.rose.withAlpha(90),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreatePostScreen()),
            ).then((_) => ref.read(feedPostsProvider.notifier).fetchPosts());
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
