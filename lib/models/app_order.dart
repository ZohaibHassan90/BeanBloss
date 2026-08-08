import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  received,
  preparing,
  almostReady,
  ready,
  completed,
  cancelled;

  String get firestoreValue => name;

  static OrderStatus fromString(String? raw) {
    switch (raw) {
      case 'received':
        return OrderStatus.received;
      case 'preparing':
        return OrderStatus.preparing;
      case 'almostReady':
        return OrderStatus.almostReady;
      case 'ready':
        return OrderStatus.ready;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.received;
    }
  }

  bool get isActive =>
      this == OrderStatus.received ||
      this == OrderStatus.preparing ||
      this == OrderStatus.almostReady ||
      this == OrderStatus.ready;

  String get label {
    switch (this) {
      case OrderStatus.received:
        return 'Order received';
      case OrderStatus.preparing:
        return 'Being prepared';
      case OrderStatus.almostReady:
        return 'Almost ready';
      case OrderStatus.ready:
        return 'Ready for pickup';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Rough ETA for the track UI.
  int get etaMinutes {
    switch (this) {
      case OrderStatus.received:
        return 12;
      case OrderStatus.preparing:
        return 8;
      case OrderStatus.almostReady:
        return 3;
      case OrderStatus.ready:
      case OrderStatus.completed:
      case OrderStatus.cancelled:
        return 0;
    }
  }
}

class OrderLineItem {
  const OrderLineItem({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.unitPrice,
    required this.quantity,
    this.size,
    this.milkType,
    this.temperature,
    this.extraShots,
  });

  final String productId;
  final String name;
  final String imageUrl;
  final double unitPrice;
  final int quantity;
  final String? size;
  final String? milkType;
  final String? temperature;
  final int? extraShots;

  double get lineTotal => unitPrice * quantity;

  String get detailLabel {
    final parts = <String>[
      if (size != null && size!.isNotEmpty) size!,
      if (milkType != null && milkType!.isNotEmpty) milkType!,
      if (temperature != null && temperature!.isNotEmpty) temperature!,
      if (extraShots != null && extraShots! > 0) '+${extraShots!} shot',
    ];
    return parts.isEmpty ? 'Pickup item' : parts.join(' · ');
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'imageUrl': imageUrl,
        'unitPrice': unitPrice,
        'quantity': quantity,
        if (size != null) 'size': size,
        if (milkType != null) 'milkType': milkType,
        if (temperature != null) 'temperature': temperature,
        if (extraShots != null) 'extraShots': extraShots,
      };

  factory OrderLineItem.fromMap(Map<String, dynamic> data) {
    return OrderLineItem(
      productId: (data['productId'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      imageUrl: (data['imageUrl'] as String?) ?? 'assets/images/on2.jpg',
      unitPrice: (data['unitPrice'] as num?)?.toDouble() ?? 0,
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      size: data['size'] as String?,
      milkType: data['milkType'] as String?,
      temperature: data['temperature'] as String?,
      extraShots: (data['extraShots'] as num?)?.toInt(),
    );
  }
}

enum PaymentMethod {
  payAtPickup;

  String get firestoreValue {
    switch (this) {
      case PaymentMethod.payAtPickup:
        return 'pay_at_pickup';
    }
  }

  String get label {
    switch (this) {
      case PaymentMethod.payAtPickup:
        return 'Pay at pickup';
    }
  }

  static PaymentMethod fromString(String? raw) {
    switch (raw) {
      case 'pay_at_pickup':
      default:
        return PaymentMethod.payAtPickup;
    }
  }
}

enum PaymentStatus {
  unpaid,
  paid;

  String get firestoreValue => name;

  String get label {
    switch (this) {
      case PaymentStatus.unpaid:
        return 'Pay at counter';
      case PaymentStatus.paid:
        return 'Paid';
    }
  }

  static PaymentStatus fromString(String? raw) {
    switch (raw) {
      case 'paid':
        return PaymentStatus.paid;
      case 'unpaid':
      default:
        return PaymentStatus.unpaid;
    }
  }
}

class AppOrder {
  const AppOrder({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.promoDiscount,
    required this.total,
    required this.status,
    required this.placedAt,
    this.promoCode,
    this.paymentMethod = PaymentMethod.payAtPickup,
    this.paymentStatus = PaymentStatus.unpaid,
  });

  final String id;
  final String orderNumber;
  final String userId;
  final List<OrderLineItem> items;
  final double subtotal;
  final double tax;
  final double promoDiscount;
  final double total;
  final OrderStatus status;
  final DateTime placedAt;
  final String? promoCode;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;

  List<String> get itemNames {
    final names = <String>[];
    for (final line in items) {
      for (var i = 0; i < line.quantity; i++) {
        names.add(line.name);
      }
    }
    return names;
  }

  String get whenLabel {
    final now = DateTime.now();
    final local = placedAt.toLocal();
    final sameDay = now.year == local.year &&
        now.month == local.month &&
        now.day == local.day;
    final yesterday = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));
    final wasYesterday = yesterday.year == local.year &&
        yesterday.month == local.month &&
        yesterday.day == local.day;

    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    final time = '$h:$m $ampm';

    if (sameDay) return 'Today · $time';
    if (wasYesterday) return 'Yesterday · $time';
    return '${local.day}/${local.month}/${local.year} · $time';
  }

  factory AppOrder.fromMap(String id, Map<String, dynamic> data) {
    DateTime placed = DateTime.now();
    final raw = data['placedAt'];
    if (raw is Timestamp) {
      placed = raw.toDate();
    } else if (raw is DateTime) {
      placed = raw;
    }

    final rawItems = data['items'];
    final items = <OrderLineItem>[];
    if (rawItems is List) {
      for (final entry in rawItems) {
        if (entry is Map<String, dynamic>) {
          items.add(OrderLineItem.fromMap(entry));
        } else if (entry is Map) {
          items.add(OrderLineItem.fromMap(Map<String, dynamic>.from(entry)));
        }
      }
    }

    return AppOrder(
      id: id,
      orderNumber: (data['orderNumber'] as String?) ?? id,
      userId: (data['userId'] as String?) ?? '',
      items: items,
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0,
      tax: (data['tax'] as num?)?.toDouble() ?? 0,
      promoDiscount: (data['promoDiscount'] as num?)?.toDouble() ?? 0,
      total: (data['total'] as num?)?.toDouble() ?? 0,
      status: OrderStatus.fromString(data['status'] as String?),
      placedAt: placed,
      promoCode: data['promoCode'] as String?,
      paymentMethod: PaymentMethod.fromString(data['paymentMethod'] as String?),
      paymentStatus: PaymentStatus.fromString(data['paymentStatus'] as String?),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'orderNumber': orderNumber,
      'userId': userId,
      'items': items.map((e) => e.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'promoDiscount': promoDiscount,
      'total': total,
      'status': status.firestoreValue,
      'paymentMethod': paymentMethod.firestoreValue,
      'paymentStatus': paymentStatus.firestoreValue,
      'placedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (promoCode != null) 'promoCode': promoCode,
    };
  }
}
