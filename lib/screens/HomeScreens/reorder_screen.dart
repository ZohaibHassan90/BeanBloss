import 'package:beanbloss/models/app_order.dart';
import 'package:beanbloss/screens/HomeScreens/cart_screen.dart';
import 'package:beanbloss/screens/HomeScreens/menu_screen.dart';
import 'package:beanbloss/services/order_service.dart';
import 'package:beanbloss/theme/app_colors.dart';
import 'package:beanbloss/utils/responsive.dart';
import 'package:beanbloss/widgets/app_detail_bar.dart';
import 'package:beanbloss/widgets/app_empty_state.dart';
import 'package:beanbloss/widgets/product_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class _OrderItem {
  const _OrderItem({
    required this.name,
    required this.detail,
    required this.imageUrl,
  });

  final String name;
  final String detail;
  final String imageUrl;
}

class _PastOrder {
  const _PastOrder({
    required this.id,
    required this.when,
    required this.items,
    required this.total,
    this.isUsual = false,
    this.lines,
  });

  final String id;
  final String when;
  final List<_OrderItem> items;
  final double total;
  final bool isUsual;
  final List<OrderLineItem>? lines;
}

class ReorderScreen extends StatefulWidget {
  const ReorderScreen({super.key});

  @override
  State<ReorderScreen> createState() => _ReorderScreenState();
}

class _ReorderScreenState extends State<ReorderScreen> {
  List<_PastOrder> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final orders = await OrderService.instance.loadRecentOrders();
      _orders = [
        for (var i = 0; i < orders.length; i++)
          _PastOrder(
            id: orders[i].orderNumber,
            when: orders[i].whenLabel,
            total: orders[i].total,
            isUsual: i == 0,
            items: [
              for (final line in orders[i].items)
                _OrderItem(
                  name: line.name,
                  detail: line.detailLabel,
                  imageUrl: line.imageUrl,
                ),
            ],
            lines: orders[i].items,
          ),
      ];
    } catch (_) {
      _orders = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _reorder(BuildContext context, _PastOrder order) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartScreen(
          reorderOrderId: order.id,
          reorderLines: order.lines,
          reorderItems: order.lines == null || order.lines!.isEmpty
              ? order.items.map((e) => e.name).toList()
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final last = _orders.isNotEmpty ? _orders.first : null;
    final older = _orders.length > 1 ? _orders.sublist(1) : const <_PastOrder>[];

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      body: SafeArea(
        child: Column(
          children: [
            AppDetailBar(
              title: 'Reorder',
              subtitle: _orders.isEmpty
                  ? null
                  : '${_orders.length} recent orders',
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentGold,
                        strokeWidth: 2.5,
                      ),
                    )
                  : _orders.isEmpty
                  ? AppEmptyState(
                      icon: Icons.refresh_rounded,
                      title: 'Nothing to reorder',
                      subtitle:
                          'Place an order at BeanBloss and it will show up here.',
                      actionLabel: 'Browse menu',
                      onAction: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MenuCardScreen(),
                          ),
                        );
                      },
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
                        if (last != null) ...[
                          _LastOrderHero(
                            order: last,
                            onReorder: () => _reorder(context, last),
                          ),
                          const SizedBox(height: 24),
                        ],
                        if (older.isNotEmpty) ...[
                          Text(
                            'EARLIER ORDERS',
                            style: TextStyle(
                              color: AppColors.textLight.withOpacity(0.9),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...older.map(
                            (order) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ReorderCard(
                                order: order,
                                onReorder: () => _reorder(context, order),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LastOrderHero extends StatelessWidget {
  const _LastOrderHero({
    required this.order,
    required this.onReorder,
  });

  final _PastOrder order;
  final VoidCallback onReorder;

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
              top: -36,
              right: -18,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -20,
              child: Container(
                width: 110,
                height: 110,
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
                        'LAST ORDER',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const Spacer(),
                      if (order.isUsual)
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
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Your usual',
                                style: TextStyle(
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
                  Row(
                    children: [
                      _StackedThumbs(
                        images: order.items.map((e) => e.imageUrl).toList(),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.items.map((e) => e.name).join(' + '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${order.when} · \$${order.total.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onReorder,
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
                          Icon(Icons.refresh_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Order again',
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

class _StackedThumbs extends StatelessWidget {
  const _StackedThumbs({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    final show = images.take(2).toList();
    final width = show.length == 1 ? 64.0 : 88.0;

    return SizedBox(
      width: width,
      height: 64,
      child: Stack(
        children: [
          for (var i = 0; i < show.length; i++)
            Positioned(
              left: i * 24.0,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.45), width: 2),
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
                    iconSize: 22,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReorderCard extends StatelessWidget {
  const _ReorderCard({required this.order, required this.onReorder});

  final _PastOrder order;
  final VoidCallback onReorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border()),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Text(
                  order.id,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textLight.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.when,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                Text(
                  '\$${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.primaryBrown,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border(0.14)),
          for (var i = 0; i < order.items.length; i++) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ProductImage(
                      imageUrl: order.items[i].imageUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      placeholderColor: AppColors.softFill(),
                      iconColor: AppColors.primaryBrown,
                      iconSize: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.items[i].name,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.items[i].detail,
                          style: const TextStyle(
                            color: AppColors.textLight,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (i < order.items.length - 1)
              Divider(
                height: 1,
                indent: 74,
                endIndent: 14,
                color: AppColors.border(0.12),
              ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onReorder,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBrown,
                  side: BorderSide(color: AppColors.border(0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh_rounded, size: 17),
                    SizedBox(width: 7),
                    Text(
                      'Reorder',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
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
}
