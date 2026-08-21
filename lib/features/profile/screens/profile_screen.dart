import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/theme/theme_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../feed/models/post_model.dart';
import '../../feed/widgets/post_card.dart';
import '../../messages/controllers/message_controller.dart';
import '../../messages/screens/chat_screen.dart';
import '../../post_creation/screens/create_post_screen.dart';
import '../controllers/profile_controller.dart';
import '../models/profile_state.dart';
import 'follow_list_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String? userId; // Null means current user
  const ProfileScreen({super.key, this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _picker = ImagePicker();
  int _selectedTab = 0;

  final _bioController = TextEditingController();
  final _statusController = TextEditingController();

  String get _effectiveUserId => widget.userId ?? Supabase.instance.client.auth.currentUser!.id;
  bool get _isOwnProfile => _effectiveUserId == Supabase.instance.client.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(profileControllerProvider(_effectiveUserId).notifier).fetchProfileData();
    });
  }

  @override
  void dispose() {
    _bioController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  void _showEditProfileDialog(ProfileData? profile) {
    if (profile != null) {
      _bioController.text = profile.bio ?? '';
      _statusController.text = profile.relationshipStatus ?? '';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(labelText: 'Bio'),
              maxLines: 3,
            ),
            TextField(
              controller: _statusController,
              decoration: const InputDecoration(labelText: 'Relationship Status'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(profileControllerProvider(_effectiveUserId).notifier).updateProfileDetails(
                bio: _bioController.text.trim(),
                relationshipStatus: _statusController.text.trim(),
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );

    if (pickedFile != null) {
      await ref.read(profileControllerProvider(_effectiveUserId).notifier).uploadProfileImage(File(pickedFile.path));
    }
  }

  void _openMenuSheet() {
    final themeMode = ref.read(themeProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDarkModeSheet = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isDarkModeSheet ? AppColors.darkCharcoal : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDarkModeSheet ? Colors.white24 : AppColors.softGrey,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              if (_isOwnProfile)
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: AppColors.rose),
                  title: const Text('Edit Profile'),
                  onTap: () {
                    Navigator.pop(context);
                    final profile = ref.read(profileControllerProvider(_effectiveUserId)).value?.profile;
                    _showEditProfileDialog(profile);
                  },
                ),
              SwitchListTile(
                secondary: Icon(
                  isDarkModeSheet ? Icons.dark_mode : Icons.light_mode,
                  color: AppColors.rose,
                ),
                title: const Text('Dark Mode'),
                subtitle: themeMode == ThemeMode.system ? const Text('Following System', style: TextStyle(fontSize: 10)) : null,
                value: isDarkModeSheet,
                onChanged: (bool value) {
                  ref.read(themeProvider.notifier).setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline, color: AppColors.rose),
                title: const Text('Help & Support'),
                onTap: () => Navigator.pop(context),
              ),
              if (_isOwnProfile)
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                  onTap: _signOut,
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showPostOptions(PostModel post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCharcoal : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isOwnProfile) ...[
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: Colors.blue),
                title: const Text('Edit Post'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreatePostScreen(postToEdit: post),
                    ),
                  ).then((_) => ref.read(profileControllerProvider(_effectiveUserId).notifier).fetchProfileData());
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_rounded, color: Colors.red),
                title: const Text('Delete Post', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Post'),
                      content: const Text('Are you sure you want to delete this post?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    if (mounted) Navigator.pop(context);
                    await ref.read(profileControllerProvider(_effectiveUserId).notifier).deletePost(post.id);
                  }
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Share'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statColumn(String value, String label, VoidCallback? onTap) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.w700, 
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12, 
              color: isDarkMode ? Colors.white54 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabIcon(IconData icon, int index) {
    final bool isSelected = _selectedTab == index;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.rose : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Icon(
            icon,
            size: 22,
            color: isSelected 
                ? AppColors.rose 
                : (isDarkMode ? Colors.white38 : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final profileState = ref.watch(profileControllerProvider(_effectiveUserId));
    
    return Scaffold(
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
        data: (data) {
          final profile = data.profile;
          final userPosts = data.posts;
          
          final avatarUrl = profile?.avatarUrl;
          final displayName = profile?.displayName ?? profile?.username ?? 'Anonymous User';
          final email = profile?.email ?? '';

          return SafeArea(
            child: CustomScrollView(
              slivers: [
                // Top bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                          onPressed: () => Navigator.maybePop(context),
                        ),
                        Text(
                          profile?.username != null ? '@${profile!.username}' : displayName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_horiz_rounded),
                          onPressed: _openMenuSheet,
                        ),
                      ],
                    ),
                  ),
                ),

                // Avatar + name
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.rose.withAlpha(80), width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 42,
                                backgroundColor: AppColors.softGrey,
                                backgroundImage: avatarUrl != null
                                    ? CachedNetworkImageProvider(avatarUrl)
                                    : null,
                                child: avatarUrl == null
                                    ? const Icon(Icons.person, size: 42, color: Colors.grey)
                                    : null,
                              ),
                            ),
                            if (_isOwnProfile)
                              Positioned(
                                bottom: 0,
                                right: 4,
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: AppColors.rose,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: isDarkMode ? AppColors.darkCharcoal : Colors.white, width: 2),
                                    ),
                                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(displayName, style: AppStyles.headingLarge),
                        if (profile?.bio != null && profile!.bio!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 32, right: 32),
                            child: Text(
                              profile.bio!,
                              style: AppStyles.bodyText,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: 8),
                        if (_isOwnProfile || profile?.showRelationshipStatus == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.rose.withAlpha(20),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.favorite_rounded, size: 14, color: AppColors.rose),
                                const SizedBox(width: 6),
                                Text(
                                  profile?.relationshipStatus ?? 'No Status',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.rose,
                                  ),
                                ),
                                if (_isOwnProfile) ...[
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => ref.read(profileControllerProvider(_effectiveUserId).notifier).toggleRelationshipStatusVisibility(),
                                    child: Icon(
                                      profile?.showRelationshipStatus == true 
                                          ? Icons.visibility_rounded 
                                          : Icons.visibility_off_rounded,
                                      size: 14,
                                      color: AppColors.rose.withAlpha(150),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          email.isNotEmpty ? email : 'Supportive Member',
                          style: AppStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ),

                // Stats row
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _statColumn(userPosts.length.toString(), 'Posts', null),
                        _statColumn(data.followersCount.toString(), 'Followers', () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => FollowListScreen(userId: _effectiveUserId, title: 'Followers', type: 'followers')));
                        }),
                        _statColumn(data.followingCount.toString(), 'Following', () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => FollowListScreen(userId: _effectiveUserId, title: 'Following', type: 'following')));
                        }),
                        _statColumn(data.totalLikes.toString(), 'Likes', null),
                      ],
                    ),
                  ),
                ),

                // Action buttons
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: _isOwnProfile 
                            ? ElevatedButton(
                                onPressed: () => _showEditProfileDialog(profile),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.rose,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w600)),
                              )
                            : ElevatedButton(
                                onPressed: () => ref.read(profileControllerProvider(_effectiveUserId).notifier).toggleFollow(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: data.isFollowing ? (isDarkMode ? Colors.white12 : AppColors.softGrey) : AppColors.rose,
                                  foregroundColor: data.isFollowing ? (isDarkMode ? Colors.white : Colors.black87) : Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: Text(data.isFollowing ? 'Following' : 'Follow', style: const TextStyle(fontWeight: FontWeight.w600)),
                              ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              if (_isOwnProfile) {
                                // Share Profile logic
                              } else {
                                final conversationId = await ref.read(messageControllerProvider).getOrCreateConversation(_effectiveUserId);
                                if (mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(
                                        conversationId: conversationId,
                                        otherUserId: _effectiveUserId,
                                        otherUserName: displayName,
                                        otherUserAvatar: avatarUrl,
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(_isOwnProfile ? 'Share Profile' : 'Message', style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 18)),

                // Tab strip
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: Row(
                        children: [
                          _tabIcon(Icons.grid_on_rounded, 0),
                          _tabIcon(Icons.format_list_bulleted_rounded, 1),
                          _tabIcon(Icons.person_pin_outlined, 2),
                        ],
                      ),
                    ),
                  ),
                ),

                // Post content (Grid or Feed)
                if (userPosts.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('No posts yet')),
                  )
                else if (_selectedTab == 0)
                  SliverPadding(
                    padding: const EdgeInsets.all(2),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, mainAxisSpacing: 2, crossAxisSpacing: 2, childAspectRatio: 1.0,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final post = userPosts[index];
                          return GestureDetector(
                            onTap: () => setState(() => _selectedTab = 1),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.white.withAlpha(10) : AppColors.softGrey,
                                image: post.mediaUrl != null
                                    ? DecorationImage(image: CachedNetworkImageProvider(post.mediaUrl!), fit: BoxFit.cover)
                                    : null,
                              ),
                              child: post.mediaUrl == null
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          post.content,
                                          maxLines: 4,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 8, color: isDarkMode ? Colors.white70 : Colors.black87),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          );
                        },
                        childCount: userPosts.length,
                      ),
                    ),
                  )
                else if (_selectedTab == 1)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final post = userPosts[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: PostCard(
                            post: post,
                            onReact: (reaction) => ref.read(profileControllerProvider(_effectiveUserId).notifier).togglePostReaction(post.id, reaction),
                            onComment: () {},
                            onShare: () {},
                            onMore: () => _showPostOptions(post),
                          ),
                        );
                      },
                      childCount: userPosts.length,
                    ),
                  )
                else
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('Coming Soon')),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _TabBarDelegate({required this.child});
  @override
  double get minExtent => 44;
  @override
  double get maxExtent => 44;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;
  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => true;
}
