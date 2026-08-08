import 'package:beanbloss/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Inset floating bottom sheet chrome with drag handle.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: isScrollControlled,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: 12 + MediaQuery.viewInsetsOf(ctx).bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(AppRadii.xxl),
            border: Border.all(color: AppColors.border(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textLight.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Flexible(child: builder(ctx)),
            ],
          ),
        ),
      );
    },
  );
}

class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    this.hintText = 'Search coffee, drinks…',
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border(0.22)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          color: AppColors.textDark,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: AppColors.primaryBrown,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: AppColors.textLight.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(
              Icons.search_rounded,
              color: AppColors.textLight.withOpacity(0.75),
              size: 22,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                onPressed: controller.clear,
                icon: Icon(
                  Icons.close_rounded,
                  color: AppColors.textLight.withOpacity(0.8),
                  size: 18,
                ),
              );
            },
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 13,
          ),
        ),
      ),
    );
  }
}
