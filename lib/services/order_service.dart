import 'dart:async';

import 'package:beanbloss/models/app_order.dart';
import 'package:beanbloss/services/notification_service.dart';
import 'package:beanbloss/state/cart_store.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class OrderService extends ChangeNotifier {
  OrderService._();
  static final OrderService instance = OrderService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders');

  AppOrder? _active;
  AppOrder? get activeOrder => _active;

  List<AppOrder> _recent = [];
  List<AppOrder> get recentOrders => List.unmodifiable(_recent);

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _activeSub;
  Timer? _demoTimer;
  final List<Timer> _demoSteps = [];

  Future<AppOrder> createFromCart(CartStore cart) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('You must be signed in to place an order.');
    }
    if (cart.items.isEmpty) {
      throw StateError('Your cart is empty.');
    }

    final lines = cart.items.map((line) {
      final unit = line.quantity == 0 ? 0.0 : line.totalPrice / line.quantity;
      return OrderLineItem(
        productId: line.product.id,
        name: line.product.name,
        imageUrl: line.product.imageUrl,
        unitPrice: unit,
        quantity: line.quantity,
        size: line.size,
        milkType: line.milkType,
        temperature: line.temperature,
        extraShots: line.extraShots,
      );
    }).toList();

    final orderNumber =
        'ORD-${DateTime.now().millisecondsSinceEpoch % 100000}';
    final draft = AppOrder(
      id: '',
      orderNumber: orderNumber,
      userId: user.uid,
      items: lines,
      subtotal: cart.subtotal,
      tax: cart.tax,
      promoDiscount: cart.promoDiscount,
      total: cart.total,
      status: OrderStatus.received,
      placedAt: DateTime.now(),
      promoCode: cart.appliedPromo,
      paymentMethod: PaymentMethod.payAtPickup,
      paymentStatus: PaymentStatus.unpaid,
    );

    final ref = await _orders.add(draft.toCreateMap());
    final snap = await ref.get();
    final data = snap.data();
    final order = data != null
        ? AppOrder.fromMap(ref.id, data)
        : AppOrder(
            id: ref.id,
            orderNumber: orderNumber,
            userId: user.uid,
            items: lines,
            subtotal: draft.subtotal,
            tax: draft.tax,
            promoDiscount: draft.promoDiscount,
            total: draft.total,
            status: OrderStatus.received,
            placedAt: DateTime.now(),
            promoCode: draft.promoCode,
            paymentMethod: PaymentMethod.payAtPickup,
            paymentStatus: PaymentStatus.unpaid,
          );

    _active = order;
    notifyListeners();
    watchOrder(order.id);
    startDemoStatusProgress(order.id);
    unawaited(
      NotificationService.instance.notifyOrderStatus(
        orderNumber: order.orderNumber,
        status: OrderStatus.received,
      ),
    );
    return order;
  }

  void watchOrder(String orderId) {
    _activeSub?.cancel();
    _activeSub = _orders.doc(orderId).snapshots().listen((snap) {
      if (!snap.exists || snap.data() == null) return;
      _active = AppOrder.fromMap(snap.id, snap.data()!);
      notifyListeners();
    }, onError: (_) {});
  }

  Stream<AppOrder?> orderStream(String orderId) {
    return _orders.doc(orderId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return AppOrder.fromMap(snap.id, snap.data()!);
    });
  }

  /// Load newest active order for the signed-in user (for Track / splash).
  Future<AppOrder?> loadActiveOrder() async {
    final user = _auth.currentUser;
    if (user == null) {
      _active = null;
      notifyListeners();
      return null;
    }

    final snap = await _orders.where('userId', isEqualTo: user.uid).get();
    final orders = snap.docs
        .map((d) => AppOrder.fromMap(d.id, d.data()))
        .where((o) => o.status.isActive)
        .toList()
      ..sort((a, b) => b.placedAt.compareTo(a.placedAt));

    if (orders.isEmpty) {
      _active = null;
      notifyListeners();
      return null;
    }

    _active = orders.first;
    watchOrder(_active!.id);
    notifyListeners();
    return _active;
  }

  Future<List<AppOrder>> loadRecentOrders({int limit = 20}) async {
    final user = _auth.currentUser;
    if (user == null) {
      _recent = [];
      notifyListeners();
      return _recent;
    }

    final snap = await _orders.where('userId', isEqualTo: user.uid).get();
    final orders = snap.docs
        .map((d) => AppOrder.fromMap(d.id, d.data()))
        .toList()
      ..sort((a, b) => b.placedAt.compareTo(a.placedAt));

    _recent = orders.take(limit).toList();
    notifyListeners();
    return _recent;
  }

  Future<void> updateStatus(String orderId, OrderStatus status) async {
    await _orders.doc(orderId).update({
      'status': status.firestoreValue,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final number = (_active?.id == orderId)
        ? _active!.orderNumber
        : (_active?.orderNumber ?? orderId);
    unawaited(
      NotificationService.instance.notifyOrderStatus(
        orderNumber: number,
        status: status,
      ),
    );
  }

  /// Demo only: advances status so Track updates without a staff app.
  void startDemoStatusProgress(String orderId) {
    _cancelDemo();
    const steps = [
      (Duration(seconds: 8), OrderStatus.preparing),
      (Duration(seconds: 18), OrderStatus.almostReady),
      (Duration(seconds: 28), OrderStatus.ready),
    ];
    for (final step in steps) {
      _demoSteps.add(
        Timer(step.$1, () async {
          try {
            await updateStatus(orderId, step.$2);
          } catch (_) {}
        }),
      );
    }
  }

  void _cancelDemo() {
    for (final t in _demoSteps) {
      t.cancel();
    }
    _demoSteps.clear();
    _demoTimer?.cancel();
    _demoTimer = null;
  }

  void clear() {
    _cancelDemo();
    _activeSub?.cancel();
    _activeSub = null;
    _active = null;
    _recent = [];
    notifyListeners();
  }
}
