import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beanbloss/models/user_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class UserService extends ChangeNotifier {
  UserService._();
  static final UserService instance = UserService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  UserProfile? _cached;
  UserProfile? get cached => _cached;

  List<String> get favoriteProductIds =>
      List<String>.from(_cached?.favoriteProductIds ?? const []);

  bool isFavorite(String productId) =>
      _cached?.isFavorite(productId) ?? false;

  Future<void> createUserProfile({
    required String uid,
    required String name,
    required String email,
  }) async {
    final profile = UserProfile(
      uid: uid,
      name: name.trim(),
      email: email.trim().toLowerCase(),
    );
    await _users.doc(uid).set(profile.toCreateMap());
    _cached = UserProfile(
      uid: uid,
      name: profile.name,
      email: profile.email,
      createdAt: DateTime.now(),
    );
    notifyListeners();
  }

  /// Load profile; create a doc if Auth user exists but Firestore doc is missing.
  Future<UserProfile?> loadCurrentUser({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) {
      _cached = null;
      notifyListeners();
      return null;
    }

    if (!forceRefresh && _cached != null && _cached!.uid == user.uid) {
      return _cached;
    }

    final snap = await _users.doc(user.uid).get();
    if (snap.exists && snap.data() != null) {
      _cached = UserProfile.fromMap(user.uid, snap.data()!);
      notifyListeners();
      return _cached;
    }

    final name = (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!.trim()
        : (user.email?.split('@').first ?? 'Guest');
    final email = user.email ?? '';
    await createUserProfile(uid: user.uid, name: name, email: email);
    return _cached;
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? photoUrl,
    String? favoriteOrder,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final data = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (name != null) data['name'] = name.trim();
    if (phone != null) data['phone'] = phone.trim();
    if (photoUrl != null) data['photoUrl'] = photoUrl.trim();
    if (favoriteOrder != null) data['favoriteOrder'] = favoriteOrder.trim();

    await _users.doc(user.uid).set(data, SetOptions(merge: true));

    if (name != null && name.trim().isNotEmpty) {
      await user.updateDisplayName(name.trim());
      await user.reload();
    }

    await loadCurrentUser(forceRefresh: true);
  }

  Future<bool> toggleFavorite(String productId) async {
    final user = _auth.currentUser;
    if (user == null || productId.isEmpty) return false;

    final next = List<String>.from(_cached?.favoriteProductIds ?? const []);
    final added = !next.contains(productId);
    if (added) {
      next.add(productId);
    } else {
      next.remove(productId);
    }

    // Optimistic UI
    if (_cached != null) {
      _cached = _cached!.copyWith(favoriteProductIds: next);
      notifyListeners();
    }

    try {
      await _users.doc(user.uid).set({
        'favoriteProductIds': next,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Revert on failure
      if (_cached != null) {
        final revert = List<String>.from(next);
        if (added) {
          revert.remove(productId);
        } else {
          revert.add(productId);
        }
        _cached = _cached!.copyWith(favoriteProductIds: revert);
        notifyListeners();
      }
      rethrow;
    }
    return added;
  }

  Future<void> removeFavorite(String productId) async {
    if (!isFavorite(productId)) return;
    await toggleFavorite(productId);
  }

  Future<void> saveFcmToken(String token) async {
    final user = _auth.currentUser;
    if (user == null || token.isEmpty) return;
    if (_cached?.fcmToken == token) return;

    await _users.doc(user.uid).set({
      'fcmToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (_cached != null) {
      _cached = _cached!.copyWith(fcmToken: token);
      notifyListeners();
    }
  }

  void clear() {
    _cached = null;
    notifyListeners();
  }
}
