class CoffeeProduct {
  const CoffeeProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.rating,
    required this.imageUrl,
    required this.category,
    this.isPopular = false,
    required this.preparationTime,
    required this.calories,
    this.available = true,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final double rating;
  /// Asset path (`assets/...`) or Cloudinary HTTPS URL.
  final String imageUrl;
  final String category;
  final bool isPopular;
  final String preparationTime;
  final int calories;
  final bool available;
  final int sortOrder;

  bool get isRemoteImage {
    final u = imageUrl.trim();
    return u.startsWith('http://') || u.startsWith('https://');
  }

  factory CoffeeProduct.fromMap(String id, Map<String, dynamic> data) {
    return CoffeeProduct(
      id: id,
      name: (data['name'] as String?)?.trim() ?? '',
      description: (data['description'] as String?)?.trim() ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      imageUrl: (data['imageUrl'] as String?)?.trim() ??
          'assets/images/on2.jpg',
      category: (data['category'] as String?)?.trim() ?? 'Coffee',
      isPopular: data['isPopular'] as bool? ?? false,
      preparationTime:
          (data['preparationTime'] as String?)?.trim() ?? '5 min',
      calories: (data['calories'] as num?)?.toInt() ?? 0,
      available: data['available'] as bool? ?? true,
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'rating': rating,
      'imageUrl': imageUrl,
      'category': category,
      'isPopular': isPopular,
      'preparationTime': preparationTime,
      'calories': calories,
      'available': available,
      'sortOrder': sortOrder,
    };
  }
}
