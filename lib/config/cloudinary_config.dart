/// Cloudinary settings for product / avatar images.
///
/// Never put API secret in the app. Firestore docs store full HTTPS URLs.
abstract final class CloudinaryConfig {
  // Pass via --dart-define (do not hardcode account values in git).
  static const cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: '',
  );

  /// Products / menu images → folder `beanbloss/products`
  static const productsUploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: '',
  );

  /// Profile avatars → folder `beanbloss/avatars`
  static const avatarsUploadPreset = String.fromEnvironment(
    'CLOUDINARY_AVATARS_UPLOAD_PRESET',
    defaultValue: '',
  );

  /// Alias for products (older call sites).
  static const uploadPreset = productsUploadPreset;

  static bool get isConfigured =>
      cloudName.isNotEmpty &&
      productsUploadPreset.isNotEmpty &&
      avatarsUploadPreset.isNotEmpty;

  /// Build a delivery URL from a public id (optional transforms).
  static String deliveryUrl(
    String publicId, {
    int? width,
    String quality = 'auto',
  }) {
    if (cloudName.isEmpty || publicId.isEmpty) return '';
    if (publicId.startsWith('http://') || publicId.startsWith('https://')) {
      return publicId;
    }
    final transforms = <String>[
      if (width != null) 'w_$width',
      'q_$quality',
      'f_auto',
    ].join(',');
    final path = transforms.isEmpty ? publicId : '$transforms/$publicId';
    return 'https://res.cloudinary.com/$cloudName/image/upload/$path';
  }
}
