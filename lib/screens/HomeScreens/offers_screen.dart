import 'package:beanbloss/state/cart_store.dart';
import 'package:beanbloss/theme/app_colors.dart';
import 'package:beanbloss/utils/responsive.dart';
import 'package:beanbloss/widgets/app_detail_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class _Offer {
  const _Offer({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.code,
    required this.expires,
    required this.gradient,
  });

  final String title;
  final String subtitle;
  final String badge;
  final String code;
  final String expires;
  final List<Color> gradient;
}

class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});

  static const _offers = [
    _Offer(
      title: 'Espresso Happy Hour',
      subtitle: 'Buy one espresso drink, get the second free.',
      badge: 'BOGO',
      code: 'BOGOESP',
      expires: 'Ends Sunday',
      gradient: [Color(0xFFC9956B), Color(0xFFD4A574), Color(0xFFE8C9A0)],
    ),
    _Offer(
      title: 'Premium Arabica',
      subtitle: '20% off any Arabica pour-over or drip.',
      badge: '20% OFF',
      code: 'ARABICA20',
      expires: 'Ends Friday',
      gradient: [Color(0xFF4A2814), Color(0xFF8B4513), Color(0xFFB8845A)],
    ),
    _Offer(
      title: 'Espresso Special',
      subtitle: '15% off classic espresso and macchiatos.',
      badge: '15% OFF',
      code: 'ESPRESSO15',
      expires: 'Ends in 3 days',
      gradient: [Color(0xFF6B3A1F), Color(0xFFA0522D), Color(0xFFD4A574)],
    ),
    _Offer(
      title: 'Cold Brew Collection',
      subtitle: '25% off all cold brew sizes this week.',
      badge: '25% OFF',
      code: 'COLDBREW25',
      expires: 'Ends Thursday',
      gradient: [Color(0xFF3D2A1E), Color(0xFF8B7355), Color(0xFFD4A574)],
    ),
    _Offer(
      title: 'Weekend Special',
      subtitle: 'Buy 2 drinks, get 1 free pastry.',
      badge: 'WEEKEND',
      code: 'WEEKEND',
      expires: 'Sat & Sun only',
      gradient: [Color(0xFF8B4513), Color(0xFFC4895A), Color(0xFFE8C9A0)],
    ),
  ];

  void _copyCode(BuildContext context, String code) {
    HapticFeedback.mediumImpact();
    Clipboard.setData(ClipboardData(text: code));
    final applied = CartStore.instance.applyPromo(code);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          applied
              ? (CartStore.instance.items.isEmpty
                  ? 'Code $code saved for checkout'
                  : 'Code $code applied to cart')
              : 'Invalid code $code',
        ),
        backgroundColor: AppColors.primaryBrown,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      body: SafeArea(
        child: Column(
          children: [
            AppDetailBar(
              title: 'Offers',
              subtitle: '${_offers.length} available',
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  r.pagePadding,
                  16,
                  r.pagePadding,
                  28,
                ),
                children: [
                  Text(
                    'TAP TO APPLY CODE',
                    style: TextStyle(
                      color: AppColors.textLight.withOpacity(0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._offers.map(
                    (offer) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _OfferCard(
                        offer: offer,
                        onCopy: () => _copyCode(context, offer.code),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Show your code at the BeanBloss counter or apply it at checkout.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textLight.withOpacity(0.85),
                      fontSize: 12.5,
                      height: 1.4,
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

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer, required this.onCopy});

  final _Offer offer;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onCopy,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: offer.gradient,
            ),
            boxShadow: [
              BoxShadow(
                color: offer.gradient.first.withOpacity(0.28),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -16,
                top: -16,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),
              ),
              Positioned(
                right: 40,
                bottom: -24,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.08),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        offer.badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      offer.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      offer.subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.88),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.28),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.local_offer_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  offer.code,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          offer.expires,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
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
    );
  }
}
