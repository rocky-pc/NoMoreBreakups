import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  static final _client = Supabase.instance.client;

  /// Uploads an image to the 'post-images' bucket
  /// Follows the policy: private folder, authenticated users only
  static Future<String?> uploadPostImage(File imageFile) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw 'User not authenticated';

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'private/$userId/$fileName';

      await _client.storage.from('post-images').upload(path, imageFile);
      
      final url = _client.storage.from('post-images').getPublicUrl(path);
      return url;
    } catch (e) {
      print('Error uploading post image: $e');
      return null;
    }
  }

  /// Uploads an image to the 'avatars' bucket with cache-busting
  static Future<String?> uploadAvatar(File imageFile) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw 'User not authenticated';

      final fileExtension = imageFile.path.split('.').last;
      final path = '$userId/avatar.$fileExtension';

      // Use upsert: true to overwrite old avatar
      await _client.storage.from('avatars').upload(
        path, 
        imageFile, 
        fileOptions: const FileOptions(upsert: true),
      );
      
      final url = _client.storage.from('avatars').getPublicUrl(path);
      // Append cache-buster to ensure the UI refreshes the image
      return '$url?v=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      print('Error uploading avatar: $e');
      return null;
    }
  }
}
