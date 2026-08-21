import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../feed/screens/feed_screen.dart';
import '../../healings/screens/healings_screen.dart';
import '../../messages/screens/messages_screen.dart';
import '../../search/screens/search_screen.dart';
import '../../profile/screens/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

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
        ? AppColors.darkCharcoal.withOpacity(0.78)
        : scaffoldBg.withOpacity(0.82);

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
              height: 64,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double barWidth = constraints.maxWidth;
                  final double itemWidth = barWidth / _navItems.length;
                  const double indicatorSize = 42;

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
                                blurRadius: 16,
                                spreadRadius: 1,
                                offset: const Offset(0, 5),
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
                            height: 30,
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