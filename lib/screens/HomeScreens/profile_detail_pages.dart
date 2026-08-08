import 'package:beanbloss/screens/HomeScreens/cart_screen.dart';
import 'package:beanbloss/services/user_service.dart';
import 'package:beanbloss/utils/app_launch.dart';
import 'package:beanbloss/utils/responsive.dart';
import 'package:beanbloss/theme/app_colors.dart';
import 'package:beanbloss/widgets/app_detail_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Shared palette aliases (compat with existing page code) ─────────────────

class _P {
  static const primaryBg = AppColors.primaryBg;
  static const cardBg = AppColors.cardBg;
  static const primaryBrown = AppColors.primaryBrown;
  static const accentGold = AppColors.accentGold;
  static const textDark = AppColors.textDark;
  static const textLight = AppColors.textLight;
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: _P.primaryBrown,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ),
  );
}

// ─── Shared chrome ────────────────────────────────────────────────────────────

class ProfileSubScaffold extends StatelessWidget {
  const ProfileSubScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
    this.action,
    this.bottomBar,
  });

  final String title;
  final String? subtitle;
  final IconData? icon; // kept for call-site compat; unused in slim bar
  final Widget child;
  final Widget? action;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _P.primaryBg,
      body: SafeArea(
        child: Column(
          children: [
            AppDetailBar(
              title: title,
              subtitle: subtitle,
              action: action,
            ),
            Expanded(child: child),
            if (bottomBar != null) bottomBar!,
          ],
        ),
      ),
    );
  }
}

Widget _sectionTitle(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 4),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        color: _P.textLight.withOpacity(0.9),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    ),
  );
}

Widget _primaryButton({
  required String label,
  required VoidCallback onPressed,
  IconData? icon,
}) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _P.primaryBrown,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ],
      ),
    ),
  );
}

Widget _creamCard({required Widget child, EdgeInsetsGeometry? padding}) {
  return Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: _P.cardBg,
      borderRadius: BorderRadius.circular(AppRadii.xl),
      border: Border.all(color: AppColors.border()),
    ),
    child: child,
  );
}

// ─── Personal info ────────────────────────────────────────────────────────────

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key, required this.userData});

  final Map<String, dynamic> userData;

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _order;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.userData['name']);
    _email = TextEditingController(text: widget.userData['email']);
    _phone = TextEditingController(text: widget.userData['phone']);
    _order = TextEditingController(text: widget.userData['favoriteOrder']);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _order.dispose();
    super.dispose();
  }

  String get _initials {
    return _name.text
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((p) => p.isNotEmpty ? p[0].toUpperCase() : '')
        .join();
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return ProfileSubScaffold(
      title: 'Personal info',
      action: TextButton(
        onPressed: () {
          setState(() => _editing = !_editing);
          HapticFeedback.selectionClick();
        },
        child: Text(
          _editing ? 'Done' : 'Edit',
          style: const TextStyle(
            color: _P.primaryBrown,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      bottomBar: _editing
          ? Container(
              padding: EdgeInsets.fromLTRB(
                r.pagePadding,
                12,
                r.pagePadding,
                12 + MediaQuery.paddingOf(context).bottom,
              ),
              decoration: BoxDecoration(
                color: _P.cardBg,
                border: Border(
                  top: BorderSide(color: AppColors.border(0.18)),
                ),
              ),
              child: _primaryButton(
                label: 'Save changes',
                icon: Icons.check_rounded,
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  try {
                    await UserService.instance.updateProfile(
                      name: _name.text,
                      phone: _phone.text,
                      favoriteOrder: _order.text,
                    );
                    if (!context.mounted) return;
                    setState(() => _editing = false);
                    _toast(context, 'Profile updated');
                  } catch (_) {
                    if (!context.mounted) return;
                    _toast(context, 'Could not save profile');
                  }
                },
              ),
            )
          : null,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(r.pagePadding, 14, r.pagePadding, 28),
        children: [
          _IdentityHero(
            initials: _initials,
            name: _name.text,
            email: _email.text,
            memberSince: '${widget.userData['memberSince']}',
            tier: '${widget.userData['rewardsTier']}',
            points: '${widget.userData['rewardsPoints']}',
            editing: _editing,
          ),
          const SizedBox(height: 22),
          _sectionTitle('Contact'),
          _creamCard(
            child: Column(
              children: [
                _InfoRow(
                  label: 'Full name',
                  icon: Icons.person_outline_rounded,
                  controller: _name,
                  editing: _editing,
                  onChanged: () => setState(() {}),
                ),
                Divider(
                  height: 1,
                  indent: 62,
                  endIndent: 14,
                  color: AppColors.border(0.14),
                ),
                _InfoRow(
                  label: 'Email',
                  icon: Icons.mail_outline_rounded,
                  controller: _email,
                  editing: _editing,
                  keyboardType: TextInputType.emailAddress,
                ),
                Divider(
                  height: 1,
                  indent: 62,
                  endIndent: 14,
                  color: AppColors.border(0.14),
                ),
                _InfoRow(
                  label: 'Phone',
                  icon: Icons.phone_outlined,
                  controller: _phone,
                  editing: _editing,
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _sectionTitle('At BeanBloss'),
          _creamCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.softFill(0.28),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.coffee_rounded,
                    color: _P.primaryBrown,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Usual order',
                        style: TextStyle(
                          color: _P.textLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_editing)
                        TextField(
                          controller: _order,
                          style: const TextStyle(
                            color: _P.textDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          cursorColor: _P.primaryBrown,
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: AppColors.softFill(0.12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                          ),
                        )
                      else
                        Text(
                          _order.text,
                          style: const TextStyle(
                            color: _P.textDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
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

class _IdentityHero extends StatelessWidget {
  const _IdentityHero({
    required this.initials,
    required this.name,
    required this.email,
    required this.memberSince,
    required this.tier,
    required this.points,
    required this.editing,
  });

  final String initials;
  final String name;
  final String email;
  final String memberSince;
  final String tier;
  final String points;
  final bool editing;

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
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        AppBrand.name.toUpperCase(),
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
                              Icons.workspace_premium_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$tier · $points pts',
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
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.28),
                                  Colors.white.withOpacity(0.08),
                                ],
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.55),
                                width: 1.6,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ),
                          if (editing)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.border(0.4),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_outlined,
                                  size: 13,
                                  color: _P.primaryBrown,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Member since $memberSince',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.72),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.icon,
    required this.controller,
    required this.editing,
    this.keyboardType,
    this.onChanged,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final bool editing;
  final TextInputType? keyboardType;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: AppColors.softFill(),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: _P.primaryBrown, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _P.textLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                if (editing)
                  TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    onChanged: (_) => onChanged?.call(),
                    style: const TextStyle(
                      color: _P.textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    cursorColor: _P.primaryBrown,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.softFill(0.12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                    ),
                  )
                else
                  Text(
                    controller.text,
                    style: const TextStyle(
                      color: _P.textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
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

// ─── Payment methods ──────────────────────────────────────────────────────────

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key, required this.paymentMethods});

  final List<PaymentMethod> paymentMethods;

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  late List<PaymentMethod> _methods;

  @override
  void initState() {
    super.initState();
    _methods = List.of(widget.paymentMethods);
  }

  String _label(PaymentType type) {
    switch (type) {
      case PaymentType.visa:
        return 'Visa';
      case PaymentType.mastercard:
        return 'Mastercard';
      case PaymentType.applePay:
        return 'Apple Pay';
      case PaymentType.googlePay:
        return 'Google Pay';
      case PaymentType.paypal:
        return 'PayPal';
    }
  }

  List<Color> _cardColors(PaymentType type) {
    switch (type) {
      case PaymentType.visa:
        return const [Color(0xFF1A3A6B), Color(0xFF2E5A9E)];
      case PaymentType.mastercard:
        return const [Color(0xFF3D2415), Color(0xFF8B4513)];
      case PaymentType.applePay:
        return const [Color(0xFF1C1C1E), Color(0xFF3A3A3C)];
      default:
        return const [Color(0xFF5C4030), Color(0xFFD4A574)];
    }
  }

  void _setDefault(String id) {
    setState(() {
      _methods = _methods
          .map(
            (m) => PaymentMethod(
              id: m.id,
              type: m.type,
              lastFour: m.lastFour,
              expiryDate: m.expiryDate,
              isDefault: m.id == id,
            ),
          )
          .toList();
    });
    HapticFeedback.selectionClick();
    _toast(context, 'Default payment updated');
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return ProfileSubScaffold(
      title: 'Payment methods',
      bottomBar: Container(
        padding: EdgeInsets.fromLTRB(
          r.pagePadding,
          12,
          r.pagePadding,
          12 + MediaQuery.paddingOf(context).bottom,
        ),
        decoration: BoxDecoration(
          color: _P.cardBg,
          border: Border(
            top: BorderSide(color: AppColors.border(0.18)),
          ),
        ),
        child: _primaryButton(
          label: 'Add payment method',
          icon: Icons.add_rounded,
          onPressed: () async {
            HapticFeedback.selectionClick();
            final added = await Navigator.push<PaymentMethod>(
              context,
              MaterialPageRoute(builder: (_) => const AddPaymentMethodPage()),
            );
            if (added != null && mounted) {
              setState(() {
                _methods = [
                  ..._methods.map(
                    (m) => PaymentMethod(
                      id: m.id,
                      type: m.type,
                      lastFour: m.lastFour,
                      expiryDate: m.expiryDate,
                      isDefault: added.isDefault ? false : m.isDefault,
                    ),
                  ),
                  added,
                ];
              });
              if (!context.mounted) return;
              _toast(context, 'Payment method added');
            }
          },
        ),
      ),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(r.pagePadding, 14, r.pagePadding, 20),
        children: [
          Text(
            'SAVED FOR CHECKOUT',
            style: TextStyle(
              color: _P.textLight.withOpacity(0.9),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          ..._methods.map((p) {
            final colors = _cardColors(p.type);
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: colors.first.withOpacity(0.32),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: colors,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: -28,
                            right: -12,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.12),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -30,
                            left: -16,
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.1),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _label(p.type),
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.92),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (p.isDefault)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.28),
                                          ),
                                        ),
                                        child: const Text(
                                          'Default',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 36),
                                Text(
                                  p.lastFour.isEmpty
                                      ? 'Digital wallet'
                                      : '••••  ••••  ••••  ${p.lastFour}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Text(
                                      p.expiryDate.isEmpty
                                          ? 'Ready to use'
                                          : 'Expires ${p.expiryDate}',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      p.type == PaymentType.applePay
                                          ? Icons.apple
                                          : Icons.contactless_rounded,
                                      color: Colors.white.withOpacity(0.9),
                                      size: 26,
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
                  if (!p.isDefault) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _setDefault(p.id),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _P.primaryBrown,
                          side: BorderSide(color: AppColors.border(0.4)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                        ),
                        child: const Text(
                          'Set as default',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Visit us (single BeanBloss café) ─────────────────────────────────────────

class VisitUsPage extends StatelessWidget {
  const VisitUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return ProfileSubScaffold(
      title: 'Visit us',
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(r.pagePadding, 14, r.pagePadding, 28),
        children: [
          Container(
            decoration: BoxDecoration(
              color: _P.cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border()),
              boxShadow: [
                BoxShadow(
                  color: _P.primaryBrown.withOpacity(0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
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
                      stops: [0.0, 0.32, 0.68, 1.0],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -10,
                        top: -20,
                        child: Icon(
                          Icons.coffee_rounded,
                          size: 88,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'OUR CAFÉ',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.8,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.16),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.storefront_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  AppBrand.name,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppBrand.tagline,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Address',
                        style: TextStyle(
                          color: _P.textLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        AppBrand.fullAddress,
                        style: TextStyle(
                          color: _P.textDark,
                          fontSize: 15,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.softFill(0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 16,
                              color: _P.primaryBrown,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AppBrand.hours,
                                style: TextStyle(
                                  color: _P.primaryBrown,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => launchBeanBlossDirections(context),
                              icon: const Icon(Icons.directions_rounded, size: 18),
                              label: const Text(
                                'Directions',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _P.primaryBrown,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadii.md),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => launchBeanBlossPhone(context),
                              icon: const Icon(Icons.phone_outlined, size: 18),
                              label: const Text(
                                'Call',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _P.primaryBrown,
                                side: BorderSide(color: AppColors.border(0.4)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadii.md),
                                ),
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
          const SizedBox(height: 14),
          Text(
            'All orders are prepared for pickup at this BeanBloss counter.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _P.textLight.withOpacity(0.95),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Order history ────────────────────────────────────────────────────────────

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key, required this.orders});

  final List<OrderHistory> orders;

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.completed:
        return AppColors.success;
      case OrderStatus.processing:
        return _P.primaryBrown;
      case OrderStatus.pending:
        return const Color(0xFFB8860B);
      case OrderStatus.cancelled:
        return AppColors.destructive;
    }
  }

  void _reorder(BuildContext context, OrderHistory order) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartScreen(
          reorderOrderId: order.id,
          reorderItems: order.items,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final totalSpent = orders.fold<double>(0, (sum, o) => sum + o.total);

    return ProfileSubScaffold(
      title: 'Order history',
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(r.pagePadding, 14, r.pagePadding, 28),
        children: [
          Container(
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LIFETIME',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total spent',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${totalSpent.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.8,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.16),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.25),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '${orders.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    'orders',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Pickup at BeanBloss',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.78),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          _sectionTitle('Recent'),
          ...orders.map((o) {
            final statusLabel =
                o.status.name[0].toUpperCase() + o.status.name.substring(1);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: _P.cardBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border()),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.softFill(),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: _P.primaryBrown,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                o.id,
                                style: const TextStyle(
                                  color: _P.textDark,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                o.date,
                                style: const TextStyle(
                                  color: _P.textLight,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '\$${o.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: _P.primaryBrown,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...o.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: _P.accentGold,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item,
                                style: const TextStyle(
                                  color: _P.textDark,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(o.status).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: _statusColor(o.status),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _reorder(context, o),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _P.primaryBrown,
                          foregroundColor: Colors.white,
                          elevation: 0,
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
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Preferences ──────────────────────────────────────────────────────────────

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({super.key});

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  bool _locationEnabled = false;
  bool _saveFavorites = true;
  String _language = 'English';
  String _milk = 'Oat Milk';
  String _size = 'Medium';
  String _temp = 'Hot';

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return ProfileSubScaffold(
      title: 'Preferences',
      bottomBar: Container(
        padding: EdgeInsets.fromLTRB(
          r.pagePadding,
          12,
          r.pagePadding,
          12 + MediaQuery.paddingOf(context).bottom,
        ),
        decoration: BoxDecoration(
          color: _P.cardBg,
          border: Border(
            top: BorderSide(color: _P.accentGold.withOpacity(0.18)),
          ),
        ),
        child: _primaryButton(
          label: 'Save preferences',
          icon: Icons.check_rounded,
          onPressed: () {
            HapticFeedback.mediumImpact();
            _toast(context, 'Preferences saved');
          },
        ),
      ),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(r.pagePadding, 8, r.pagePadding, 20),
        children: [
          _sectionTitle('Default drink'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _P.cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _P.accentGold.withOpacity(0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _chipGroup(
                  'Size',
                  ['Small', 'Medium', 'Large'],
                  _size,
                  (v) => setState(() => _size = v),
                ),
                const SizedBox(height: 16),
                _chipGroup(
                  'Milk',
                  ['Whole', 'Oat Milk', 'Almond', 'Soy'],
                  _milk,
                  (v) => setState(() => _milk = v),
                ),
                const SizedBox(height: 16),
                _chipGroup(
                  'Temperature',
                  ['Hot', 'Iced'],
                  _temp,
                  (v) => setState(() => _temp = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _sectionTitle('App'),
          Container(
            decoration: BoxDecoration(
              color: _P.cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _P.accentGold.withOpacity(0.18)),
            ),
            child: Column(
              children: [
                _switchRow(
                  Icons.directions_outlined,
                  'Directions to BeanBloss',
                  'Help me navigate to our café',
                  _locationEnabled,
                  (v) => setState(() => _locationEnabled = v),
                ),
                _divider(),
                _switchRow(
                  Icons.favorite_border_rounded,
                  'Remember favorites',
                  'Keep your usual order ready',
                  _saveFavorites,
                  (v) => setState(() => _saveFavorites = v),
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _sectionTitle('Language'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _P.cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _P.accentGold.withOpacity(0.18)),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['English', 'Spanish', 'French', 'Arabic']
                  .map(
                    (lang) => ChoiceChip(
                      label: Text(lang),
                      selected: _language == lang,
                      onSelected: (_) => setState(() => _language = lang),
                      selectedColor: _P.primaryBrown,
                      backgroundColor: _P.accentGold.withOpacity(0.12),
                      labelStyle: TextStyle(
                        color: _language == lang ? Colors.white : _P.textDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipGroup(
    String label,
    List<String> options,
    String selected,
    ValueChanged<String> onSelect,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _P.textLight,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options
              .map(
                (o) => ChoiceChip(
                  label: Text(o),
                  selected: selected == o,
                  onSelected: (_) => onSelect(o),
                  selectedColor: _P.primaryBrown,
                  backgroundColor: _P.accentGold.withOpacity(0.12),
                  labelStyle: TextStyle(
                    color: selected == o ? Colors.white : _P.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _switchRow(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged, {
    bool isLast = false,
  }) {
    return Column(
      children: [
        SwitchListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          secondary: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _P.accentGold.withOpacity(0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: _P.primaryBrown, size: 18),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: _P.textDark,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: _P.textLight, fontSize: 12),
          ),
          value: value,
          activeColor: _P.primaryBrown,
          onChanged: onChanged,
        ),
        if (!isLast) _divider(),
      ],
    );
  }

  Widget _divider() => Divider(
        height: 1,
        indent: 62,
        endIndent: 14,
        color: _P.accentGold.withOpacity(0.14),
      );
}

// ─── Notifications ────────────────────────────────────────────────────────────

class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  State<NotificationsSettingsPage> createState() =>
      _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  bool _push = true;
  bool _orderUpdates = true;
  bool _offers = true;
  bool _rewards = true;
  bool _email = true;
  bool _receipts = true;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return ProfileSubScaffold(
      title: 'Notifications',
      bottomBar: Container(
        padding: EdgeInsets.fromLTRB(
          r.pagePadding,
          12,
          r.pagePadding,
          12 + MediaQuery.paddingOf(context).bottom,
        ),
        decoration: BoxDecoration(
          color: _P.cardBg,
          border: Border(
            top: BorderSide(color: AppColors.border(0.18)),
          ),
        ),
        child: _primaryButton(
          label: 'Save settings',
          icon: Icons.check_rounded,
          onPressed: () {
            HapticFeedback.mediumImpact();
            _toast(context, 'Notification settings saved');
          },
        ),
      ),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(r.pagePadding, 14, r.pagePadding, 20),
        children: [
          Container(
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
                    top: -30,
                    right: -16,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.12),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Stay in the loop',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Orders, rewards, and offers from BeanBloss.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12.5,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          _sectionTitle('Push'),
          _notifGroup([
            _NotifToggle(
              icon: Icons.notifications_none_rounded,
              title: 'Push notifications',
              subtitle: 'Master control for app alerts',
              value: _push,
              onChanged: (v) => setState(() => _push = v),
            ),
            _NotifToggle(
              icon: Icons.storefront_outlined,
              title: 'Order updates',
              subtitle: 'Ready for pickup & status changes',
              value: _orderUpdates,
              onChanged: (v) => setState(() => _orderUpdates = v),
              enabled: _push,
            ),
            _NotifToggle(
              icon: Icons.local_offer_outlined,
              title: 'Offers & promos',
              subtitle: 'Seasonal deals and specials',
              value: _offers,
              onChanged: (v) => setState(() => _offers = v),
              enabled: _push,
            ),
            _NotifToggle(
              icon: Icons.card_giftcard_rounded,
              title: 'Rewards',
              subtitle: 'Points, tiers, and free drinks',
              value: _rewards,
              onChanged: (v) => setState(() => _rewards = v),
              enabled: _push,
              isLast: true,
            ),
          ]),
          const SizedBox(height: 22),
          _sectionTitle('Email'),
          _notifGroup([
            _NotifToggle(
              icon: Icons.mail_outline_rounded,
              title: 'Email updates',
              subtitle: 'Newsletters and account mail',
              value: _email,
              onChanged: (v) => setState(() => _email = v),
            ),
            _NotifToggle(
              icon: Icons.receipt_long_outlined,
              title: 'Order receipts',
              subtitle: 'Send a copy after each order',
              value: _receipts,
              onChanged: (v) => setState(() => _receipts = v),
              enabled: _email,
              isLast: true,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _notifGroup(List<Widget> children) {
    return _creamCard(child: Column(children: children));
  }
}

class _NotifToggle extends StatelessWidget {
  const _NotifToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Opacity(
          opacity: enabled ? 1 : 0.45,
          child: SwitchListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            secondary: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.softFill(),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: _P.primaryBrown, size: 18),
            ),
            title: Text(
              title,
              style: const TextStyle(
                color: _P.textDark,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: const TextStyle(color: _P.textLight, fontSize: 12),
            ),
            value: value && enabled,
            activeColor: _P.primaryBrown,
            onChanged: enabled ? onChanged : null,
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 62,
            endIndent: 14,
            color: AppColors.border(0.14),
          ),
      ],
    );
  }
}

// ─── Support ──────────────────────────────────────────────────────────────────

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  static const _faqs = [
    (
      'How does pickup work?',
      'Order in the app, come to the BeanBloss counter, and show your confirmation when you arrive.'
    ),
    (
      'How do rewards work?',
      'Earn points on every purchase. Higher tiers unlock free drinks and special treats.'
    ),
    (
      'Can I change an order?',
      'You can change or cancel within a few minutes of placing. After we start preparing, call BeanBloss.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return ProfileSubScaffold(
      title: 'Support',
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(r.pagePadding, 14, r.pagePadding, 28),
        children: [
          Container(
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
                    top: -30,
                    right: -16,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.12),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WE\'RE HERE',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.16),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: const Icon(
                                Icons.support_agent_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Need a hand?',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Contact BeanBloss or browse quick answers.',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12.5,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
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
          const SizedBox(height: 22),
          _sectionTitle('Contact'),
          _creamCard(
            child: Column(
              children: [
                _SupportTile(
                  icon: Icons.mail_outline_rounded,
                  title: 'Email',
                  detail: AppBrand.email,
                  onTap: () => launchBeanBlossEmail(context),
                ),
                Divider(
                  height: 1,
                  indent: 62,
                  endIndent: 14,
                  color: AppColors.border(0.14),
                ),
                _SupportTile(
                  icon: Icons.phone_outlined,
                  title: 'Call',
                  detail: AppBrand.phone,
                  onTap: () => launchBeanBlossPhone(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _sectionTitle('Café'),
          _creamCard(
            padding: const EdgeInsets.all(16),
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
                        color: _P.primaryBrown,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        AppBrand.name,
                        style: TextStyle(
                          color: _P.textDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  AppBrand.fullAddress,
                  style: TextStyle(
                    color: _P.textLight,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.softFill(0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 15,
                        color: _P.primaryBrown,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppBrand.hours,
                          style: TextStyle(
                            color: _P.primaryBrown,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => launchBeanBlossDirections(context),
                    icon: const Icon(Icons.directions_rounded, size: 18),
                    label: const Text(
                      'Get directions',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _P.primaryBrown,
                      side: BorderSide(color: AppColors.border(0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _sectionTitle('More help'),
          _creamCard(
            child: Column(
              children: [
                _SupportTile(
                  icon: Icons.menu_book_outlined,
                  title: 'Help center',
                  detail: 'Guides and common questions',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const HelpCenterPage(),
                      ),
                    );
                  },
                ),
                Divider(
                  height: 1,
                  indent: 62,
                  endIndent: 14,
                  color: AppColors.border(0.14),
                ),
                _SupportTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Contact us',
                  detail: 'Reach the café team',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ContactUsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _sectionTitle('FAQs'),
          ..._faqs.map(
            (faq) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _creamCard(
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    iconColor: _P.primaryBrown,
                    collapsedIconColor: _P.textLight,
                    title: Text(
                      faq.$1,
                      style: const TextStyle(
                        color: _P.textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    children: [
                      Text(
                        faq.$2,
                        style: const TextStyle(
                          color: _P.textLight,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Legal details are in Profile → About.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _P.textLight.withOpacity(0.9),
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  const _SupportTile({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.softFill(),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: _P.primaryBrown, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _P.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: const TextStyle(color: _P.textLight, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: _P.textLight.withOpacity(0.65),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  static const _faqs = [
    (
      'How does pickup work?',
      'Place your order in the app, head to your BeanBloss counter, and show the order confirmation when you arrive.'
    ),
    (
      'How do rewards points work?',
      'Earn points on every purchase. Reach tier milestones to unlock free drinks, birthday treats, and early access to seasonal menus.'
    ),
    (
      'Can I change or cancel an order?',
      'You can modify or cancel within a few minutes of placing. After preparation starts, contact BeanBloss for help.'
    ),
    (
      'Where is my receipt?',
      'Find receipts under Order history. Enable email receipts in Notifications if you want a copy in your inbox.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return ProfileSubScaffold(
      title: 'Help center',
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(r.pagePadding, 8, r.pagePadding, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFB8845A), Color(0xFFD4A574)],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.support_agent_rounded, color: Colors.white, size: 28),
                SizedBox(height: 10),
                Text(
                  'Need a hand?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Browse common questions or reach out if you still need help.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _sectionTitle('FAQs'),
          ..._faqs.map(
            (faq) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: _P.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _P.accentGold.withOpacity(0.18)),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  iconColor: _P.primaryBrown,
                  collapsedIconColor: _P.textLight,
                  title: Text(
                    faq.$1,
                    style: const TextStyle(
                      color: _P.textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  children: [
                    Text(
                      faq.$2,
                      style: const TextStyle(
                        color: _P.textLight,
                        fontSize: 13,
                        height: 1.45,
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

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return ProfileSubScaffold(
      title: 'Contact us',
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(r.pagePadding, 8, r.pagePadding, 28),
        children: [
          Text(
            'We usually reply within a few hours during BeanBloss hours.',
            style: TextStyle(
              color: _P.textLight.withOpacity(0.95),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          _contactCard(
            context,
            Icons.mail_outline_rounded,
            'Email',
            AppBrand.email,
            'Send an email',
            () => launchBeanBlossEmail(context),
          ),
          const SizedBox(height: 10),
          _contactCard(
            context,
            Icons.phone_outlined,
            'Phone',
            AppBrand.phone,
            'Call BeanBloss',
            () => launchBeanBlossPhone(context),
          ),
          const SizedBox(height: 10),
          _contactCard(
            context,
            Icons.chat_bubble_outline_rounded,
            'Live chat',
            'Available 8am – 8pm',
            'Start chat',
            () {
              HapticFeedback.selectionClick();
              _toast(context, 'Chat opens during café hours');
            },
          ),
          const SizedBox(height: 22),
          _sectionTitle('Our café'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _P.cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _P.accentGold.withOpacity(0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppBrand.name,
                  style: TextStyle(
                    color: _P.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  AppBrand.fullAddress,
                  style: TextStyle(
                    color: _P.textLight,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  AppBrand.hours,
                  style: TextStyle(
                    color: _P.primaryBrown,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => launchBeanBlossDirections(context),
                    icon: const Icon(Icons.directions_rounded, size: 18),
                    label: const Text(
                      'Get directions',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _P.primaryBrown,
                      side: BorderSide(color: AppColors.border(0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactCard(
    BuildContext context,
    IconData icon,
    String title,
    String detail,
    String action,
    VoidCallback onAction,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _P.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _P.accentGold.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _P.accentGold.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _P.primaryBrown, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _P.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(color: _P.textLight, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onAction,
            child: Text(
              action,
              style: const TextStyle(
                color: _P.primaryBrown,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return ProfileSubScaffold(
      title: 'About BeanBloss',
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(r.pagePadding, 8, r.pagePadding, 28),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFB8845A),
                  Color(0xFFC9956B),
                  Color(0xFFD4A574),
                ],
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.4)),
                  ),
                  child: const Icon(
                    Icons.coffee_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'BeanBloss',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _P.cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _P.accentGold.withOpacity(0.18)),
            ),
            child: const Text(
              'BeanBloss is our café — carefully roasted beans, warm service, and rewards that feel personal. Order ahead for pickup at our counter and collect points with every cup.',
              style: TextStyle(
                color: _P.textDark,
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: _P.cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _P.accentGold.withOpacity(0.18)),
            ),
            child: Column(
              children: [
                _aboutLink(
                  context,
                  'Terms of service',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TermsOfServicePage(),
                      ),
                    );
                  },
                ),
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: _P.accentGold.withOpacity(0.14),
                ),
                _aboutLink(
                  context,
                  'Privacy policy',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyPage(),
                      ),
                    );
                  },
                ),
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: _P.accentGold.withOpacity(0.14),
                ),
                _aboutLink(
                  context,
                  'Open source licenses',
                  isLast: true,
                  onTap: () => _toast(context, 'Licenses coming soon'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Made with care in Seattle',
              style: TextStyle(
                color: _P.textLight,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aboutLink(
    BuildContext context,
    String title, {
    bool isLast = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(isLast ? 18 : 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: _P.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: _P.textLight.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add payment method ───────────────────────────────────────────────────────

class AddPaymentMethodPage extends StatefulWidget {
  const AddPaymentMethodPage({super.key});

  @override
  State<AddPaymentMethodPage> createState() => _AddPaymentMethodPageState();
}

class _AddPaymentMethodPageState extends State<AddPaymentMethodPage> {
  final _name = TextEditingController();
  final _number = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();
  PaymentType _type = PaymentType.visa;
  bool _makeDefault = true;

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    _expiry.dispose();
    _cvv.dispose();
    super.dispose();
  }

  String get _digitsOnly => _number.text.replaceAll(RegExp(r'\D'), '');

  bool get _valid {
    if (_type == PaymentType.applePay ||
        _type == PaymentType.googlePay ||
        _type == PaymentType.paypal) {
      return true;
    }
    return _name.text.trim().isNotEmpty &&
        _digitsOnly.length >= 12 &&
        _expiry.text.trim().length >= 4 &&
        _cvv.text.trim().length >= 3;
  }

  void _save() {
    if (!_valid) {
      _toast(context, 'Please complete card details');
      return;
    }
    HapticFeedback.mediumImpact();
    final lastFour = _digitsOnly.length >= 4
        ? _digitsOnly.substring(_digitsOnly.length - 4)
        : '';
    final method = PaymentMethod(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _type,
      lastFour: lastFour,
      expiryDate: _expiry.text.trim(),
      isDefault: _makeDefault,
    );
    Navigator.pop(context, method);
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final isCard = _type == PaymentType.visa || _type == PaymentType.mastercard;

    return ProfileSubScaffold(
      title: 'Add payment',
      bottomBar: Container(
        padding: EdgeInsets.fromLTRB(
          r.pagePadding,
          12,
          r.pagePadding,
          12 + MediaQuery.paddingOf(context).bottom,
        ),
        decoration: BoxDecoration(
          color: _P.cardBg,
          border: Border(
            top: BorderSide(color: AppColors.border(0.18)),
          ),
        ),
        child: _primaryButton(
          label: 'Save payment method',
          icon: Icons.check_rounded,
          onPressed: _save,
        ),
      ),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(r.pagePadding, 14, r.pagePadding, 28),
        children: [
          _sectionTitle('Type'),
          _creamCard(
            padding: const EdgeInsets.all(14),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in [
                  PaymentType.visa,
                  PaymentType.mastercard,
                  PaymentType.applePay,
                  PaymentType.googlePay,
                ])
                  ChoiceChip(
                    label: Text(_typeLabel(t)),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                    selectedColor: _P.primaryBrown,
                    backgroundColor: AppColors.softFill(0.16),
                    labelStyle: TextStyle(
                      color: _type == t ? Colors.white : _P.textDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
              ],
            ),
          ),
          if (isCard) ...[
            const SizedBox(height: 22),
            _sectionTitle('Card details'),
            _creamCard(
              child: Column(
                children: [
                  _payField('Name on card', _name, Icons.person_outline_rounded),
                  Divider(height: 1, indent: 62, endIndent: 14, color: AppColors.border(0.14)),
                  _payField(
                    'Card number',
                    _number,
                    Icons.credit_card_rounded,
                    keyboardType: TextInputType.number,
                    hint: '•••• •••• •••• ••••',
                  ),
                  Divider(height: 1, indent: 62, endIndent: 14, color: AppColors.border(0.14)),
                  Row(
                    children: [
                      Expanded(
                        child: _payField(
                          'Expiry',
                          _expiry,
                          Icons.calendar_today_outlined,
                          keyboardType: TextInputType.datetime,
                          hint: 'MM/YY',
                          showDivider: false,
                        ),
                      ),
                      Container(width: 1, height: 56, color: AppColors.border(0.14)),
                      Expanded(
                        child: _payField(
                          'CVV',
                          _cvv,
                          Icons.lock_outline_rounded,
                          keyboardType: TextInputType.number,
                          hint: '•••',
                          showDivider: false,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 22),
            _creamCard(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${_typeLabel(_type)} will be linked to your BeanBloss account for pickup checkout.',
                style: const TextStyle(
                  color: _P.textLight,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _creamCard(
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              title: const Text(
                'Set as default',
                style: TextStyle(
                  color: _P.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Use this method at checkout',
                style: TextStyle(color: _P.textLight, fontSize: 12),
              ),
              value: _makeDefault,
              activeColor: _P.primaryBrown,
              onChanged: (v) => setState(() => _makeDefault = v),
            ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(PaymentType t) {
    switch (t) {
      case PaymentType.visa:
        return 'Visa';
      case PaymentType.mastercard:
        return 'Mastercard';
      case PaymentType.applePay:
        return 'Apple Pay';
      case PaymentType.googlePay:
        return 'Google Pay';
      case PaymentType.paypal:
        return 'PayPal';
    }
  }

  Widget _payField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
    String? hint,
    bool showDivider = true,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.softFill(),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: _P.primaryBrown, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _P.textLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    color: _P.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  cursorColor: _P.primaryBrown,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: _P.textLight.withOpacity(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
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

// ─── Terms & Privacy ──────────────────────────────────────────────────────────

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  static const _sections = [
    (
      '1. Orders & pickup',
      'BeanBloss is a single café. Orders placed in the app are for pickup at our counter. You are responsible for collecting your order within a reasonable time after it is marked ready.'
    ),
    (
      '2. Payments',
      'Payment methods you save are used only for BeanBloss purchases. Prices shown in the app include applicable taxes unless noted. Refunds for cancelled or incorrect orders are handled at the café’s discretion.'
    ),
    (
      '3. Rewards',
      'Rewards points and tiers are promotional benefits and may change. Points have no cash value and cannot be transferred. BeanBloss may adjust or end the program with notice in the app.'
    ),
    (
      '4. Account use',
      'Keep your login details secure. You agree not to misuse the app, attempt unauthorized access, or interfere with other customers’ orders.'
    ),
    (
      '5. Changes',
      'We may update these terms. Continued use of BeanBloss after changes means you accept the updated terms. Questions? Contact us via Support in the app.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return ProfileSubScaffold(
      title: 'Terms of service',
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(r.pagePadding, 14, r.pagePadding, 28),
        children: [
          _LegalHero(
            title: 'Terms of service',
            subtitle: 'How BeanBloss orders, payments, and rewards work.',
          ),
          const SizedBox(height: 18),
          ..._sections.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _creamCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.$1,
                      style: const TextStyle(
                        color: _P.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.$2,
                      style: const TextStyle(
                        color: _P.textLight,
                        fontSize: 13.5,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Center(
            child: Text(
              'Last updated · August 2026',
              style: TextStyle(color: _P.textLight, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const _sections = [
    (
      '1. Information we collect',
      'We collect account details you provide (name, email, phone), order history, payment method metadata (such as last four digits and expiry — not full card numbers stored in this demo), and app preferences like notification settings.'
    ),
    (
      '2. How we use it',
      'We use your information to prepare pickup orders, process payments, run rewards, send order and offer notifications you enable, and improve the BeanBloss experience.'
    ),
    (
      '3. Sharing',
      'We do not sell your personal information. We may share data with payment processors and service providers solely to operate the café and app. Legal requests may require disclosure where required by law.'
    ),
    (
      '4. Retention & security',
      'We keep account and order data while your account is active and as needed for café operations. We use reasonable safeguards to protect your information.'
    ),
    (
      '5. Your choices',
      'Update personal info in Profile, manage notifications anytime, or contact Support to request help with your account. You can also review Terms of service from Profile → About.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return ProfileSubScaffold(
      title: 'Privacy policy',
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(r.pagePadding, 14, r.pagePadding, 28),
        children: [
          _LegalHero(
            title: 'Privacy policy',
            subtitle: 'How BeanBloss handles your account and order data.',
          ),
          const SizedBox(height: 18),
          ..._sections.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _creamCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.$1,
                      style: const TextStyle(
                        color: _P.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.$2,
                      style: const TextStyle(
                        color: _P.textLight,
                        fontSize: 13.5,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Center(
            child: Text(
              'Last updated · August 2026',
              style: TextStyle(color: _P.textLight, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalHero extends StatelessWidget {
  const _LegalHero({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3D2112),
            Color(0xFF8B4513),
            Color(0xFFC4895A),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _P.primaryBrown.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppBrand.name.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.82),
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Models ───────────────────────────────────────────────────────────────────

enum PaymentType { visa, mastercard, applePay, googlePay, paypal }

class PaymentMethod {
  final String id;
  final PaymentType type;
  final String lastFour;
  final String expiryDate;
  final bool isDefault;

  PaymentMethod({
    required this.id,
    required this.type,
    required this.lastFour,
    required this.expiryDate,
    required this.isDefault,
  });
}

enum OrderStatus { pending, processing, completed, cancelled }

class OrderHistory {
  final String id;
  final String date;
  final List<String> items;
  final double total;
  final OrderStatus status;

  OrderHistory({
    required this.id,
    required this.date,
    required this.items,
    required this.total,
    required this.status,
  });
}
