import 'package:beanbloss/models/app_order.dart';
import 'package:beanbloss/models/coffee_product.dart';
import 'package:beanbloss/services/order_service.dart';
import 'package:beanbloss/services/product_service.dart';
import 'package:flutter/foundation.dart';

export 'package:beanbloss/models/coffee_product.dart';

/// Shared cart + active pickup order for the whole app.
class CartStore extends ChangeNotifier {
  CartStore._();
  static final CartStore instance = CartStore._();

  final List<CartLine> items = [];
  String? appliedPromo;
  double promoDiscount = 0;

  /// Mirrored from [OrderService] for older call sites.
  AppOrder? get activeOrder => OrderService.instance.activeOrder;

  int get itemCount => items.fold(0, (s, i) => s + i.quantity);

  double get subtotal => items.fold(0.0, (s, i) => s + i.totalPrice);

  double get tax => subtotal * 0.08;

  double get total => (subtotal + tax - promoDiscount).clamp(0, double.infinity);

  void addProduct(
    CoffeeProduct product, {
    int quantity = 1,
    String? size,
    String? milkType,
    String? temperature,
    int? extraShots,
  }) {
    final existing = items.indexWhere(
      (i) =>
          i.product.id == product.id &&
          i.size == size &&
          i.milkType == milkType &&
          i.temperature == temperature &&
          i.extraShots == extraShots,
    );
    if (existing >= 0) {
      items[existing].quantity += quantity;
    } else {
      items.add(
        CartLine(
          product: product,
          quantity: quantity,
          size: size,
          milkType: milkType,
          temperature: temperature,
          extraShots: extraShots,
        ),
      );
    }
    _recalcPromo();
    notifyListeners();
  }

  void addNamedItems(List<String> names, {String? fromOrderId}) {
    for (var i = 0; i < names.length; i++) {
      final name = names[i];
      final meta = _catalog[name];
      addProduct(
        CoffeeProduct(
          id: 'reorder-${fromOrderId ?? 'x'}-$i',
          name: name,
          description: meta?.desc ?? 'From your past BeanBloss order',
          price: meta?.price ?? 4.00,
          rating: 4.8,
          imageUrl: meta?.image ?? 'assets/images/on2.jpg',
          category: meta?.category ?? 'Coffee',
          preparationTime: '5 mins',
          calories: 180,
        ),
        quantity: 1,
        size: 'Medium',
      );
    }
  }

  void addFromOrderLines(List<OrderLineItem> lines, {String? fromOrderId}) {
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final catalog = ProductService.instance.byId(line.productId);
      final product = catalog ??
          CoffeeProduct(
            id: line.productId.isNotEmpty
                ? line.productId
                : 'reorder-${fromOrderId ?? 'x'}-$i',
            name: line.name,
            description: 'From your past BeanBloss order',
            price: line.unitPrice,
            rating: 4.8,
            imageUrl: line.imageUrl,
            category: 'Coffee',
            preparationTime: '5 mins',
            calories: 180,
          );
      addProduct(
        product,
        quantity: line.quantity,
        size: line.size,
        milkType: line.milkType,
        temperature: line.temperature,
        extraShots: line.extraShots,
      );
    }
  }

  void setQuantity(int index, int quantity) {
    if (index < 0 || index >= items.length) return;
    if (quantity <= 0) {
      items.removeAt(index);
    } else {
      items[index].quantity = quantity;
    }
    _recalcPromo();
    notifyListeners();
  }

  void removeAt(int index) {
    if (index < 0 || index >= items.length) return;
    items.removeAt(index);
    _recalcPromo();
    notifyListeners();
  }

  void clear() {
    items.clear();
    appliedPromo = null;
    promoDiscount = 0;
    notifyListeners();
  }

  void clearSession() {
    items.clear();
    appliedPromo = null;
    promoDiscount = 0;
    OrderService.instance.clear();
    notifyListeners();
  }

  bool applyPromo(String code) {
    final c = code.trim().toUpperCase();
    final rate = _promoRate(c);
    if (rate == null) return false;
    appliedPromo = c;
    promoDiscount = items.isEmpty ? 0 : subtotal * rate;
    notifyListeners();
    return true;
  }

  void clearPromo() {
    appliedPromo = null;
    promoDiscount = 0;
    notifyListeners();
  }

  void _recalcPromo() {
    if (appliedPromo == null) {
      promoDiscount = 0;
      return;
    }
    final rate = _promoRate(appliedPromo!);
    promoDiscount =
        rate == null || items.isEmpty ? 0 : subtotal * rate;
  }

  double? _promoRate(String code) {
    const table = {
      'WELCOME10': 0.10,
      'STUDENT15': 0.15,
      'LOYALTY20': 0.20,
      'ARABICA20': 0.20,
      'ESPRESSO15': 0.15,
      'COLDBREW25': 0.25,
      'WEEKEND': 0.15,
      'BOGOESP': 0.15,
    };
    return table[code];
  }

  /// Persists the cart to Firestore and clears local cart lines.
  Future<AppOrder> placeOrder() async {
    final order = await OrderService.instance.createFromCart(this);
    items.clear();
    appliedPromo = null;
    promoDiscount = 0;
    notifyListeners();
    return order;
  }

  static const _catalog = <String,
      ({String image, String category, double price, String desc})>{
    'Caramel Macchiato': (
      image: 'assets/images/on2.jpg',
      category: 'Latte',
      price: 4.75,
      desc: 'Espresso with steamed milk and caramel',
    ),
    'Chocolate Croissant': (
      image: 'assets/images/on1.jpg',
      category: 'Pastries',
      price: 3.25,
      desc: 'Buttery croissant with rich chocolate',
    ),
    'Flat White': (
      image: 'assets/images/on3.jpg',
      category: 'Latte',
      price: 4.25,
      desc: 'Velvety espresso with microfoam',
    ),
    'Blueberry Muffin': (
      image: 'assets/images/on4.jpg',
      category: 'Pastries',
      price: 3.25,
      desc: 'Soft muffin with blueberries',
    ),
    'Cold Brew Coffee': (
      image: 'assets/images/on4.jpg',
      category: 'Cold Brew',
      price: 3.50,
      desc: 'Smooth and refreshing cold brew',
    ),
    'Almond Biscotti': (
      image: 'assets/images/on1.jpg',
      category: 'Pastries',
      price: 2.75,
      desc: 'Crisp almond biscuit',
    ),
    'Classic Americano': (
      image: 'assets/images/on3.jpg',
      category: 'Espresso',
      price: 3.25,
      desc: 'Bold espresso with hot water',
    ),
    'Vanilla Latte': (
      image: 'assets/images/on2.jpg',
      category: 'Latte',
      price: 4.25,
      desc: 'Smooth espresso with steamed milk and vanilla',
    ),
    'Iced Cappuccino': (
      image: 'assets/images/on4.jpg',
      category: 'Cappuccino',
      price: 3.75,
      desc: 'Refreshing cappuccino served cold',
    ),
    'Cold Brew Original': (
      image: 'assets/images/on4.jpg',
      category: 'Cold Brew',
      price: 3.50,
      desc: 'Smooth and refreshing cold brew',
    ),
    'Mocha Frappé': (
      image: 'assets/images/on4.jpg',
      category: 'Frappé',
      price: 5.25,
      desc: 'Chocolate and coffee blended perfection',
    ),
    'Iced Americano': (
      image: 'assets/images/on3.jpg',
      category: 'Cold Drinks',
      price: 3.50,
      desc: 'Bold espresso over ice',
    ),
  };
}

class CartLine {
  CartLine({
    required this.product,
    required this.quantity,
    this.size,
    this.milkType,
    this.sweetness,
    this.temperature,
    this.extraShots,
    this.specialInstructions,
  });

  final CoffeeProduct product;
  int quantity;
  final String? size;
  final String? milkType;
  final String? sweetness;
  final String? temperature;
  final int? extraShots;
  final String? specialInstructions;

  double get totalPrice {
    var base = product.price;
    switch (size) {
      case 'Small':
        base -= 0.50;
        break;
      case 'Large':
        base += 0.75;
        break;
      case 'Extra Large':
        base += 1.25;
        break;
    }
    if (milkType != null && milkType != 'Whole Milk') {
      base += 0.60;
    }
    if (extraShots != null) {
      base += extraShots! * 0.75;
    }
    return base * quantity;
  }
}
