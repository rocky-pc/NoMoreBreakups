import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/notifications_controller.dart';
import '../models/notification_model.dart';
import '../../profile/screens/profile_screen.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(notificationsProvider.notifier).fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
        elevation: 0.5,
        actions: [
          TextButton(
            onPressed: () => ref.read(notificationsProvider.notifier).markAllAsRead(),
            child: const Text('Mark all read', style: TextStyle(color: AppColors.rose, fontSize: 13)),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.rose,
        onRefresh: () => ref.read(notificationsProvider.notifier).fetchNotifications(),
        child: state.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.rose.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_none_rounded, color: AppColors.rose, size: 36),
                    ),
                    const SizedBox(height: 14),
                    const Text('No notifications yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    const Text('When people react or reply, they will appear here.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              );
            }

            return ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: isDarkMode ? Colors.white10 : Colors.grey.shade200),
              itemBuilder: (context, index) {
                final item = notifications[index];
                return _NotificationTile(item: item);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.rose)),
          error: (err, _) => Center(child: Text('Error loading activity: $err')),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel item;

  const _NotificationTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final timeStr = DateFormat('MMM d, h:mm a').format(item.createdAt);

    return InkWell(
      onTap: () {
        // Handle navigation to post/profile
        if (item.type == 'follow') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: item.senderId)));
        }
      },
      child: Container(
        color: item.isRead ? Colors.transparent : AppColors.rose.withOpacity(isDarkMode ? 0.08 : 0.04),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar + Small Action Badge Overlay
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: item.senderId)));
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: item.senderAvatar != null ? CachedNetworkImageProvider(item.senderAvatar!) : null,
                    child: item.senderAvatar == null ? const Icon(Icons.person) : null,
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: _buildBadgeIcon(item.type, isDarkMode),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Message Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDarkMode ? Colors.white : Colors.black87,
                        height: 1.3,
                      ),
                      children: [
                        TextSpan(text: item.senderName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: ' ${_getActionText(item)}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(timeStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeIcon(String type, bool isDarkMode) {
    String emoji = '🔔';
    if (type == 'heartbreak' || type == 'like') emoji = '💔';
    if (type == 'heal') emoji = '💖';
    if (type == 'comment') emoji = '💬';
    if (type == 'follow') emoji = '👤';

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black : Colors.white, 
        shape: BoxShape.circle,
        border: Border.all(color: isDarkMode ? Colors.white12 : Colors.black12, width: 0.5),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 12)),
    );
  }

  String _getActionText(NotificationModel item) {
    switch (item.type) {
      case 'heartbreak':
      case 'like':
        return 'sent a heartbreak (💔) reaction to your story.';
      case 'heal':
        return 'sent you healing (💖) on your journal reflection.';
      case 'comment':
        return 'commented: "${item.contentPreview ?? 'on your post'}"';
      case 'follow':
        return 'started following your healing journey.';
      default:
        return 'interacted with your profile.';
    }
  }
}
