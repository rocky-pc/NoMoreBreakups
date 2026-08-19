import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/storage_service.dart';

final profileControllerProvider = StateNotifierProvider<ProfileController, AsyncValue<void>>((ref) {
  return ProfileController();
});

class ProfileController extends StateNotifier<AsyncValue<void>> {
  ProfileController() : super(const AsyncValue.data(null));

  Future<void> uploadProfileImage(File imageFile) async {
    state = const AsyncValue.loading();
    try {
      final avatarUrl = await StorageService.uploadAvatar(imageFile);
      if (avatarUrl != null) {
        // Update user metadata in Auth
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(data: {'avatar_url': avatarUrl}),
        );
        
        // Also update profiles table if it exists
        await Supabase.instance.client.from('profiles').upsert({
          'id': Supabase.instance.client.auth.currentUser!.id,
          'avatar_url': avatarUrl,
        });
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
