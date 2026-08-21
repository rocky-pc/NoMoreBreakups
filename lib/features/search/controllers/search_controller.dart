import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../profile/models/user_profile.dart';

final userSearchProvider = StateNotifierProvider<UserSearchController, AsyncValue<List<UserProfile>>>((ref) {
  return UserSearchController();
});

class UserSearchController extends StateNotifier<AsyncValue<List<UserProfile>>> {
  UserSearchController() : super(const AsyncValue.data([]));

  final _supabase = Supabase.instance.client;

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      state = const AsyncValue.loading();
      
      final response = await _supabase
          .from('profiles')
          .select()
          .or('username.ilike.%$query%,display_name.ilike.%$query%')
          .limit(20);

      final users = (response as List).map((json) => UserProfile.fromJson(json)).toList();
      state = AsyncValue.data(users);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
