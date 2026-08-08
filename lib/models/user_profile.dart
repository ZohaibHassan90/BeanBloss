import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.photoUrl = '',
    this.rewardsPoints = 0,
    this.rewardsTier = 'Bronze',
    this.favoriteOrder = '',
    this.favoriteProductIds = const [],
    this.fcmToken = '',
    this.createdAt,
  });

  final String uid;
  final String name;
  final String email;
  final String phone;
  /// Cloudinary HTTPS URL for avatar — empty until uploaded.
  final String photoUrl;
  final int rewardsPoints;
  final String rewardsTier;
  final String favoriteOrder;
  final List<String> favoriteProductIds;
  final String fcmToken;
  final DateTime? createdAt;

  bool isFavorite(String productId) => favoriteProductIds.contains(productId);

  String get firstName {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      if (email.contains('@')) {
        final local = email.split('@').first.trim();
        if (local.isNotEmpty) {
          return local[0].toUpperCase() + local.substring(1);
        }
      }
      return 'Guest';
    }
    return trimmed.split(RegExp(r'\s+')).first;
  }

  String get memberSinceLabel {
    final d = createdAt;
    if (d == null) return 'BeanBloss member';
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    DateTime? created;
    final raw = data['createdAt'];
    if (raw is Timestamp) {
      created = raw.toDate();
    } else if (raw is DateTime) {
      created = raw;
    }

    final favRaw = data['favoriteProductIds'];
    final favorites = <String>[];
    if (favRaw is List) {
      for (final e in favRaw) {
        if (e is String && e.isNotEmpty) favorites.add(e);
      }
    }

    return UserProfile(
      uid: uid,
      name: (data['name'] as String?)?.trim() ?? '',
      email: (data['email'] as String?)?.trim() ?? '',
      phone: (data['phone'] as String?)?.trim() ?? '',
      photoUrl: (data['photoUrl'] as String?)?.trim() ?? '',
      rewardsPoints: (data['rewardsPoints'] as num?)?.toInt() ?? 0,
      rewardsTier: (data['rewardsTier'] as String?) ?? 'Bronze',
      favoriteOrder: (data['favoriteOrder'] as String?) ?? '',
      favoriteProductIds: favorites,
      fcmToken: (data['fcmToken'] as String?)?.trim() ?? '',
      createdAt: created,
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'photoUrl': photoUrl.trim(),
      'rewardsPoints': rewardsPoints,
      'rewardsTier': rewardsTier,
      'favoriteOrder': favoriteOrder,
      'favoriteProductIds': favoriteProductIds,
      'fcmToken': fcmToken,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    int? rewardsPoints,
    String? rewardsTier,
    String? favoriteOrder,
    List<String>? favoriteProductIds,
    String? fcmToken,
    DateTime? createdAt,
  }) {
    return UserProfile(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      rewardsPoints: rewardsPoints ?? this.rewardsPoints,
      rewardsTier: rewardsTier ?? this.rewardsTier,
      favoriteOrder: favoriteOrder ?? this.favoriteOrder,
      favoriteProductIds: favoriteProductIds ?? this.favoriteProductIds,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
