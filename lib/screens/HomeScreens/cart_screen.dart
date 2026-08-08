import 'package:beanbloss/models/app_order.dart';
import 'package:beanbloss/screens/HomeScreens/track_order_screen.dart';
import 'package:beanbloss/state/cart_store.dart';
import 'package:beanbloss/theme/app_colors.dart';
import 'package:beanbloss/utils/responsive.dart';
import 'package:beanbloss/widgets/app_buttons.dart';
import 'package:beanbloss/widgets/app_detail_bar.dart';
import 'package:beanbloss/widgets/app_empty_state.dart';
import 'package:beanbloss/widgets/app_sheet.dart';
import 'package:beanbloss/widgets/product_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({
    super.key,
    this.reorderOrderId,
    this.reorderItems,
    this.reorderLines,
  });

  /// When set, cart is filled from a past order (Reorder flow).
  final String? reorderOrderId;
  final List<String>? reorderItems;
  final List<OrderLineItem>? reorderLines;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _promoController = TextEditingController();
  String? _reorderBanner;

  @override
  void initState() {
    super.initState();
    final lines = widget.reorderLines;
    final names = widget.reorderItems;
    if (lines != null && lines.isNotEmpty) {
      _reorderBanner = widget.reorderOrderId == null
          ? 'Items added from your past order'
          : 'Reordered from ${widget.reorderOrderId}';
      CartStore.instance.clear();
      CartStore.instance.addFromOrderLines(
        lines,
        fromOrderId: widget.reorderOrderId,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${lines.length} item${lines.length == 1 ? '' : 's'} added to cart',
            ),
            backgroundColor: AppColors.primaryBrown,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      });
    } else if (names != null && names.isNotEmpty) {
      _reorderBanner = widget.reorderOrderId == null
          ? 'Items added from your past order'
          : 'Reordered from ${widget.reorderOrderId}';
      CartStore.instance.clear();
      CartStore.instance.addNamedItems(
        names,
        fromOrderId: widget.reorderOrderId,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${names.length} item${names.length == 1 ? '' : 's'} added to cart',
            ),
            backgroundColor: AppColors.primaryBrown,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      });
    }

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _updateQuantity(int index, int quantity) {
    CartStore.instance.setQuantity(index, quantity);
    HapticFeedback.selectionClick();
  }

  void _removeItem(int index) {
    CartStore.instance.removeAt(index);
    HapticFeedback.mediumImpact();
  }

  void _applyPromo() {
    final ok = CartStore.instance.applyPromo(_promoController.text);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invalid promo code'),
          backgroundColor: AppColors.primaryBrown,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    final code = CartStore.instance.appliedPromo;
    if (code != null) _promoController.text = code;
    HapticFeedback.mediumImpact();
  }

  void _checkout() {
    final cart = CartStore.instance;
    if (cart.items.isEmpty) return;
    HapticFeedback.mediumImpact();
    showAppSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.softFill(),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: AppColors.primaryBrown,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Confirm pickup',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${cart.itemCount} items · \$${cart.total.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.softFill(0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.payments_outlined,
                    color: AppColors.primaryBrown,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pay at pickup · Pay when you collect your order',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            AppPrimaryButton(
              label: 'Place order · Pay at pickup',
              onPressed: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await CartStore.instance.placeOrder();
                  if (!context.mounted) return;
                  navigator.pop();
                  navigator.pushReplacement(
                    MaterialPageRoute(
                      builder: (_) =>
                          const TrackOrderScreen(hasActiveOrder: true),
                    ),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        e is StateError
                            ? e.message
                            : 'Could not place order. Try again.',
                      ),
                      backgroundColor: AppColors.primaryBrown,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 4),
            AppLinkButton(
              label: 'Cancel',
              secondary: true,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);

    return ListenableBuilder(
      listenable: CartStore.instance,
      builder: (context, _) {
        final cart = CartStore.instance;
        final items = cart.items;
        final itemCount = cart.itemCount;
        final promoApplied = cart.appliedPromo != null;

        return Scaffold(
          backgroundColor: AppColors.primaryBg,
          body: SafeArea(
            child: Column(
              children: [
                AppDetailBar(
                  title: 'Cart',
                  subtitle: items.isEmpty
                      ? 'Your bag is waiting'
                      : '$itemCount item${itemCount == 1 ? '' : 's'} · Pickup',
                  action: items.isEmpty
                      ? null
                      : AppLinkButton(
                          label: 'Clear',
                          secondary: true,
                          onPressed: () {
                            CartStore.instance.clear();
                            _promoController.clear();
                            HapticFeedback.mediumImpact();
                          },
                        ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? AppEmptyState(
                          icon: Icons.shopping_bag_outlined,
                          title: 'Your cart is empty',
                          subtitle: 'Add something delicious from the menu.',
                          actionLabel: 'Browse Menu',
                          onAction: () => Navigator.pop(context),
                        )
                      : ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            r.pagePadding,
                            4,
                            r.pagePadding,
                            20,
                          ),
                          children: [
                            if (_reorderBanner != null) ...[
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.softFill(0.22),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.border(0.28),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.refresh_rounded,
                                      size: 18,
                                      color: AppColors.primaryBrown,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _reorderBanner!,
                                        style: const TextStyle(
                                          color: AppColors.primaryBrown,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            _buildItemsCard(items, itemCount),
                            const SizedBox(height: 14),
                            _buildPromoRow(promoApplied),
                            const SizedBox(height: 14),
                            _buildSummaryCard(cart, promoApplied),
                          ],
                        ),
                ),
                if (items.isNotEmpty) _buildCheckoutBar(cart.total),
              ],
            ),
          ),
        );
      },
    );
  }

  /// One unified card for all cart items.
  Widget _buildItemsCard(List<CartLine> items, int itemCount) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.border()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.softFill(),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.storefront_outlined,
                    color: AppColors.primaryBrown,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pickup order',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Collect at BeanBloss counter',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$itemCount item${itemCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: AppColors.primaryBrown,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border(0.14)),
          ...List.generate(items.length, (i) {
            return Column(
              children: [
                _buildLineItem(items[i], i),
                if (i < items.length - 1)
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: AppColors.border(0.14),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLineItem(CartLine item, int index) {
    final options = [
      if (item.size != null) item.size!,
      if (item.milkType != null) item.milkType!,
      if (item.temperature != null) item.temperature!,
      if (item.extraShots != null && item.extraShots! > 0)
        '+${item.extraShots} shot',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ProductImage(
              imageUrl: item.product.imageUrl,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              placeholderColor: AppColors.softFill(),
              iconColor: AppColors.accentGold,
              iconSize: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _removeItem(index),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: AppColors.textLight.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                if (options.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    options,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      '\$${item.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.primaryBrown,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    _QtyControl(
                      quantity: item.quantity,
                      onChanged: (q) => _updateQuantity(index, q),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoRow(bool promoApplied) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border()),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_offer_outlined,
            color: promoApplied
                ? AppColors.primaryBrown
                : AppColors.accentGold,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _promoController,
              enabled: !promoApplied,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              cursorColor: AppColors.primaryBrown,
              decoration: InputDecoration(
                hintText: promoApplied ? 'Promo applied' : 'Promo code',
                hintStyle: TextStyle(
                  color: AppColors.textLight.withOpacity(0.7),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          AppLinkButton(
            label: promoApplied ? 'Remove' : 'Apply',
            onPressed: promoApplied
                ? () {
                    CartStore.instance.clearPromo();
                    _promoController.clear();
                  }
                : _applyPromo,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(CartStore cart, bool promoApplied) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.border()),
      ),
      child: Column(
        children: [
          _summaryRow('Subtotal', cart.subtotal),
          const SizedBox(height: 10),
          _summaryRow('Tax', cart.tax),
          if (promoApplied) ...[
            const SizedBox(height: 10),
            _summaryRow('Discount', -cart.promoDiscount, emphasize: true),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.border(0.2)),
          ),
          Row(
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '\$${cart.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.primaryBrown,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double amount, {bool emphasize = false}) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: emphasize ? AppColors.primaryBrown : AppColors.textLight,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          '${amount < 0 ? '-' : ''}\$${amount.abs().toStringAsFixed(2)}',
          style: TextStyle(
            color: emphasize ? AppColors.primaryBrown : AppColors.textDark,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutBar(double total) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        14 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border(0.18))),
        boxShadow: AppShadows.nav,
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  color: AppColors.textLight.withOpacity(0.95),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AppPrimaryButton(
              label: 'Place Pickup Order',
              onPressed: _checkout,
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyControl extends StatelessWidget {
  const _QtyControl({required this.quantity, required this.onChanged});

  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.softFill(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(Icons.remove_rounded, () => onChanged(quantity - 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$quantity',
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _btn(Icons.add_rounded, () => onChanged(quantity + 1)),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 28,
        height: 28,
        child: Icon(icon, size: 15, color: AppColors.primaryBrown),
      ),
    );
  }
}
