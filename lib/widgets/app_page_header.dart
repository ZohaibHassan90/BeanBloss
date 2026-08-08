import 'package:beanbloss/theme/app_colors.dart';
import 'package:beanbloss/utils/responsive.dart';
import 'package:beanbloss/widgets/app_buttons.dart';
import 'package:flutter/material.dart';

/// Refined page header used on every screen except Home.
/// Soft card surface + icon badge + title/subtitle — richer than a bare title row.
class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.coffee_rounded,
    this.trailing,
    this.onBack,
    this.showBack = true,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onBack;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(r.pagePadding, 8, r.pagePadding, 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border(0.28)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBrown.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            if (showBack) ...[
              AppBackButton(onPressed: onBack),
              const SizedBox(width: 10),
            ],
            _IconBadge(icon: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      height: 1.15,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textLight.withOpacity(0.95),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 6),
                    Container(
                      width: 28,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.accentGold.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD4A574),
            Color(0xFFB8845A),
            Color(0xFF8B4513),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBrown.withOpacity(0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

/// Pinned sliver variant — same look as [AppPageHeader].
class AppSliverHeader extends StatelessWidget {
  const AppSliverHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.coffee_rounded,
    this.trailing,
    this.onBack,
    this.showBack = true,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onBack;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.primaryBg,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 84,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      centerTitle: false,
      title: AppPageHeader(
        title: title,
        subtitle: subtitle,
        icon: icon,
        trailing: trailing,
        onBack: onBack,
        showBack: showBack,
      ),
    );
  }
}
