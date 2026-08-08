import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:beanbloss/models/coffee_product.dart';
import 'package:beanbloss/screens/HomeScreens/product_detail_screen.dart';
import 'package:beanbloss/services/product_service.dart';
import 'package:beanbloss/state/cart_store.dart';
import 'package:beanbloss/utils/responsive.dart';
import 'package:beanbloss/widgets/app_bottom_nav.dart';
import 'package:beanbloss/widgets/app_empty_state.dart';
import 'package:beanbloss/widgets/app_fab.dart';
import 'package:beanbloss/widgets/app_page_header.dart';
import 'package:beanbloss/widgets/app_sheet.dart';
import 'package:beanbloss/widgets/product_image.dart';

class MenuCardScreen extends StatefulWidget {
  const MenuCardScreen({Key? key}) : super(key: key);

  @override
  State<MenuCardScreen> createState() => _MenuCardScreenState();
}

class _MenuCardScreenState extends State<MenuCardScreen>
    with TickerProviderStateMixin {

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final TextEditingController _searchTextController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _selectedCategory = 'All';
  String _searchQuery = '';


  // Consistent color scheme
  static const Color primaryBg = Color(0xFFF5F1EB);
  static const Color cardBg = Color(0xFFFFFBF7);
  static const Color primaryBrown = Color(0xFF8B4513);
  static const Color accentGold = Color(0xFFD4A574);
  static const Color textDark = Color(0xFF2C1810);
  static const Color textLight = Color(0xFF8B7355);
  static const Color lightBrown = Color(0xFFA0522D);

  final List<String> categories = [
    'All',
    'Coffee',
    'Espresso',
    'Latte',
    'Cappuccino',
    'Cold Brew',
    'Frappé',
    'Tea',
    'Pastries',
    'Cold Drinks',
  ];

  Map<String, List<CoffeeProduct>> get menuItems =>
      ProductService.instance.groupedByCategory;

  List<CoffeeProduct> get filteredProducts {
    final all = ProductService.instance.products;
    Iterable<CoffeeProduct> list = all;

    if (_selectedCategory != 'All') {
      list = list.where((p) => p.category == _selectedCategory);
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where(
        (p) =>
            p.name.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q),
      );
    }

    return list.toList();
  }

  // Group products by category for "All" view
  Map<String, List<CoffeeProduct>> get groupedProducts {
    if (_selectedCategory != 'All' || _searchQuery.isNotEmpty) {
      return {_selectedCategory: filteredProducts};
    }

    return menuItems;
  }

  @override
  void initState() {
    super.initState();
    _searchTextController.addListener(() {
      setState(() {
        _searchQuery = _searchTextController.text;
      });
    });
    ProductService.instance.addListener(_onProductsChanged);
    ProductService.instance.loadProducts();
    _initializeAnimations();
    _setSystemUIStyle();
  }

  void _onProductsChanged() {
    if (mounted) setState(() {});
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    _animationController.forward();
  }

  void _setSystemUIStyle() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    ProductService.instance.removeListener(_onProductsChanged);
    _animationController.dispose();
    _searchTextController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _navigateToProduct(CoffeeProduct product) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ProductDetailScreen(product: product),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final media = MediaQuery.of(context);

    return MediaQuery(
      data: media.copyWith(
        textScaler: media.textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.15),
      ),
      child: Scaffold(
        backgroundColor: primaryBg,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Stack(
            children: [
              Positioned(
                top: -70,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentGold.withOpacity(0.12),
                  ),
                ),
              ),
              Positioned(
                top: 260,
                left: -80,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryBrown.withOpacity(0.05),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ((r.width - r.contentMaxWidth) / 2).clamp(0.0, 400.0),
                  ),
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      _buildAppBar(),
                      SliverToBoxAdapter(
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            children: [
                              _buildMenuHeader(),
                              _buildSearchBar(),
                              _buildCategoryTabs(),
                              const SizedBox(height: 4),
                            ],
                          ),
                        ),
                      ),
                      _buildMenuItems(),
                      SliverToBoxAdapter(
                        child: SizedBox(height: 110 + r.screenInsets.bottom),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        extendBody: true,
        floatingActionButton: const AppCartFab(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      ),
    );
  }

  Widget _buildAppBar() {
    return const AppSliverHeader(
      title: 'Menu',
      subtitle: 'Drinks, pastries & more',
      icon: Icons.menu_book_rounded,
      showBack: false,
    );
  }

  Widget _buildMenuHeader() {
    final r = Responsive.of(context);
    return Container(
      margin: EdgeInsets.fromLTRB(r.pagePadding, 14, r.pagePadding, 2),
      height: r.width < 360 ? 132 : (r.isTablet ? 168 : 148),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primaryBrown.withOpacity(0.26),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/on1.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: primaryBrown,
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    primaryBrown.withOpacity(0.95),
                    primaryBrown.withOpacity(0.78),
                    lightBrown.withOpacity(0.55),
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.05),
                    Colors.black.withOpacity(0.28),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.28),
                          ),
                        ),
                        child: const Text(
                          'TODAY\'S PICKS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accentGold.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: textDark,
                              size: 13,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '4.7 · $_totalItemCount items',
                              style: const TextStyle(
                                color: textDark,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Text(
                    'Crafted with care',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fresh beans, bold flavors, cozy vibes',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
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

  int get _totalItemCount {
    var count = 0;
    for (final products in menuItems.values) {
      count += products.length;
    }
    return count;
  }

  Widget _buildSearchBar() {
    final r = Responsive.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(r.pagePadding, 16, r.pagePadding, 8),
      child: AppSearchField(
        controller: _searchTextController,
        hintText: 'Search drinks, pastries...',
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: Responsive.of(context).pagePadding - 4),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                  _searchQuery = '';
                  _searchTextController.clear();
                });
                HapticFeedback.selectionClick();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [primaryBrown, lightBrown],
                        )
                      : null,
                  color: isSelected ? null : cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : accentGold.withOpacity(0.22),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? primaryBrown.withOpacity(0.25)
                          : primaryBrown.withOpacity(0.04),
                      blurRadius: isSelected ? 12 : 6,
                      offset: Offset(0, isSelected ? 5 : 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    category,
                    style: TextStyle(
                      color: isSelected ? Colors.white : textDark,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuItems() {
    if (_selectedCategory == 'All' && _searchQuery.isEmpty) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final category = categories[index + 1];
            final products = menuItems[category] ?? [];
            if (products.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: Responsive.of(context).pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategoryHeader(category, products.length),
                  ...products.map(_buildMenuItemCard),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
          childCount: categories.length - 1,
        ),
      );
    }

    final products = filteredProducts;

    if (products.isEmpty) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 280,
          child: AppEmptyState(
            icon: Icons.search_off_rounded,
            title: 'No items found',
            subtitle: 'Try a different search or category',
            actionLabel: 'Clear filters',
            onAction: () {
              _searchTextController.clear();
              setState(() {
                _selectedCategory = 'All';
                _searchQuery = '';
              });
            },
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(Responsive.of(context).pagePadding, 8, Responsive.of(context).pagePadding, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == 0) {
              return _buildCategoryHeader(
                _searchQuery.isNotEmpty ? 'Results' : _selectedCategory,
                products.length,
              );
            }
            return _buildMenuItemCard(products[index - 1]);
          },
          childCount: products.length + 1,
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(String category, [int? count]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: accentGold,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (count != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentGold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count items',
                    style: const TextStyle(
                      color: primaryBrown,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Text(
              _getCategoryDescription(category),
              style: TextStyle(
                color: textLight.withOpacity(0.95),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryDescription(String category) {
    switch (category) {
      case 'Coffee':
        return 'Signature blends roasted to perfection';
      case 'Espresso':
        return 'Bold shots with rich crema';
      case 'Latte':
        return 'Espresso with steamed milk and flavors';
      case 'Cappuccino':
        return 'Balanced espresso, milk, and foam';
      case 'Tea':
        return 'Premium teas and tea lattes';
      case 'Pastries':
        return 'Fresh bakes to pair with your drink';
      case 'Cold Drinks':
        return 'Iced favorites for warmer days';
      case 'Results':
        return 'Matching items from our menu';
      default:
        return 'Explore our carefully crafted menu';
    }
  }

  Widget _buildMenuItemCard(CoffeeProduct product) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _navigateToProduct(product),
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accentGold.withOpacity(0.12)),
              boxShadow: [
                BoxShadow(
                  color: primaryBrown.withOpacity(0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: ProductImage(
                          imageUrl: product.imageUrl,
                          width: 92,
                          height: 92,
                          fit: BoxFit.cover,
                          placeholderColor: primaryBrown.withOpacity(0.1),
                          iconColor: accentGold,
                          iconSize: 32,
                        ),
                      ),
                      if (product.isPopular)
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: const BoxDecoration(
                              color: primaryBrown,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(14),
                                bottomRight: Radius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Popular',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 92,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  product.name,
                                  style: TextStyle(
                                    color: textDark,
                                    fontSize: Responsive.of(context).sp(15),
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '\$${product.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: primaryBrown,
                                  fontSize: Responsive.of(context).sp(15),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Flexible(
                            child: Text(
                              product.description,
                              style: TextStyle(
                                color: textLight.withOpacity(0.95),
                                fontSize: 12,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: accentGold,
                                size: 15,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                product.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: textDark,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                Icons.schedule_rounded,
                                color: textLight.withOpacity(0.8),
                                size: 13,
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  product.preparationTime,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: textLight.withOpacity(0.9),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Material(
                                color: primaryBrown,
                                borderRadius: BorderRadius.circular(10),
                                child: InkWell(
                                  onTap: () {
                                    CartStore.instance.addProduct(product);
                                    HapticFeedback.mediumImpact();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${product.name} added to cart'),
                                        backgroundColor: primaryBrown,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        margin: const EdgeInsets.all(16),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: const SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: Icon(
                                      Icons.add_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}
