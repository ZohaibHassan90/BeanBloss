import 'package:beanbloss/screens/HomeScreens/cart_screen.dart';
import 'package:beanbloss/state/cart_store.dart';
import 'package:beanbloss/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared gradient cart FAB used on all main tabs.
class AppCartFab extends StatelessWidget {
  const AppCartFab({
    super.key,
    this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CartStore.instance,
      builder: (context, _) {
        final itemCount = CartStore.instance.itemCount;
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.lightBrown, AppColors.primaryBrown],
            ),
            boxShadow: AppShadows.soft(opacity: 0.35),
          ),
          child: FloatingActionButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              if (onPressed != null) {
                onPressed!();
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                );
              }
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            highlightElevation: 0,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.shopping_bag_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                if (itemCount > 0)
                  Positioned(
                    top: -2,
                    right: -6,
                    child: Container(
                      constraints:
                          const BoxConstraints(minWidth: 18, minHeight: 18),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentGold,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          itemCount > 9 ? '9+' : '$itemCount',
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
