import 'dart:convert';
import 'dart:io';

import 'package:beanbloss/config/cloudinary_config.dart';
import 'package:http/http.dart' as http;

enum CloudinaryUploadKind { avatar, product }

class CloudinaryService {
  CloudinaryService._();
  static final CloudinaryService instance = CloudinaryService._();

  Uri get _uploadUri => Uri.parse(
        'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload',
      );

  String _presetFor(CloudinaryUploadKind kind) {
    switch (kind) {
      case CloudinaryUploadKind.avatar:
        return CloudinaryConfig.avatarsUploadPreset;
      case CloudinaryUploadKind.product:
        return CloudinaryConfig.productsUploadPreset;
    }
  }

  /// Uploads an image file and returns the secure HTTPS delivery URL.
  Future<String> uploadImage(
    File file, {
    required CloudinaryUploadKind kind,
  }) async {
    if (!CloudinaryConfig.isConfigured) {
      throw StateError('Cloudinary is not configured.');
    }
    if (!await file.exists()) {
      throw StateError('Image file not found.');
    }

    final request = http.MultipartRequest('POST', _uploadUri)
      ..fields['upload_preset'] = _presetFor(kind)
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw StateError('Upload failed (${streamed.statusCode}).');
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    final url = (json['secure_url'] as String?)?.trim();
    if (url == null || url.isEmpty) {
      throw StateError('Upload succeeded but no image URL was returned.');
    }
    return url;
  }
}
