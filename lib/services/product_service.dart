import 'package:beanbloss/data/menu_seed.dart';
import 'package:beanbloss/models/coffee_product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ProductService extends ChangeNotifier {
  ProductService._();
  static final ProductService instance = ProductService._();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection('products');

  List<CoffeeProduct> _items = [];
  List<CoffeeProduct> get products => List.unmodifiable(_items);

  bool _loading = false;
  bool get isLoading => _loading;

  String? _error;
  String? get error => _error;

  bool _seededCheckDone = false;

  CoffeeProduct? byId(String id) {
    for (final p in _items) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<CoffeeProduct> byCategory(String category) {
    if (category == 'All') return products;
    return _items.where((p) => p.category == category).toList();
  }

  Map<String, List<CoffeeProduct>> get groupedByCategory {
    final map = <String, List<CoffeeProduct>>{};
    for (final p in _items) {
      map.putIfAbsent(p.category, () => []).add(p);
    }
    return map;
  }

  /// Load available products. Seeds the collection once if empty.
  Future<void> loadProducts({bool forceRefresh = false}) async {
    if (_loading) return;
    if (!forceRefresh && _items.isNotEmpty) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _ensureSeeded();
      final snap = await _products
          .where('available', isEqualTo: true)
          .get();

      final list = snap.docs
          .map((d) => CoffeeProduct.fromMap(d.id, d.data()))
          .toList()
        ..sort((a, b) {
          final byOrder = a.sortOrder.compareTo(b.sortOrder);
          if (byOrder != 0) return byOrder;
          return a.name.compareTo(b.name);
        });

      _items = list;
    } catch (e) {
      _error = e.toString();
      // Offline / rules: fall back to local seed so Home still works.
      if (_items.isEmpty) {
        _items = List<CoffeeProduct>.from(MenuSeed.products)
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _ensureSeeded() async {
    if (_seededCheckDone) return;
    final existing = await _products.limit(1).get();
    if (existing.docs.isNotEmpty) {
      _seededCheckDone = true;
      return;
    }

    final batch = _db.batch();
    for (final product in MenuSeed.products) {
      batch.set(_products.doc(product.id), product.toFirestoreMap());
    }
    await batch.commit();
    _seededCheckDone = true;
  }

  /// Set a Cloudinary (or other HTTPS) image URL on a product doc.
  Future<void> updateImageUrl(String productId, String imageUrl) async {
    final url = imageUrl.trim();
    if (productId.isEmpty || url.isEmpty) return;
    await _products.doc(productId).set({
      'imageUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await loadProducts(forceRefresh: true);
  }

  void clear() {
    _items = [];
    _error = null;
    _seededCheckDone = false;
    notifyListeners();
  }
}
