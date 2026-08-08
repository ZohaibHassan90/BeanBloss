import 'package:beanbloss/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> launchBeanBlossDirections(BuildContext context) async {
  final query = Uri.encodeComponent('${AppBrand.street}, ${AppBrand.cityLine}');
  final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
  await _launch(context, uri, fallback: 'Could not open maps');
}

Future<void> launchBeanBlossPhone(BuildContext context) async {
  final digits = AppBrand.phone.replaceAll(RegExp(r'[^\d+]'), '');
  await _launch(
    context,
    Uri(scheme: 'tel', path: digits),
    fallback: 'Could not open phone',
  );
}

Future<void> launchBeanBlossEmail(BuildContext context) async {
  await _launch(
    context,
    Uri(
      scheme: 'mailto',
      path: AppBrand.email,
      queryParameters: {'subject': 'BeanBloss support'},
    ),
    fallback: 'Could not open email',
  );
}

Future<void> _launch(
  BuildContext context,
  Uri uri, {
  required String fallback,
}) async {
  HapticFeedback.selectionClick();
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      _snack(context, fallback);
    }
  } catch (_) {
    if (context.mounted) _snack(context, fallback);
  }
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.primaryBrown,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ),
  );
}
