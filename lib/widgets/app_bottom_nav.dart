import 'package:beanbloss/screens/HomeScreens/home_screen.dart';
import 'package:beanbloss/screens/HomeScreens/menu_screen.dart';
import 'package:beanbloss/screens/HomeScreens/profile_screen.dart';
import 'package:beanbloss/screens/HomeScreens/reward_screen.dart';
import 'package:beanbloss/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared bottom navigation for main tabs.
/// Indices: 0 Home, 1 Menu, 3 Rewards, 4 Profile (2 reserved for FAB).
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
  });

  final int currentIndex;

  void _go(BuildContext context, int index) {
    if (index == currentIndex) return;
    HapticFeedback.selectionClick();

    final Widget page;
    switch (index) {
      case 0:
        page = const HomeScreen();
        break;
      case 1:
        page = const MenuCardScreen();
        break;
      case 3:
        page = const RewardsScreen();
        break;
      case 4:
        page = const ProfileScreen();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: const Duration(milliseconds: 220),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.border(0.15))),
        boxShadow: AppShadows.nav,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
          child: Row(
            children: [
              _item(context, 0, Icons.home_rounded, 'Home'),
              _item(context, 1, Icons.menu_book_rounded, 'Menu'),
              const SizedBox(width: 56),
              _item(context, 3, Icons.card_giftcard_rounded, 'Rewards'),
              _item(context, 4, Icons.person_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    int index,
    IconData icon,
    String label,
  ) {
    final selected = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _go(context, index),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.accentGold.withOpacity(0.16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: selected
                      ? AppColors.primaryBrown
                      : AppColors.textLight,
                  size: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? AppColors.primaryBrown
                      : AppColors.textLight,
                  fontSize: 11,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
