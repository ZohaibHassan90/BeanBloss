import 'dart:ui';

import 'package:beanbloss/models/coffee_product.dart';
import 'package:beanbloss/screens/HomeScreens/product_detail_screen.dart';
import 'package:beanbloss/services/product_service.dart';
import 'package:beanbloss/services/user_service.dart';
import 'package:beanbloss/state/cart_store.dart';
import 'package:beanbloss/utils/responsive.dart';
import 'package:beanbloss/widgets/app_bottom_nav.dart';
import 'package:beanbloss/widgets/app_buttons.dart';
import 'package:beanbloss/widgets/app_empty_state.dart';
import 'package:beanbloss/widgets/app_fab.dart';
import 'package:beanbloss/widgets/app_sheet.dart';
import 'package:beanbloss/widgets/product_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'notification_screen.dart';
import 'cart_screen.dart';
import 'favorites_screen.dart';
import 'offers_screen.dart';
import 'reorder_screen.dart';
import 'track_order_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _carouselProgressController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late PageController _pageController;

  int _currentCarouselIndex = 0;
  int _selectedCategoryIndex = 0;
  String _selectedSortOption = 'Popular';
  String _searchQuery = '';
  List<String> get _favoriteProducts => UserService.instance.favoriteProductIds;

  List<CoffeeProduct> get coffeeProducts => ProductService.instance.products;

  bool _isCarouselPaused = false;

  static const Duration _carouselAutoPlayDuration = Duration(seconds: 4);

  // Consistent color scheme
  static const Color primaryBg = Color(0xFFF5F1EB);
  static const Color cardBg = Color(0xFFFFFBF7);
  static const Color primaryBrown = Color(0xFF8B4513);
  static const Color accentGold = Color(0xFFD4A574);
  static const Color textDark = Color(0xFF2C1810);
  static const Color textLight = Color(0xFF8B7355);
  static const Color lightBrown = Color(0xFFA0522D);

  final TextEditingController _searchController = TextEditingController();

  final List<CarouselItem> carouselItems = [
    CarouselItem(
      title: 'Premium Arabica',
      subtitle: 'Fresh from the mountains',
      discount: '20% OFF',
      imageUrl: 'assets/images/on1.jpg',
      backgroundColor: primaryBrown,
      promoCode: 'ARABICA20',
    ),
    CarouselItem(
      title: 'Espresso Special',
      subtitle: 'Rich and bold flavor',
      discount: '15% OFF',
      imageUrl: 'assets/images/on2.jpg',
      backgroundColor: const Color(0xFF6B3A1F),
      promoCode: 'ESPRESSO15',
    ),
    CarouselItem(
      title: 'Cold Brew Collection',
      subtitle: 'Perfect for summer',
      discount: '25% OFF',
      imageUrl: 'assets/images/on3.jpg',
      backgroundColor: lightBrown,
      promoCode: 'COLDBREW25',
    ),
    CarouselItem(
      title: 'Weekend Special',
      subtitle: 'Buy 2 Get 1 Free',
      discount: 'BOGO',
      imageUrl: 'assets/images/on4.jpg',
      backgroundColor: primaryBrown,
      promoCode: 'WEEKEND',
    ),
  ];

  final List<Category> categories = [
    Category(name: 'All', icon: Icons.apps_rounded, isSelected: true),
    Category(name: 'Espresso', icon: Icons.local_cafe_rounded),
    Category(name: 'Latte', icon: Icons.coffee_rounded),
    Category(name: 'Cappuccino', icon: Icons.emoji_food_beverage_rounded),
    Category(name: 'Cold Brew', icon: Icons.ac_unit_rounded),
    Category(name: 'Frappé', icon: Icons.icecream_rounded),
  ];

  final List<String> sortOptions = [
    'Popular',
    'Price: Low to High',
    'Price: High to Low',
    'Rating',
    'Newest',
    // 'Name A-Z',
  ];

  // Catalog lives in Firestore via ProductService (seeded on first load).

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeCarousel();
    _setSystemUIStyle();
    ProductService.instance.addListener(_onProductsChanged);
    UserService.instance.addListener(_onProductsChanged);
    ProductService.instance.loadProducts();

    // Listen to search changes
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  void _onProductsChanged() {
    if (mounted) setState(() {});
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _carouselProgressController = AnimationController(
      duration: _carouselAutoPlayDuration,
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

  void _initializeCarousel() {
    _pageController = PageController(viewportFraction: 0.88);

    _carouselProgressController.addStatusListener((status) {
      if (status == AnimationStatus.completed &&
          !_isCarouselPaused &&
          !_isCarouselPageAnimating) {
        _goToNextCarouselPage();
      }
    });

    // Start after first frame so the active pill has real width (avoids
    // a half-filled first progress cycle).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startCarouselAutoPlay();
    });
  }

  void _startCarouselAutoPlay() {
    if (_isCarouselPaused || !mounted) return;
    _carouselProgressController.stop();
    _carouselProgressController.reset();
    _carouselProgressController.forward();
  }

  void _pauseCarouselAutoPlay() {
    _isCarouselPaused = true;
    _carouselProgressController.stop();
  }

  void _resumeCarouselAutoPlay() {
    if (!mounted) return;
    _isCarouselPaused = false;
    _startCarouselAutoPlay();
  }

  bool _isCarouselPageAnimating = false;

  void _goToNextCarouselPage() {
    if (!_pageController.hasClients || carouselItems.isEmpty) return;
    final nextPage = (_currentCarouselIndex + 1) % carouselItems.length;
    _isCarouselPageAnimating = true;
    _pageController
        .animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    )
        .whenComplete(() {
      _isCarouselPageAnimating = false;
    });
  }

  void _onCarouselPageChanged(int index) {
    if (_currentCarouselIndex == index) return;
    setState(() {
      _currentCarouselIndex = index;
    });
    if (!_isCarouselPaused) {
      _startCarouselAutoPlay();
    }
  }

  void _setSystemUIStyle() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: cardBg,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _carouselProgressController.dispose();
    _pageController.dispose();
    _searchController.dispose();
    ProductService.instance.removeListener(_onProductsChanged);
    UserService.instance.removeListener(_onProductsChanged);
    super.dispose();
  }

  List<CoffeeProduct> get filteredProducts {
    // ProductService exposes an unmodifiable list; clone before in-place sorts.
    List<CoffeeProduct> filtered = List<CoffeeProduct>.from(coffeeProducts);

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) =>
      product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.category.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Filter by category
    if (_selectedCategoryIndex > 0) {
      String selectedCategory = categories[_selectedCategoryIndex].name;
      filtered = filtered.where((product) => product.category == selectedCategory).toList();
    }

    // Sort products
    switch (_selectedSortOption) {
      case 'Price: Low to High':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price: High to Low':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Rating':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      // case 'Name A-Z':
      //   filtered.sort((a, b) => a.name.compareTo(b.name));
      //   break;
      case 'Popular':
        filtered.sort((a, b) => (b.isPopular ? 1 : 0).compareTo(a.isPopular ? 1 : 0));
        break;
    }

    return filtered;
  }

  Future<void> _toggleFavorite(String productId) async {
    HapticFeedback.lightImpact();
    try {
      final added = await UserService.instance.toggleFavorite(productId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            added ? 'Added to favorites!' : 'Removed from favorites!',
          ),
          backgroundColor: primaryBrown,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not update favorites'),
          backgroundColor: primaryBrown,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _addToCart(CoffeeProduct product) {
    CartStore.instance.addProduct(product);
    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text('${product.name} added to cart!'),
            ),
          ],
        ),
        backgroundColor: primaryBrown,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: accentGold,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartScreen()),
            );
          },
        ),
      ),
    );
  }

  void _usePromoCode(String promoCode) {
    HapticFeedback.mediumImpact();
    Clipboard.setData(ClipboardData(text: promoCode));
    final applied = CartStore.instance.applyPromo(promoCode);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.local_offer, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                applied
                    ? (CartStore.instance.items.isEmpty
                        ? 'Promo $promoCode saved for checkout'
                        : 'Promo $promoCode applied to cart')
                    : 'Invalid promo $promoCode',
              ),
            ),
          ],
        ),
        backgroundColor: accentGold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
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
      backgroundColor: const Color(0xFFF8F4EE),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Stack(
            children: [
              // Soft vertical wash like the reference, in brand tones
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: const [
                        Color(0xFFC9956B),
                        Color(0xFFD9B48C),
                        Color(0xFFEFE4D4),
                        Color(0xFFF8F4EE),
                      ],
                      stops: const [0.0, 0.22, 0.48, 0.78],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -40,
                left: -30,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),
              ),
              Positioned(
                top: 90,
                right: -50,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryBrown.withOpacity(0.08),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ((r.width - r.contentMaxWidth) / 2).clamp(0.0, 400.0),
                  ),
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      _buildAppBar(),
                      SliverToBoxAdapter(child: _buildSearchBar()),
                      SliverToBoxAdapter(child: _buildCarousel()),
                      const SliverToBoxAdapter(child: SizedBox(height: 8)),
                      SliverToBoxAdapter(child: _buildQuickActions()),
                      SliverToBoxAdapter(child: _buildFeaturedSection()),
                      SliverToBoxAdapter(child: _buildCategories()),
                      SliverToBoxAdapter(child: _buildSortingOptions()),
                      _buildProductGrid(),
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
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      floatingActionButton: const AppCartFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      extendBody: true,
    ),
    );
  }

  Widget _buildSectionHeader(String title, {String? actionLabel, VoidCallback? onAction}) {
    final r = Responsive.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.pagePadding),
      child: Row(
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
              title,
              style: const TextStyle(
                color: textDark,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
          if (actionLabel != null)
            AppLinkButton(
              label: actionLabel,
              onPressed: onAction ?? () {},
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    final r = Responsive.of(context);
    return SliverAppBar(
      pinned: true,
      floating: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 86,
      automaticallyImplyLeading: false,
      flexibleSpace: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(r.pagePadding, 8, r.pagePadding, 6),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFB8845A),
                  Color(0xFFC9956B),
                  Color(0xFFD4A574),
                  Color(0xFFE2C49A),
                ],
                stops: [0.0, 0.35, 0.7, 1.0],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.42),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B4513).withOpacity(0.22),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.35),
                  blurRadius: 0,
                  offset: const Offset(0, 1),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Soft top gloss
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.28),
                          Colors.white.withOpacity(0.05),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.4, 0.85],
                      ),
                    ),
                  ),
                  // Matching organic accents
                  Positioned(
                    top: -28,
                    right: -18,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.14),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -24,
                    left: 40,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryBrown.withOpacity(0.12),
                      ),
                    ),
                  ),
                  // Inner content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.white.withOpacity(0.22),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                          child: const Icon(
                            Icons.coffee_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _getGreeting(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.3,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              ListenableBuilder(
                                listenable: UserService.instance,
                                builder: (context, _) {
                                  return Text(
                                    _displayFirstName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.syne(
                                      color: Colors.white,
                                      fontSize: r.width < 360 ? 22 : 24,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.6,
                                      height: 1.05,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        _buildIconButton(
                          Icons.notifications_none_rounded,
                          () => openNotificationsPanel(context),
                          showBadge: true,
                        ),
                        const SizedBox(width: 8),
                        _buildIconButton(
                          _favoriteProducts.isEmpty
                              ? Icons.favorite_border_rounded
                              : Icons.favorite_rounded,
                          _openFavorites,
                        ),
                      ],
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// Prefer Firestore profile; fall back to Auth display name / email.
  String get _displayFirstName {
    final fromProfile = UserService.instance.cached?.firstName;
    if (fromProfile != null && fromProfile.isNotEmpty) return fromProfile;

    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName.split(RegExp(r'\s+')).first;
    }
    final email = user?.email?.trim();
    if (email != null && email.contains('@')) {
      final local = email.split('@').first.trim();
      if (local.isNotEmpty) {
        return local[0].toUpperCase() + local.substring(1);
      }
    }
    return 'Guest';
  }

  Widget _buildIconButton(
    IconData icon,
    VoidCallback onTap, {
    bool showBadge = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: Colors.white.withOpacity(0.22),
          child: InkWell(
            onTap: onTap,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.4)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  if (showBadge)
                    Positioned(
                      top: 9,
                      right: 10,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE0B2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
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

  Widget _buildSearchBar() {
    final r = Responsive.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(r.pagePadding, 10, r.pagePadding, 6),
      child: AppSearchField(controller: _searchController),
    );
  }

  Widget _buildCarousel() {
    final r = Responsive.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 6),
      child: Column(
        children: [
          SizedBox(
            height: r.carouselHeight,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollStartNotification &&
                    notification.dragDetails != null) {
                  _pauseCarouselAutoPlay();
                } else if (notification is ScrollEndNotification &&
                    _isCarouselPaused) {
                  Future.delayed(const Duration(milliseconds: 600), () {
                    if (mounted && _isCarouselPaused) {
                      _resumeCarouselAutoPlay();
                    }
                  });
                }
                return false;
              },
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onCarouselPageChanged,
                itemCount: carouselItems.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return _buildCarouselItem(carouselItems[index], index);
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildCarouselIndicators(),
        ],
      ),
    );
  }

  Widget _buildCarouselIndicators() {
    const double activeWidth = 28;
    const double inactiveWidth = 8;
    const double dotHeight = 8;

    return AnimatedBuilder(
      animation: _carouselProgressController,
      builder: (context, _) {
        final progress = _carouselProgressController.value.clamp(0.0, 1.0);

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(carouselItems.length, (index) {
            final isActive = _currentCarouselIndex == index;

            return GestureDetector(
              onTap: () {
                if (index == _currentCarouselIndex) return;
                _pauseCarouselAutoPlay();
                _isCarouselPageAnimating = true;
                _pageController
                    .animateToPage(
                  index,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                )
                    .whenComplete(() {
                  _isCarouselPageAnimating = false;
                  if (mounted) _resumeCarouselAutoPlay();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: isActive ? activeWidth : inactiveWidth,
                height: dotHeight,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(dotHeight / 2),
                  color: isActive
                      ? primaryBrown.withOpacity(0.22)
                      : textLight.withOpacity(0.25),
                ),
                // Use a fixed active width for fill — FractionallySizedBox
                // against an animating AnimatedContainer caused the first
                // cycle to render as a half-filled pill.
                child: isActive
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: activeWidth * progress,
                          height: dotHeight,
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(dotHeight / 2),
                            color: primaryBrown,
                          ),
                        ),
                      )
                    : null,
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildCarouselItem(CarouselItem item, int index) {
    return GestureDetector(
      onTap: () => _usePromoCode(item.promoCode),
      child: AnimatedBuilder(
        animation: _pageController,
        builder: (context, child) {
          double scale = 1.0;
          double opacity = 1.0;
          if (_pageController.position.haveDimensions) {
            final page = _pageController.page ?? _currentCarouselIndex.toDouble();
            final distance = (page - index).abs();
            scale = (1 - (distance * 0.12)).clamp(0.88, 1.0);
            opacity = (1 - (distance * 0.35)).clamp(0.65, 1.0);
          }

          return Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: child,
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: item.backgroundColor.withOpacity(0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
                spreadRadius: -2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  item.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: item.backgroundColor,
                    child: Icon(
                      Icons.local_cafe_rounded,
                      color: Colors.white.withOpacity(0.7),
                      size: 56,
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        item.backgroundColor.withOpacity(0.92),
                        item.backgroundColor.withOpacity(0.55),
                        item.backgroundColor.withOpacity(0.15),
                      ],
                      stops: const [0.0, 0.45, 1.0],
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
                        Colors.black.withOpacity(0.35),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                          ),
                        ),
                        child: Text(
                          item.discount,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            child: InkWell(
                              onTap: () => _usePromoCode(item.promoCode),
                              borderRadius: BorderRadius.circular(18),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 9,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.local_offer_rounded,
                                      color: item.backgroundColor,
                                      size: 15,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Claim Offer',
                                      style: TextStyle(
                                        color: item.backgroundColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            item.promoCode,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
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

  Widget _buildQuickActions() {
    final actions = [
      _QuickActionData('Reorder', Icons.refresh_rounded, primaryBrown, () {
        _openQuickScreen(const ReorderScreen());
      }),
      _QuickActionData('Track', Icons.near_me_rounded, lightBrown, () {
        _openQuickScreen(const TrackOrderScreen());
      }),
      _QuickActionData('Favorites', Icons.favorite_rounded, const Color(0xFF9C5A3C), () {
        _openFavorites();
      }),
      _QuickActionData('Offers', Icons.local_offer_rounded, accentGold, () {
        _openQuickScreen(const OffersScreen());
      }),
    ];

    final r = Responsive.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(r.pagePadding, 4, r.pagePadding, 8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: r.isPhone ? 6 : 12, vertical: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accentGold.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: primaryBrown.withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            for (int i = 0; i < actions.length; i++) ...[
              if (i > 0)
                Container(
                  width: 1,
                  height: 36,
                  color: accentGold.withOpacity(0.15),
                ),
              Expanded(
                child: _buildQuickActionCard(
                  actions[i].title,
                  actions[i].icon,
                  actions[i].color,
                  actions[i].onTap,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedSection() {
    final r = Responsive.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Featured Offer',
            actionLabel: 'See All',
            onAction: () => _openQuickScreen(const OffersScreen()),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: r.pagePadding),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _usePromoCode('BOGOESP'),
                borderRadius: BorderRadius.circular(22),
                child: Ink(
                  height: r.featuredHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFC9956B),
                        accentGold,
                        Color(0xFFE8C9A0),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentGold.withOpacity(0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.12),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 30,
                        bottom: -30,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryBrown.withOpacity(0.12),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(r.width < 360 ? 12 : 16),
                        child: Row(
                          children: [
                            if (r.width >= 340)
                              Container(
                              width: r.width < 400 ? 64 : 78,
                              height: r.width < 400 ? 72 : 86,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                image: const DecorationImage(
                                  image: AssetImage('assets/images/on1.jpg'),
                                  fit: BoxFit.cover,
                                ),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.35),
                                  width: 2,
                                ),
                              ),
                            ),
                            if (r.width >= 340)
                              SizedBox(width: r.width < 400 ? 10 : 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primaryBrown.withOpacity(0.85),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'EVERY TUESDAY',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Buy 1 Get 1 Free',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: r.sp(16),
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'On all Espresso drinks today',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.92),
                                      fontSize: r.sp(12),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (r.width >= 380)
                              Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: primaryBrown,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    final r = Responsive.of(context);
    final tile = r.categoryTileSize;
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Categories'),
          const SizedBox(height: 14),
          SizedBox(
            height: tile + 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: r.pagePadding - 4),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = _selectedCategoryIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategoryIndex = index;
                      for (final cat in categories) {
                        cat.isSelected = false;
                      }
                      categories[index].isSelected = true;
                    });
                    HapticFeedback.selectionClick();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    width: tile + 14,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          width: tile,
                          height: tile,
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [primaryBrown, lightBrown],
                                  )
                                : null,
                            color: isSelected ? null : cardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : accentGold.withOpacity(0.22),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? primaryBrown.withOpacity(0.28)
                                    : primaryBrown.withOpacity(0.04),
                                blurRadius: isSelected ? 14 : 8,
                                offset: Offset(0, isSelected ? 6 : 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            category.icon,
                            color: isSelected ? Colors.white : textLight,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected ? textDark : textLight,
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortingOptions() {
    final r = Responsive.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(r.pagePadding, 12, r.pagePadding, 4),
      child: Row(
        children: [
          Expanded(
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
                    Flexible(
                      child: Text(
                        _searchQuery.isNotEmpty ? 'Search Results' : 'Popular Items',
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_searchQuery.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: Text(
                      '${filteredProducts.length} items found',
                      style: const TextStyle(
                        color: textLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Material(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: _showSortBottomSheet,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accentGold.withOpacity(0.28)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sort_rounded, color: accentGold, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      _selectedSortOption == 'Popular'
                          ? 'Popular'
                          : _selectedSortOption.contains('Low')
                              ? 'Price'
                              : _selectedSortOption,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: textLight.withOpacity(0.8),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    if (ProductService.instance.isLoading && coffeeProducts.isEmpty) {
      return const SliverToBoxAdapter(
        child: SizedBox(
          height: 220,
          child: Center(
            child: CircularProgressIndicator(
              color: accentGold,
              strokeWidth: 2.5,
            ),
          ),
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
            title: 'No products found',
            subtitle: 'Try a different search or category',
            actionLabel: 'Clear search',
            onAction: () => _searchController.clear(),
          ),
        ),
      );
    }

    final r = Responsive.of(context);
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(r.pagePadding, 10, r.pagePadding, 10),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: r.productColumns,
          childAspectRatio: r.productAspectRatio,
          crossAxisSpacing: r.gridSpacing,
          mainAxisSpacing: r.gridSpacing,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildProductCard(products[index]),
          childCount: products.length,
        ),
      ),
    );
  }

  Widget _buildProductCard(CoffeeProduct product) {
    final isFavorite = _favoriteProducts.contains(product.id);

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  ProductDetailScreen(product: product),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                    .chain(CurveTween(curve: Curves.easeInOut));
                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        },
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: accentGold.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                color: primaryBrown.withOpacity(0.07),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                      child: ProductImage(
                        imageUrl: product.imageUrl,
                        fit: BoxFit.cover,
                        placeholderColor: primaryBrown.withOpacity(0.12),
                        iconColor: accentGold,
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.18),
                          ],
                        ),
                      ),
                    ),
                    if (product.isPopular)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryBrown,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Popular',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Material(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: () => _toggleFavorite(product.id),
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isFavorite ? const Color(0xFFC45C4A) : accentGold,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 140;
                    return Padding(
                      padding: EdgeInsets.fromLTRB(narrow ? 8 : 12, 8, narrow ? 8 : 12, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: accentGold, size: 15),
                              const SizedBox(width: 3),
                              Text(
                                product.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: textDark,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              Flexible(
                                child: Text(
                                  product.preparationTime,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    color: textLight.withOpacity(0.9),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.name,
                            style: TextStyle(
                              color: textDark,
                              fontSize: Responsive.of(context).sp(14),
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Flexible(
                            child: Text(
                              product.description,
                              style: TextStyle(
                                color: textLight.withOpacity(0.95),
                                fontSize: 11,
                                height: 1.25,
                              ),
                              maxLines: narrow ? 1 : 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '\$${product.price.toStringAsFixed(2)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: primaryBrown,
                                    fontSize: Responsive.of(context).sp(15),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Material(
                                color: primaryBrown,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  onTap: () => _addToCart(product),
                                  borderRadius: BorderRadius.circular(12),
                                  child: const SizedBox(
                                    width: 32,
                                    height: 32,
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
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSortBottomSheet() {
    showAppSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Sort by',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  AppIconButton(
                    icon: Icons.close_rounded,
                    size: 36,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...sortOptions.map((option) {
                final isSelected = _selectedSortOption == option;
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  title: Text(
                    option,
                    style: TextStyle(
                      color: isSelected ? primaryBrown : textDark,
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryBrown.withOpacity(0.1)
                          : accentGold.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getSortIcon(option),
                      color: isSelected ? primaryBrown : textLight,
                      size: 20,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_rounded, color: primaryBrown)
                      : null,
                  onTap: () {
                    setState(() => _selectedSortOption = option);
                    Navigator.pop(context);
                    HapticFeedback.selectionClick();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _openQuickScreen(Widget page) {
    HapticFeedback.selectionClick();
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _openFavorites() {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FavoritesScreen(
          allProducts: coffeeProducts,
          favoriteIds: _favoriteProducts,
          onRemoveFavorite: (id) {
            UserService.instance.removeFavorite(id);
          },
          onAddToCart: (product) {
            CartStore.instance.addProduct(product);
          },
        ),
      ),
    );
  }

  IconData _getSortIcon(String option) {
    switch (option) {
      case 'Popular':
        return Icons.trending_up_rounded;
      case 'Price: Low to High':
        return Icons.arrow_upward_rounded;
      case 'Price: High to Low':
        return Icons.arrow_downward_rounded;
      case 'Rating':
        return Icons.star_rounded;
      case 'Newest':
        return Icons.new_releases_rounded;
      // case 'Name A-Z':
      //   return Icons.sort_by_alpha_rounded;
      default:
        return Icons.sort_rounded;
    }
  }
}

// Enhanced Data Models
class _QuickActionData {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionData(this.title, this.icon, this.color, this.onTap);
}




class CarouselItem {
  final String title;
  final String subtitle;
  final String discount;
  final String imageUrl;
  final Color backgroundColor;
  final String promoCode;

  CarouselItem({
    required this.title,
    required this.subtitle,
    required this.discount,
    required this.imageUrl,
    required this.backgroundColor,
    required this.promoCode,
  });
}

class Category {
  final String name;
  final IconData icon;
  bool isSelected;

  Category({
    required this.name,
    required this.icon,
    this.isSelected = false,
  });
}
