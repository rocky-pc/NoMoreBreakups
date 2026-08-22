import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../feed/screens/feed_screen.dart';
import '../../healings/screens/healings_screen.dart';
import '../../messages/screens/messages_screen.dart';
import '../../search/screens/search_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../calls/controllers/call_controller.dart';
import '../../calls/screens/incoming_call_screen.dart';
import '../../calls/screens/call_screen.dart';
import '../../../core/services/call_kit_service.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;
  StreamSubscription? _callSubscription;

  @override
  void initState() {
    super.initState();
    _listenForCalls();
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    super.dispose();
  }

  void _listenForCalls() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    FlutterCallkitIncoming.onEvent.listen((event) {
      switch (event?.event) {
        case Event.actionCallAccept:
          final extra = event!.body['extra'];
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CallScreen(
                channelName: extra['channel_name'],
                otherUserName: extra['caller_name'],
                otherUserAvatar: extra['caller_avatar'],
                isVideoCall: extra['is_video'],
                isCaller: false,
              ),
            ),
          );
          break;
        case Event.actionCallDecline:
          final extra = event!.body['extra'];
          ref.read(callControllerProvider).endCall(extra['channel_name']);
          break;
        default:
          break;
      }
    });

    _callSubscription = ref.read(callControllerProvider).streamIncomingCalls().listen((calls) async {
      if (calls.isNotEmpty) {
        final lastCall = calls.first;
        final status = lastCall['status'];
        final callerId = lastCall['caller_id'];
        
        if (status == 'ringing') {
          try {
            final profileData = await Supabase.instance.client
                .from('profiles')
                .select()
                .eq('id', callerId)
                .single();
            
            final callerName = profileData['display_name'] ?? profileData['username'] ?? 'Unknown User';
            final callerAvatar = profileData['avatar_url'];

            // Show System Call UI
            await CallKitService.showIncomingCall(
              callerName: callerName,
              avatar: callerAvatar,
              channelName: lastCall['channel_name'],
              isVideo: lastCall['call_type'] == 'video',
              callId: lastCall['id'],
            );

            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => IncomingCallScreen(
                    callData: lastCall,
                    callerName: callerName,
                    callerAvatar: callerAvatar,
                  ),
                ),
              );
            }
          } catch (e) {
            debugPrint('Error fetching caller profile: $e');
          }
        }
      }
    });
  }

  final List<Widget> _pages = const [
    FeedScreen(),
    HealingsScreen(),
    SearchScreen(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  final List<_NavItemData> _navItems = const [
    _NavItemData(icon: Icons.home_rounded, outlineIcon: Icons.home_outlined),
    _NavItemData(icon: Icons.favorite_rounded, outlineIcon: Icons.favorite_outline_rounded),
    _NavItemData(icon: Icons.search_rounded, outlineIcon: Icons.search_rounded),
    _NavItemData(icon: Icons.chat_bubble_rounded, outlineIcon: Icons.chat_bubble_outline_rounded),
    _NavItemData(icon: Icons.person_rounded, outlineIcon: Icons.person_outline_rounded),
  ];

  void _onTabTapped(int index) {
    if (index == _selectedIndex) return;

    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: _buildFluidPageSwitcher(),
      ),
      bottomNavigationBar: _buildFixedNavBar(context),
    );
  }

  // ---------------------------------------------------------------------
  // Ultra fluid page transition (fade + micro-slide + scale)
  // ---------------------------------------------------------------------
  Widget _buildFluidPageSwitcher() {
    return Stack(
      children: List.generate(_pages.length, (index) {
        final bool isSelected = index == _selectedIndex;

        return IgnorePointer(
          ignoring: !isSelected,
          child: AnimatedOpacity(
            opacity: isSelected ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 340),
            curve: Curves.easeOutCubic,
            child: AnimatedSlide(
              offset: isSelected ? Offset.zero : const Offset(0, 0.015),
              duration: const Duration(milliseconds: 340),
              curve: Curves.easeOutCubic,
              child: AnimatedScale(
                scale: isSelected ? 1.0 : 0.975,
                duration: const Duration(milliseconds: 340),
                curve: Curves.easeOutCubic,
                child: _pages[index],
              ),
            ),
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------
  // Frosted glass nav bar with fluid sliding indicator + pop icons
  // ---------------------------------------------------------------------
  Widget _buildFixedNavBar(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    final barColor = isDarkMode
        ? AppColors.darkCharcoal.withValues(alpha: 0.78)
        : scaffoldBg.withValues(alpha: 0.82);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: barColor,
            border: Border(
              top: BorderSide(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.07)
                    : AppColors.rose.withOpacity(0.14),
                width: 0.7,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 52,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double barWidth = constraints.maxWidth;
                  final double itemWidth = barWidth / _navItems.length;
                  const double indicatorSize = 34;

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // ── Sliding rose pill (fluid) ───────────────────
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 360),
                        curve: Curves.easeOutBack,
                        left: itemWidth * _selectedIndex + (itemWidth - indicatorSize) / 2,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 360),
                          curve: Curves.easeOutBack,
                          width: indicatorSize,
                          height: indicatorSize,
                          decoration: BoxDecoration(
                            color: AppColors.rose,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.rose.withOpacity(0.42),
                                blurRadius: 12,
                                spreadRadius: 1,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Nav icons ───────────────────────────────────
                      Row(
                        children: List.generate(_navItems.length, (index) {
                          final bool isSelected = index == _selectedIndex;
                          final item = _navItems[index];

                          return SizedBox(
                            width: itemWidth,
                            height: 32,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _onTabTapped(index),
                              child: Center(
                                child: TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 320),
                                  curve: Curves.easeOutBack,
                                  tween: Tween<double>(
                                    begin: 0.0,
                                    end: isSelected ? 1.0 : 0.0,
                                  ),
                                  builder: (context, value, child) {
                                    final Color iconColor = Color.lerp(
                                      isDarkMode
                                          ? Colors.white70
                                          : AppColors.textSecondary,
                                      Colors.white,
                                      value,
                                    )!;

                                    return Transform.scale(
                                      scale: 1.0 + (value * 0.18),
                                      child: Icon(
                                        isSelected ? item.icon : item.outlineIcon,
                                        size: 22 + (value * 1.5),
                                        color: iconColor,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData outlineIcon;

  const _NavItemData({
    required this.icon,
    required this.outlineIcon,
  });
}