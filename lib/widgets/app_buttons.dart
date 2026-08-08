import 'package:beanbloss/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Primary filled CTA — elevation 0, brand brown.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        Text(label),
      ],
    );

    return SizedBox(
      width: expand ? double.infinity : null,
      child: ElevatedButton(
        onPressed: onPressed == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onPressed!();
              },
        child: child,
      ),
    );
  }
}

/// Action link — primaryBrown. Use for See all / Reorder / Apply.
class AppLinkButton extends StatelessWidget {
  const AppLinkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.secondary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        HapticFeedback.selectionClick();
        onPressed();
      },
      style: TextButton.styleFrom(
        foregroundColor:
            secondary ? AppColors.textLight : AppColors.primaryBrown,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: secondary ? AppColors.textLight : AppColors.primaryBrown,
        ),
      ),
    );
  }
}

/// Cart-style bordered square back / icon control.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 42,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onPressed();
        },
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: AppColors.border(0.28)),
          ),
          child: Icon(icon, size: size * 0.4, color: AppColors.textDark),
        ),
      ),
    );
  }
}

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      icon: Icons.arrow_back_ios_new_rounded,
      onPressed: onPressed ?? () => Navigator.maybePop(context),
    );
  }
}
