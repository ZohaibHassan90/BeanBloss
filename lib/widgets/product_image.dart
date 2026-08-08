import 'package:flutter/material.dart';

/// Renders a product image from a Cloudinary HTTPS URL or a local asset path.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholderColor,
    this.iconColor,
    this.iconSize = 40,
  });

  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? placeholderColor;
  final Color? iconColor;
  final double iconSize;

  bool get _isRemote {
    final u = imageUrl.trim();
    return u.startsWith('http://') || u.startsWith('https://');
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: placeholderColor ?? Colors.brown.withOpacity(0.12),
      alignment: Alignment.center,
      child: Icon(
        Icons.local_cafe_rounded,
        color: iconColor ?? const Color(0xFFD4A574),
        size: iconSize,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = _isRemote
        ? Image.network(
            imageUrl,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, __, ___) => _placeholder(),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                width: width,
                height: height,
                color: placeholderColor ?? Colors.brown.withOpacity(0.08),
                alignment: Alignment.center,
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: iconColor ?? const Color(0xFFD4A574),
                  ),
                ),
              );
            },
          )
        : Image.asset(
            imageUrl.isEmpty ? 'assets/images/on2.jpg' : imageUrl,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, __, ___) => _placeholder(),
          );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }
}
