import 'package:beanbloss/services/user_service.dart';
import 'package:beanbloss/state/cart_store.dart';
import 'package:beanbloss/theme/app_colors.dart';
import 'package:beanbloss/widgets/app_buttons.dart';
import 'package:beanbloss/widgets/app_page_header.dart';
import 'package:beanbloss/widgets/app_sheet.dart';
import 'package:beanbloss/widgets/product_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProductDetailScreen extends StatefulWidget {
  final CoffeeProduct product;

  const ProductDetailScreen({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _heartController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _heartAnimation;

  int _quantity = 1;
  String _selectedSize = 'Medium';
  String _selectedMilk = 'Whole Milk';
  String _selectedSweetness = 'Regular';
  bool _isFavorite = false;
  bool _isAddingToCart = false;

  final List<String> sizes = ['Small', 'Medium', 'Large'];
  final List<String> milkOptions = [
    'Whole Milk',
    'Almond Milk',
    'Oat Milk',
    'Soy Milk',
    'Coconut Milk',
  ];
  final List<String> sweetnessLevels = [
    'No Sugar',
    'Light',
    'Regular',
    'Extra Sweet',
  ];

  final Map<String, double> sizePrices = {
    'Small': -0.50,
    'Medium': 0.00,
    'Large': 0.75,
  };

  @override
  void initState() {
    super.initState();
    _isFavorite = UserService.instance.isFavorite(widget.product.id);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _heartController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _heartAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.elasticOut),
    );

    _animationController.forward();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _heartController.dispose();
    super.dispose();
  }

  double get totalPrice {
    double basePrice = widget.product.price;
    double sizeAdjustment = sizePrices[_selectedSize] ?? 0.0;
    return (basePrice + sizeAdjustment) * _quantity;
  }

  Future<void> _toggleFavorite() async {
    HapticFeedback.lightImpact();
    try {
      final added =
          await UserService.instance.toggleFavorite(widget.product.id);
      if (!mounted) return;
      setState(() => _isFavorite = added);
      if (added) {
        _heartController.forward().then((_) {
          _heartController.reverse();
        });
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not update favorites'),
          backgroundColor: AppColors.primaryBrown,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _addToCart() async {
    setState(() {
      _isAddingToCart = true;
    });

    CartStore.instance.addProduct(
      widget.product,
      quantity: _quantity,
      size: _selectedSize,
      milkType: _selectedMilk,
    );

    await Future.delayed(const Duration(milliseconds: 400));

    if (mounted) {
      setState(() {
        _isAddingToCart = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('${widget.product.name} added to cart!'),
              ),
            ],
          ),
          backgroundColor: AppColors.primaryBrown,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );

      HapticFeedback.mediumImpact();
    }
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        border: Border.all(color: AppColors.border(0.2)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    _buildProductImage(),
                    _buildProductInfo(),
                    _buildCustomizationOptions(),
                    _buildQuantitySelector(),
                    _buildNutritionalInfo(),
                    _buildReviews(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildAppBar() {
    return AppSliverHeader(
      title: widget.product.name,
      subtitle: widget.product.category,
      icon: Icons.coffee_rounded,
      trailing: ScaleTransition(
        scale: _heartAnimation,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              _toggleFavorite();
            },
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: AppColors.border(0.28)),
              ),
              child: Icon(
                _isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 17,
                color: _isFavorite
                    ? AppColors.destructive
                    : AppColors.textDark,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    return Container(
      height: 300,
      margin: const EdgeInsets.all(20),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.xxl),
                border: Border.all(color: AppColors.border(0.22)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.xxl),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.accentGold.withOpacity(0.1),
                        AppColors.primaryBrown.withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: ProductImage(
                    imageUrl: widget.product.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholderColor: AppColors.primaryBrown.withOpacity(0.1),
                    iconColor: AppColors.accentGold,
                    iconSize: 48,
                  ),
                ),
              ),
            ),
            ...List.generate(15, (index) => _buildCoffeeBean(index)),
            if (widget.product.isPopular)
              Positioned(
                top: 20,
                left: 20,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBrown,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Popular',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoffeeBean(int index) {
    final random = (index * 37) % 100;
    final left = (random % 80) + 10.0;
    final top = (random % 60) + 20.0;
    final size = 4.0 + (random % 3);

    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.primaryBrown.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.product.name,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.softFill(),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(color: AppColors.border(0.22)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.accentGold,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.product.rating.toString(),
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.product.category,
            style: const TextStyle(
              color: AppColors.accentGold,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.product.description,
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                color: AppColors.textLight,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                '5-7 min preparation',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 14,
                ),
              ),
              SizedBox(width: 20),
              Icon(
                Icons.local_fire_department_rounded,
                color: AppColors.accentGold,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Hot',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomizationOptions() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customize Your Order',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildOptionSection(
            'Size',
            sizes,
            _selectedSize,
            (value) => setState(() => _selectedSize = value),
            showPrice: true,
          ),
          const SizedBox(height: 20),
          _buildOptionSection(
            'Milk Type',
            milkOptions,
            _selectedMilk,
            (value) => setState(() => _selectedMilk = value),
          ),
          const SizedBox(height: 20),
          _buildOptionSection(
            'Sweetness',
            sweetnessLevels,
            _selectedSweetness,
            (value) => setState(() => _selectedSweetness = value),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionSection(
    String title,
    List<String> options,
    String selectedOption,
    Function(String) onChanged, {
    bool showPrice = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedOption == option;
            final priceAdjustment =
                showPrice ? sizePrices[option] ?? 0.0 : 0.0;
            final label = showPrice && priceAdjustment != 0
                ? '$option ${priceAdjustment > 0 ? '+' : ''}\$${priceAdjustment.toStringAsFixed(2)}'
                : option;

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(option);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryBrown
                      : AppColors.softFill(),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryBrown
                        : AppColors.border(0.22),
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.border(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Quantity',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              _buildQuantityButton(
                Icons.remove_rounded,
                () {
                  if (_quantity > 1) {
                    setState(() => _quantity--);
                    HapticFeedback.lightImpact();
                  }
                },
                _quantity > 1,
              ),
              Container(
                width: 50,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.softFill(),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(color: AppColors.border(0.18)),
                ),
                child: Center(
                  child: Text(
                    _quantity.toString(),
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              _buildQuantityButton(
                Icons.add_rounded,
                () {
                  if (_quantity < 10) {
                    setState(() => _quantity++);
                    HapticFeedback.lightImpact();
                  }
                },
                _quantity < 10,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback onTap, bool enabled) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primaryBrown
              : AppColors.textLight.withOpacity(0.2),
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(
            color: enabled
                ? AppColors.primaryBrown
                : AppColors.border(0.18),
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : AppColors.textLight,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildNutritionalInfo() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.border(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nutritional Information',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNutritionItem('Calories', '180'),
              _buildNutritionItem('Caffeine', '95mg'),
              _buildNutritionItem('Sugar', '12g'),
              _buildNutritionItem('Fat', '8g'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.primaryBrown,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textLight,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildReviews() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.border(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Reviews',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppLinkButton(
                label: 'See All',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  showAppSheet(
                    context: context,
                    builder: (ctx) => Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'All reviews',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildReviewItem(
                            'Sarah M.',
                            'Perfect balance of espresso and milk. Love the smooth texture!',
                            5,
                          ),
                          const SizedBox(height: 10),
                          _buildReviewItem(
                            'Mike R.',
                            'Great coffee, exactly what I needed for my morning routine.',
                            4,
                          ),
                          const SizedBox(height: 10),
                          _buildReviewItem(
                            'Ayesha K.',
                            'Consistent quality every time I order ahead for pickup.',
                            5,
                          ),
                          const SizedBox(height: 10),
                          _buildReviewItem(
                            'Daniel P.',
                            'Slightly sweet for me, but still excellent.',
                            4,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildReviewItem(
            'Sarah M.',
            'Perfect balance of espresso and milk. Love the smooth texture!',
            5,
          ),
          const SizedBox(height: 12),
          _buildReviewItem(
            'Mike R.',
            'Great coffee, exactly what I needed for my morning routine.',
            4,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String name, String review, int rating) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: AppColors.border(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: AppColors.accentGold,
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review,
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadii.xxl),
          topRight: Radius.circular(AppRadii.xxl),
        ),
        border: Border(
          top: BorderSide(color: AppColors.border(0.22)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Price',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.primaryBrown,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isAddingToCart ? null : _addToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBrown,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                  ),
                  child: _isAddingToCart
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_bag_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Add to Cart',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
