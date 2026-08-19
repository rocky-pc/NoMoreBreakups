import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import 'profile_screen.dart';

class FollowListScreen extends StatefulWidget {
  final String userId;
  final String title;
  final String type; // 'followers' or 'following'

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.title,
    required this.type,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final String foreignKey = widget.type == 'followers' ? 'follower_id' : 'following_id';
      final String matchKey = widget.type == 'followers' ? 'following_id' : 'follower_id';
      
      // If we want followers, we look for everyone where following_id = userId, and fetch their profile (follower_id)
      // If we want following, we look for everyone where follower_id = userId, and fetch their profile (following_id)
      
      final response = await Supabase.instance.client
          .from('follows')
          .select('profiles: $foreignKey (id, username, display_name, avatar_url)')
          .eq(matchKey, widget.userId);

      setState(() {
        _users = List<Map<String, dynamic>>.from(response.map((e) => e['profiles']));
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching follow list: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(child: Text('No ${widget.type} yet.'))
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user['avatar_url'] != null
                            ? CachedNetworkImageProvider(user['avatar_url'])
                            : null,
                        child: user['avatar_url'] == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(user['display_name'] ?? user['username'] ?? 'User'),
                      subtitle: Text('@${user['username'] ?? 'user'}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileScreen(userId: user['id']),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
