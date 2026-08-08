import 'dart:math' as math;

import 'package:beanbloss/models/app_order.dart';
import 'package:beanbloss/screens/HomeScreens/menu_screen.dart';
import 'package:beanbloss/services/order_service.dart';
import 'package:beanbloss/theme/app_colors.dart';
import 'package:beanbloss/utils/responsive.dart';
import 'package:beanbloss/widgets/app_detail_bar.dart';
import 'package:beanbloss/widgets/app_empty_state.dart';
import 'package:beanbloss/widgets/product_image.dart';
import 'package:flutter/material.dart';

enum _TrackStep { received, preparing, almostReady, ready }

class _OrderLine {
  const _OrderLine({
    required this.name,
    required this.detail,
    required this.imageUrl,
  });

  final String name;
  final String detail;
  final String imageUrl;
}

class TrackOrderScreen extends StatefulWidget {
  const TrackOrderScreen({super.key, this.hasActiveOrder});

  /// When null, uses [OrderService.activeOrder] if present.
  final bool? hasActiveOrder;

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    OrderService.instance.addListener(_onOrderChanged);
    _ensureActiveOrder();
  }

  Future<void> _ensureActiveOrder() async {
    if (OrderService.instance.activeOrder != null) return;
    setState(() => _loading = true);
    try {
      await OrderService.instance.loadActiveOrder();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onOrderChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    OrderService.instance.removeListener(_onOrderChanged);
    _pulse.dispose();
    super.dispose();
  }

  AppOrder? get _live => OrderService.instance.activeOrder;

  bool get _hasOrder =>
      widget.hasActiveOrder == true || _live != null;

  _TrackStep get _current {
    switch (_live?.status) {
      case OrderStatus.received:
        return _TrackStep.received;
      case OrderStatus.preparing:
        return _TrackStep.preparing;
      case OrderStatus.almostReady:
        return _TrackStep.almostReady;
      case OrderStatus.ready:
      case OrderStatus.completed:
        return _TrackStep.ready;
      default:
        return _TrackStep.preparing;
    }
  }

  int get _minutesLeft => _live?.status.etaMinutes ?? 6;

  String get _orderId => _live?.orderNumber ?? '—';

  List<_OrderLine> get _items {
    final lines = _live?.items;
    if (lines == null || lines.isEmpty) {
      return const [];
    }
    return [
      for (final line in lines)
        _OrderLine(
          name: line.quantity > 1
              ? '${line.name} ×${line.quantity}'
              : line.name,
          detail: line.detailLabel,
          imageUrl: line.imageUrl,
        ),
    ];
  }

  double get _progress {
    switch (_current) {
      case _TrackStep.received:
        return 0.2;
      case _TrackStep.preparing:
        return 0.48;
      case _TrackStep.almostReady:
        return 0.78;
      case _TrackStep.ready:
        return 1.0;
    }
  }

  String get _statusTitle =>
      _live?.status.label ?? 'Being prepared';

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final showEmpty = !_hasOrder || (_live == null && !_loading);

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      body: SafeArea(
        child: Column(
          children: [
            const AppDetailBar(
              title: 'Track order',
              subtitle: 'Pickup at BeanBloss',
            ),
            Expanded(
              child: _loading && _live == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentGold,
                        strokeWidth: 2.5,
                      ),
                    )
                  : showEmpty
                      ? AppEmptyState(
                          icon: Icons.near_me_rounded,
                          title: 'No active order',
                          subtitle:
                              'When you place a pickup order, you can follow it here.',
                          actionLabel: 'Browse menu',
                          onAction: () {
                            Navigator.of(context).pushReplacement(
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
                            _StatusHero(
                              orderId: _orderId,
                              title: _statusTitle,
                              minutesLeft: _minutesLeft,
                              progress: _progress,
                              pulse: _pulse,
                            ),
                            const SizedBox(height: 18),
                            _StepStrip(current: _current),
                            const SizedBox(height: 24),
                            _sectionLabel('Your order'),
                            const SizedBox(height: 10),
                            _OrderCard(items: _items, orderId: _orderId),
                            const SizedBox(height: 16),
                            if (_live != null) _PaymentCard(order: _live!),
                            if (_live != null) const SizedBox(height: 16),
                            const _PickupCard(),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: AppColors.textLight.withOpacity(0.9),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _StatusHero extends StatelessWidget {
  const _StatusHero({
    required this.orderId,
    required this.title,
    required this.minutesLeft,
    required this.progress,
    required this.pulse,
  });

  final String orderId;
  final String title;
  final int minutesLeft;
  final double progress;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5A2E12).withOpacity(0.28),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF3D2112),
                      Color(0xFF6B3A1F),
                      Color(0xFF8B4513),
                      Color(0xFFC4895A),
                    ],
                    stops: [0.0, 0.35, 0.7, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -40,
              right: -20,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'PICKUP',
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
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.22),
                          ),
                        ),
                        child: Text(
                          orderId,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  AnimatedBuilder(
                    animation: pulse,
                    builder: (context, _) {
                      final glow = 0.12 + (pulse.value * 0.1);
                      return SizedBox(
                        width: 148,
                        height: 148,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 148,
                              height: 148,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(glow),
                                    blurRadius: 24,
                                  ),
                                ],
                              ),
                            ),
                            CustomPaint(
                              size: const Size(148, 148),
                              painter: _RingPainter(
                                progress: progress,
                                trackColor: Colors.white.withOpacity(0.16),
                                progressColor: Colors.white,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$minutesLeft',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 44,
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                    letterSpacing: -1.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'min left',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'We’ll notify you when it’s ready',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.78),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
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

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 7;
    const stroke = 7.0;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final prog = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      prog,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _StepStrip extends StatelessWidget {
  const _StepStrip({required this.current});

  final _TrackStep current;

  static const _labels = ['Received', 'Preparing', 'Almost', 'Ready'];

  @override
  Widget build(BuildContext context) {
    final idx = current.index;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.border()),
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < _labels.length; i++) ...[
                _StepDot(done: i <= idx, active: i == idx),
                if (i < _labels.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: i < idx
                            ? AppColors.primaryBrown
                            : AppColors.border(0.28),
                      ),
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < _labels.length; i++)
                Expanded(
                  child: Text(
                    _labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: i <= idx
                          ? AppColors.textDark
                          : AppColors.textLight.withOpacity(0.65),
                      fontSize: 11,
                      fontWeight:
                          i == idx ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.done, required this.active});

  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? AppColors.primaryBrown
            : done
                ? AppColors.softFill(0.45)
                : AppColors.softFill(0.12),
        border: Border.all(
          color: done || active
              ? AppColors.primaryBrown.withOpacity(0.5)
              : AppColors.border(0.3),
          width: 1.2,
        ),
      ),
      child: done || active
          ? Icon(
              active ? Icons.coffee_rounded : Icons.check_rounded,
              size: 12,
              color: active ? Colors.white : AppColors.primaryBrown,
            )
          : null,
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.items, required this.orderId});

  final List<_OrderLine> items;
  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.border()),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: ProductImage(
                      imageUrl: items[i].imageUrl,
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                      placeholderColor: AppColors.softFill(),
                      iconColor: AppColors.primaryBrown,
                      iconSize: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[i].name,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          items[i].detail,
                          style: const TextStyle(
                            color: AppColors.textLight,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '×1',
                    style: TextStyle(
                      color: AppColors.textLight.withOpacity(0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (i < items.length - 1)
              Divider(
                height: 1,
                indent: 80,
                endIndent: 14,
                color: AppColors.border(0.14),
              ),
          ],
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.order});

  final AppOrder order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.border()),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.softFill(0.28),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.payments_outlined,
              color: AppColors.primaryBrown,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.paymentMethod.label,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${order.paymentStatus.label} · \$${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PickupCard extends StatelessWidget {
  const _PickupCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.border()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.softFill(0.28),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: AppColors.primaryBrown,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppBrand.name,
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '${AppBrand.street}, ${AppBrand.cityLine}',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.softFill(0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: AppColors.primaryBrown,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppBrand.hours,
                    style: TextStyle(
                      color: AppColors.primaryBrown,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Show your order ID at the counter when you arrive.',
            style: TextStyle(
              color: AppColors.textLight.withOpacity(0.95),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
