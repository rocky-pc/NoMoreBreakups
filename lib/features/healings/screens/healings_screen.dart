import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../controllers/healings_controller.dart';
import '../models/healing_model.dart';
import 'create_healing_screen.dart';

class HealingsScreen extends ConsumerWidget {
  const HealingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healingsState = ref.watch(healingsProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: false,
      body: Stack(
        children: [
          // Soft fluid backdrop
          _buildBackdrop(isDarkMode),

          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: AppColors.rose,
              onRefresh: () => ref.read(healingsProvider.notifier).fetchHealings(),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // App Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [AppColors.rose, AppColors.rose.withAlpha(180)],
                            ).createShader(bounds),
                            child: Text(
                              'Healing Journal  ',
                              textAlign: TextAlign.center,
                              style: AppStyles.brandName.copyWith(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Personal reflections, peace and progress',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Healings List
                  healingsState.when(
                    data: (healings) {
                      if (healings.isEmpty) {
                        return SliverToBoxAdapter(child: _buildEmptyState());
                      }
                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = healings[index];
                              return _HealingCard(
                                item: item,
                                onReact: () => ref.read(healingsProvider.notifier).toggleReaction(item.id),
                              );
                            },
                            childCount: healings.length,
                          ),
                        ),
                      );
                    },
                    loading: () => const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator(color: AppColors.rose)),
                    ),
                    error: (err, _) => SliverFillRemaining(
                      child: Center(child: Text('Error loading journal: $err')),
                    ),
                  ),

                  // Bottom padding for FAB & nav bar
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),
          ),
        ],
      ),

      // Dedicated Floating Action Button (Pencil Icon)
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 76),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateHealingScreen()),
            );
          },
          backgroundColor: AppColors.rose,
          elevation: 4,
          icon: const Icon(Icons.edit_rounded, color: Colors.white),
          label: const Text('Write Entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.rose.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.spa_rounded, size: 44, color: AppColors.rose),
          ),
          const SizedBox(height: 16),
          const Text('No healing entries yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text(
            'Write down your thoughts, milestones, or words of comfort to begin your healing journey.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildBackdrop(bool isDarkMode) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: -60,
              right: -50,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [AppColors.rose.withValues(alpha: 0.18), Colors.transparent]),
                ),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealingCard extends StatelessWidget {
  final HealingModel item;
  final VoidCallback onReact;

  const _HealingCard({required this.item, required this.onReact});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final timeStr = DateFormat('MMM dd, yyyy').format(item.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCharcoal : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Header + Mood Tag
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: item.authorAvatarUrl != null
                    ? CachedNetworkImageProvider(item.authorAvatarUrl!)
                    : null,
                child: item.authorAvatarUrl == null ? const Icon(Icons.person, size: 20) : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(timeStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.rose.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '🕊️ ${item.mood}',
                  style: const TextStyle(fontSize: 11, color: AppColors.rose, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Content Text
          Text(item.content, style: const TextStyle(fontSize: 14, height: 1.45)),
          const SizedBox(height: 10),

          // Optional Image
          if (item.mediaUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CachedNetworkImage(
                imageUrl: item.mediaUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

          const SizedBox(height: 8),
          const Divider(height: 1),

          // Empathy Healing Reaction Button
          Row(
            children: [
              TextButton.icon(
                onPressed: onReact,
                icon: Text(
                  item.hasReacted ? '💖' : '🩹',
                  style: const TextStyle(fontSize: 16),
                ),
                label: Text(
                  item.hasReacted ? 'Sent Healing (${item.reactionsCount})' : 'Send Healing (${item.reactionsCount})',
                  style: TextStyle(
                    color: item.hasReacted ? AppColors.rose : Colors.grey[700],
                    fontWeight: item.hasReacted ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
