import 'package:beanbloss/screens/HomeScreens/menu_screen.dart';
import 'package:beanbloss/screens/HomeScreens/product_detail_screen.dart';
import 'package:beanbloss/services/user_service.dart';
import 'package:beanbloss/state/cart_store.dart';
import 'package:beanbloss/theme/app_colors.dart';
import 'package:beanbloss/utils/responsive.dart';
import 'package:beanbloss/widgets/app_detail_bar.dart';
import 'package:beanbloss/widgets/app_empty_state.dart';
import 'package:beanbloss/widgets/product_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({
    super.key,
    required this.allProducts,
    required this.favoriteIds,
    required this.onRemoveFavorite,
    required this.onAddToCart,
  });

  final List<CoffeeProduct> allProducts;
  final List<String> favoriteIds;
  final ValueChanged<String> onRemoveFavorite;
  final ValueChanged<CoffeeProduct> onAddToCart;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    UserService.instance.addListener(_onChanged);
  }

  @override
  void dispose() {
    UserService.instance.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  List<String> get _ids => UserService.instance.favoriteProductIds;

  List<CoffeeProduct> get _items =>
      widget.allProducts.where((p) => _ids.contains(p.id)).toList();

  void _remove(String id) {
    HapticFeedback.lightImpact();
    widget.onRemoveFavorite(id);
  }

  void _add(CoffeeProduct product) {
    HapticFeedback.mediumImpact();
    widget.onAddToCart(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        backgroundColor: AppColors.primaryBrown,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addAll() {
    final items = _items;
    if (items.isEmpty) return;
    HapticFeedback.mediumImpact();
    for (final p in items) {
      widget.onAddToCart(p);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${items.length} favorites added to cart'),
        backgroundColor: AppColors.primaryBrown,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _openProduct(CoffeeProduct product) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: product),
      ),
    );
  }

  void _browseMenu() {
    HapticFeedback.selectionClick();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MenuCardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final items = _items;

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      body: SafeArea(
        child: Column(
          children: [
            AppDetailBar(
              title: 'Favorites',
              subtitle: items.isEmpty
                  ? null
                  : (items.length == 1
                      ? '1 saved drink'
                      : '${items.length} saved drinks'),
            ),
            Expanded(
              child: items.isEmpty
                  ? AppEmptyState(
                      icon: Icons.favorite_border_rounded,
                      title: 'No favorites yet',
                      subtitle:
                          'Tap the heart on any drink to save it here for quick reorder.',
                      actionLabel: 'Browse menu',
                      onAction: _browseMenu,
                    )
                  : ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        r.pagePadding,
                        14,
                        r.pagePadding,
                        32,
                      ),
                      children: [
                        _FavoritesHero(
                          count: items.length,
                          coverImages: items
                              .take(3)
                              .map((e) => e.imageUrl)
                              .toList(),
                          onAddAll: _addAll,
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'SAVED FOR LATER',
                          style: TextStyle(
                            color: AppColors.textLight.withOpacity(0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...items.map(
                          (product) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _FavoriteCard(
                              product: product,
                              onTap: () => _openProduct(product),
                              onRemove: () => _remove(product.id),
                              onAdd: () => _add(product),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoritesHero extends StatelessWidget {
  const _FavoritesHero({
    required this.count,
    required this.coverImages,
    required this.onAddAll,
  });

  final int count;
  final List<String> coverImages;
  final VoidCallback onAddAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5A2E12).withOpacity(0.26),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF3D2112),
                      Color(0xFF6B3A1F),
                      Color(0xFF8B4513),
                      Color(0xFFC4895A),
                    ],
                    stops: [0.0, 0.32, 0.68, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -40,
              right: -24,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
            ),
            Positioned(
              bottom: -36,
              left: -16,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'YOUR PICKS',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.28),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.favorite_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$count saved',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final narrow = constraints.maxWidth < 300;
                      final titleBlock = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saved for later',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: narrow ? 18 : 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'One tap to add your favorites to the cart.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12.5,
                              height: 1.35,
                            ),
                          ),
                        ],
                      );

                      if (narrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CoverStack(images: coverImages),
                            const SizedBox(height: 12),
                            titleBlock,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          _CoverStack(images: coverImages),
                          const SizedBox(width: 14),
                          Expanded(child: titleBlock),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onAddAll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryBrown,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_shopping_cart_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Add all to cart',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverStack extends StatelessWidget {
  const _CoverStack({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    final show = images.take(3).toList();
    if (show.isEmpty) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.favorite_rounded, color: Colors.white),
      );
    }

    final width = 64.0 + ((show.length - 1) * 18.0);

    return SizedBox(
      width: width,
      height: 64,
      child: Stack(
        children: [
          for (var i = 0; i < show.length; i++)
            Positioned(
              left: i * 18.0,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: ProductImage(
                    imageUrl: show[i],
                    fit: BoxFit.cover,
                    placeholderColor: AppColors.softFill(),
                    iconColor: AppColors.primaryBrown,
                    iconSize: 28,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.product,
    required this.onTap,
    required this.onRemove,
    required this.onAdd,
  });

  final CoffeeProduct product;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final imageSize = width < 360 ? 72.0 : (width < 400 ? 80.0 : 88.0);
    final titleSize = width < 360 ? 13.5 : 15.0;
    final compact = width < 360;

    return Material(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border()),
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 10 : 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ProductImage(
                        imageUrl: product.imageUrl,
                        width: imageSize,
                        height: imageSize,
                        fit: BoxFit.cover,
                        placeholderColor: AppColors.softFill(),
                        iconColor: AppColors.primaryBrown,
                        iconSize: 28,
                      ),
                    ),
                    if (product.isPopular)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBrown,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Popular',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: compact ? 10 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textDark,
                                fontSize: titleSize,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: onRemove,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: AppColors.destructive.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.favorite_rounded,
                                size: 15,
                                color: AppColors.destructive.withOpacity(0.95),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        product.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: compact ? 11.5 : 12.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 13,
                            color: AppColors.accentGold,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            product.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              '  ·  ${product.preparationTime}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textLight.withOpacity(0.9),
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: AppColors.primaryBrown,
                              fontSize: compact ? 14 : 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: onAdd,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: compact ? 10 : 12,
                                vertical: compact ? 6 : 7,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBrown,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_rounded,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    'Add',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
