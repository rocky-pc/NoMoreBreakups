import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:no_more_breakups/features/notifications/controllers/notifications_controller.dart';
import '../../../core/services/storage_service.dart';
import '../../feed/models/post_model.dart';
import '../models/profile_state.dart';

final profileControllerProvider = StateNotifierProvider.family<ProfileController, AsyncValue<ProfileState>, String>((ref, userId) {
  return ProfileController(userId);
});

class ProfileController extends StateNotifier<AsyncValue<ProfileState>> {
  final String targetUserId;
  ProfileController(this.targetUserId) : super(const AsyncValue.data(ProfileState())) {
    fetchProfileData();
  }

  Future<void> fetchProfileData({bool silent = false}) async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    
    if (!silent) {
      state = const AsyncValue.loading();
    }

    try {
      // 1. Fetch user profile info
      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', targetUserId)
          .single();
      
      final profile = ProfileData.fromJson(profileResponse);

      // 2. Fetch user's posts
      final postsResponse = await Supabase.instance.client
          .from('posts')
          .select('*, profiles(username, display_name, avatar_url)')
          .eq('user_id', targetUserId)
          .order('created_at', ascending: false);
      
      final posts = (postsResponse as List).map((json) => PostModel.fromJson(json)).toList();

      // 3. Fetch total likes
      int totalLikes = 0;
      for (var post in posts) {
        totalLikes += post.heartbreakCount + post.healingCount;
      }

      // 4. Fetch followers/following counts (Graceful handling if table missing)
      int followers = 0;
      int following = 0;
      try {
        final fers = await Supabase.instance.client.from('follows').select('id').eq('following_id', targetUserId);
        followers = fers.length;
        final fing = await Supabase.instance.client.from('follows').select('id').eq('follower_id', targetUserId);
        following = fing.length;
      } catch (e) {
        debugPrint('Warning: follows table not found or inaccessible: $e');
      }

      // 5. Check if current user follows this target user
      bool isFollowing = false;
      if (currentUserId != null && currentUserId != targetUserId) {
        try {
          final followCheck = await Supabase.instance.client
              .from('follows')
              .select()
              .eq('follower_id', currentUserId)
              .eq('following_id', targetUserId)
              .maybeSingle();
          isFollowing = followCheck != null;
        } catch (_) {}
      }

      state = AsyncValue.data(ProfileState(
        profile: profile,
        posts: posts,
        totalLikes: totalLikes,
        followersCount: followers,
        followingCount: following,
        isFollowing: isFollowing,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleFollow() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null || currentUserId == targetUserId) return;

    final previousState = state.value;
    if (previousState == null) return;

    // Optimistic Update
    final isFollowing = !previousState.isFollowing;
    final followersCount = isFollowing 
        ? previousState.followersCount + 1 
        : (previousState.followersCount > 0 ? previousState.followersCount - 1 : 0);
    
    state = AsyncValue.data(previousState.copyWith(
      isFollowing: isFollowing,
      followersCount: followersCount,
    ));

    try {
      if (!isFollowing) {
        // User was following, now unfollowing
        await Supabase.instance.client
            .from('follows')
            .delete()
            .eq('follower_id', currentUserId)
            .eq('following_id', targetUserId);
      } else {
        // User was not following, now following
        await Supabase.instance.client.from('follows').insert({
          'follower_id': currentUserId,
          'following_id': targetUserId,
        });

        // Trigger notification
        NotificationController.sendNotification(
          receiverId: targetUserId,
          type: 'follow',
        );
      }
      // Refresh in background to sync with server counts/data
      await fetchProfileData(silent: true);
    } catch (e) {
      debugPrint('Error toggling follow: $e');
      // Rollback on error
      state = AsyncValue.data(previousState);
    }
  }

  Future<void> toggleRelationshipStatusVisibility() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null || currentUserId != targetUserId) return;

    final currentState = state.value;
    if (currentState == null || currentState.profile == null) return;

    final newValue = !currentState.profile!.showRelationshipStatus;

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'show_relationship_status': newValue})
          .eq('id', currentUserId);
      
      await fetchProfileData(silent: true);
    } catch (e) {
      debugPrint('Error toggling relationship status visibility: $e');
    }
  }

  Future<void> updateProfileDetails({String? bio, String? relationshipStatus}) async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null || currentUserId != targetUserId) return;

    try {
      final Map<String, dynamic> updates = {};
      if (bio != null) updates['bio'] = bio;
      if (relationshipStatus != null) updates['relationship_status'] = relationshipStatus;

      if (updates.isNotEmpty) {
        await Supabase.instance.client
            .from('profiles')
            .update(updates)
            .eq('id', currentUserId);
        
        await fetchProfileData(silent: true);
      }
    } catch (e) {
      debugPrint('Error updating profile details: $e');
    }
  }

  Future<void> deletePost(String postId) async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null || currentUserId != targetUserId) return;

    try {
      await Supabase.instance.client
          .from('posts')
          .delete()
          .eq('id', postId)
          .eq('user_id', currentUserId);
      
      await fetchProfileData();
    } catch (e) {
      debugPrint('Error deleting post: $e');
      rethrow;
    }
  }

  Future<void> togglePostReaction(String postId, ReactionType reaction) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final existing = await Supabase.instance.client
          .from('post_reactions')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        final existingType = existing['reaction_type'] == 'healing' 
            ? ReactionType.healing 
            : ReactionType.heartbreak;

        if (existingType == reaction) {
          await Supabase.instance.client.from('post_reactions').delete().eq('id', existing['id']);
        } else {
          await Supabase.instance.client
              .from('post_reactions')
              .update({'reaction_type': reaction == ReactionType.healing ? 'healing' : 'heartbreak'})
              .eq('id', existing['id']);
        }
      } else {
        await Supabase.instance.client.from('post_reactions').insert({
          'post_id': postId,
          'user_id': userId,
          'reaction_type': reaction == ReactionType.healing ? 'healing' : 'heartbreak',
        });

        // Trigger notification
        NotificationController.sendNotification(
          receiverId: targetUserId, // We are already in the context of this user's profile
          type: reaction == ReactionType.healing ? 'heal' : 'like',
          postId: postId,
        );
      }
      await fetchProfileData(silent: true);
    } catch (e) {
      debugPrint('Error toggling reaction: $e');
    }
  }

  Future<void> uploadProfileImage(File imageFile) async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null || currentUserId != targetUserId) return;

    state = const AsyncValue.loading();
    try {
      final avatarUrl = await StorageService.uploadAvatar(imageFile);
      if (avatarUrl != null) {
        // 1. Update user metadata in Auth
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(data: {'avatar_url': avatarUrl}),
        );
        
        // 2. Update profiles table
        await Supabase.instance.client.from('profiles').update({
          'avatar_url': avatarUrl,
        }).eq('id', currentUserId);
      }
      await fetchProfileData();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
