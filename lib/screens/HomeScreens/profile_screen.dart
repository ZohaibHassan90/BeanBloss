import 'dart:io';

import 'package:beanbloss/models/app_order.dart' as app;
import 'package:beanbloss/models/user_profile.dart';
import 'package:beanbloss/screens/start/onboarding_screen.dart';
import 'package:beanbloss/services/auth_service.dart';
import 'package:beanbloss/services/cloudinary_service.dart';
import 'package:beanbloss/services/order_service.dart';
import 'package:beanbloss/services/user_service.dart';
import 'package:beanbloss/state/cart_store.dart';
import 'package:beanbloss/theme/app_colors.dart';
import 'package:beanbloss/utils/responsive.dart';
import 'package:beanbloss/widgets/app_bottom_nav.dart';
import 'package:beanbloss/widgets/app_fab.dart';
import 'package:beanbloss/widgets/app_sheet.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'profile_detail_pages.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Map<String, dynamic> userData;
  List<OrderHistory> recentOrders = [];
  bool _uploadingPhoto = false;

  final List<PaymentMethod> paymentMethods = [
    PaymentMethod(
      id: '1',
      type: PaymentType.visa,
      lastFour: '4582',
      expiryDate: '05/25',
      isDefault: true,
    ),
    PaymentMethod(
      id: '2',
      type: PaymentType.mastercard,
      lastFour: '8724',
      expiryDate: '11/24',
      isDefault: false,
    ),
    PaymentMethod(
      id: '3',
      type: PaymentType.applePay,
      lastFour: '',
      expiryDate: '',
      isDefault: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    userData = _fallbackUserData();
    _applyProfile(UserService.instance.cached);
    UserService.instance.addListener(_onProfileChanged);
    _refreshProfile();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await OrderService.instance.loadRecentOrders();
      if (!mounted) return;
      setState(() {
        recentOrders = orders.map(_toHistory).toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => recentOrders = []);
    }
  }

  OrderHistory _toHistory(app.AppOrder order) {
    final status = switch (order.status) {
      app.OrderStatus.completed => OrderStatus.completed,
      app.OrderStatus.cancelled => OrderStatus.cancelled,
      app.OrderStatus.ready ||
      app.OrderStatus.almostReady ||
      app.OrderStatus.preparing =>
        OrderStatus.processing,
      app.OrderStatus.received => OrderStatus.pending,
    };
    return OrderHistory(
      id: order.orderNumber,
      date: order.whenLabel,
      items: order.items.map((e) => e.name).toList(),
      total: order.total,
      status: status,
    );
  }

  @override
  void dispose() {
    UserService.instance.removeListener(_onProfileChanged);
    super.dispose();
  }

  Map<String, dynamic> _fallbackUserData() {
    final user = FirebaseAuth.instance.currentUser;
    final name = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : 'BeanBloss Guest';
    final email = (user?.email?.trim().isNotEmpty ?? false)
        ? user!.email!.trim()
        : 'hello@beanbloss.com';
    return {
      'name': name,
      'email': email,
      'phone': '',
      'photoUrl': '',
      'memberSince': 'BeanBloss member',
      'rewardsPoints': 0,
      'rewardsTier': 'Bronze',
      'favoriteOrder': '',
    };
  }

  void _applyProfile(UserProfile? profile) {
    if (profile == null) return;
    userData = {
      'name': profile.name.isNotEmpty ? profile.name : userData['name'],
      'email': profile.email.isNotEmpty ? profile.email : userData['email'],
      'phone': profile.phone,
      'photoUrl': profile.photoUrl,
      'memberSince': profile.memberSinceLabel,
      'rewardsPoints': profile.rewardsPoints,
      'rewardsTier': profile.rewardsTier,
      'favoriteOrder': profile.favoriteOrder.isNotEmpty
          ? profile.favoriteOrder
          : '—',
    };
  }

  void _onProfileChanged() {
    if (!mounted) return;
    setState(() => _applyProfile(UserService.instance.cached));
  }

  Future<void> _refreshProfile() async {
    try {
      final profile =
          await UserService.instance.loadCurrentUser(forceRefresh: true);
      if (!mounted) return;
      setState(() => _applyProfile(profile));
    } catch (_) {
      // Keep Auth fallback if Firestore is offline / unavailable.
    }
  }

  Future<void> _changeAvatar() async {
    if (_uploadingPhoto) return;
    HapticFeedback.selectionClick();
    showAppSheet(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Profile photo',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Upload to Cloudinary · beanbloss/avatars',
              style: TextStyle(color: AppColors.textLight, fontSize: 13),
            ),
            const SizedBox(height: 18),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primaryBrown),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAndUpload(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: AppColors.primaryBrown),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAndUpload(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _uploadingPhoto = true);
      final url = await CloudinaryService.instance.uploadImage(
        File(picked.path),
        kind: CloudinaryUploadKind.avatar,
      );
      await UserService.instance.updateProfile(photoUrl: url);
      if (!mounted) return;
      setState(() {
        _uploadingPhoto = false;
        _applyProfile(UserService.instance.cached);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile photo updated'),
          backgroundColor: AppColors.primaryBrown,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is StateError ? e.message : 'Could not upload photo. Try again.',
          ),
          backgroundColor: AppColors.primaryBrown,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  String get _initials {
    return (userData['name'] as String)
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((p) => p.isNotEmpty ? p[0].toUpperCase() : '')
        .join();
  }

  String get _memberYear =>
      '${userData['memberSince']}'.split(RegExp(r'\s+')).last;

  void _open(Widget page) {
    HapticFeedback.selectionClick();
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _confirmLogout() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Log out?',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          'You can sign back in anytime at BeanBloss.',
          style: TextStyle(color: AppColors.textLight, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textLight),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.instance.signOut();
              CartStore.instance.clearSession();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const AuthScreen(),
                ),
                (_) => false,
              );
            },
            child: const Text(
              'Log out',
              style: TextStyle(
                color: AppColors.primaryBrown,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(r.pagePadding, 8, r.pagePadding, 120),
          children: [
            _buildHeroCard(),
            const SizedBox(height: 28),
            _sectionLabel('Account'),
            const SizedBox(height: 10),
            _menuGroup([
              _MenuItem(
                icon: Icons.person_outline_rounded,
                title: 'Personal info',
                onTap: () => _open(PersonalInfoPage(userData: userData)),
              ),
              _MenuItem(
                icon: Icons.receipt_long_outlined,
                title: 'Orders',
                onTap: () => _open(OrderHistoryPage(orders: recentOrders)),
              ),
              _MenuItem(
                icon: Icons.credit_card_rounded,
                title: 'Payments',
                onTap: () => _open(
                  PaymentMethodsPage(paymentMethods: paymentMethods),
                ),
              ),
              _MenuItem(
                icon: Icons.storefront_outlined,
                title: 'Visit us',
                onTap: () => _open(const VisitUsPage()),
              ),
            ]),
            const SizedBox(height: 22),
            _sectionLabel('More'),
            const SizedBox(height: 10),
            _menuGroup([
              _MenuItem(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                onTap: () => _open(const NotificationsSettingsPage()),
              ),
              _MenuItem(
                icon: Icons.tune_rounded,
                title: 'Preferences',
                onTap: () => _open(const PreferencesPage()),
              ),
              _MenuItem(
                icon: Icons.support_agent_rounded,
                title: 'Support',
                onTap: () => _open(const SupportPage()),
              ),
            ]),
            const SizedBox(height: 22),
            _sectionLabel('About'),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(AppRadii.xl),
                border: Border.all(color: AppColors.border()),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Text(
                      'BeanBloss is our café — order ahead for pickup, earn rewards, and enjoy carefully roasted coffee.',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: AppColors.border(0.14),
                  ),
                  _aboutLink(
                    'About BeanBloss',
                    () => _open(const AboutPage()),
                  ),
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: AppColors.border(0.14),
                  ),
                  _aboutLink(
                    'Terms of service',
                    () => _open(const TermsOfServicePage()),
                  ),
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: AppColors.border(0.14),
                  ),
                  _aboutLink(
                    'Privacy policy',
                    () => _open(const PrivacyPolicyPage()),
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'BeanBloss · Version 1.0.0',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 28),
            _logoutButton(),
          ],
        ),
      ),
      floatingActionButton: const AppCartFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5A2E12).withOpacity(0.22),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: AppColors.accentGold.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withOpacity(0.22),
            width: 1.2,
          ),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4A2814),
              Color(0xFF6B3A1F),
              Color(0xFF8B4513),
              Color(0xFFC4895A),
              Color(0xFFD4A574),
            ],
            stops: [0.0, 0.22, 0.48, 0.78, 1.0],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(27),
          child: Stack(
            children: [
              // Soft light wash
              Positioned(
                top: -50,
                right: -30,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.22),
                        Colors.white.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -55,
                left: -25,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.12),
                  ),
                ),
              ),
              // Fine diagonal sheen
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: const Alignment(-1.0, -1.0),
                      end: const Alignment(0.6, 0.8),
                      colors: [
                        Colors.white.withOpacity(0.14),
                        Colors.transparent,
                        Colors.black.withOpacity(0.06),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          AppBrand.name.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.72),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.2,
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
                              Icon(
                                Icons.workspace_premium_rounded,
                                color: Colors.white.withOpacity(0.95),
                                size: 13,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${userData['rewardsTier']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
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
                        GestureDetector(
                          onTap: _changeAvatar,
                          child: Stack(
                            alignment: Alignment.center,
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
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.18),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: (userData['photoUrl'] as String)
                                          .isNotEmpty
                                      ? Image.network(
                                          userData['photoUrl'] as String,
                                          width: 76,
                                          height: 76,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Center(
                                            child: Text(
                                              _initials,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 28,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: -0.6,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            _initials,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 28,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.6,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              if (_uploadingPhoto)
                                Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withOpacity(0.45),
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: AppColors.accentGold,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userData['name'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                userData['email'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.78),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(
                                    Icons.coffee_rounded,
                                    size: 14,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Usual · ${userData['favoriteOrder']}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.88),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
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
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.18),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _heroStat(
                              '${userData['rewardsPoints']}',
                              'Points',
                            ),
                          ),
                          _heroDivider(),
                          Expanded(
                            child: _heroStat(
                              '${recentOrders.length}',
                              'Orders',
                            ),
                          ),
                          _heroDivider(),
                          Expanded(
                            child: _heroStat(_memberYear, 'Since'),
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
    );
  }

  Widget _heroDivider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white.withOpacity(0.2),
    );
  }

  Widget _heroStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.72),
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: AppColors.textLight.withOpacity(0.85),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.15,
      ),
    );
  }

  Widget _menuGroup(List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.border()),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _menuRow(items[i]),
            if (i < items.length - 1)
              Divider(
                height: 1,
                indent: 56,
                endIndent: 16,
                color: AppColors.border(0.14),
              ),
          ],
        ],
      ),
    );
  }

  Widget _menuRow(_MenuItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(AppRadii.xl),
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
                child: Icon(item.icon, color: AppColors.primaryBrown, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textLight.withOpacity(0.55),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _aboutLink(String title, VoidCallback onTap, {bool isLast = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          bottom: isLast ? const Radius.circular(AppRadii.xl) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textLight.withOpacity(0.65),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _confirmLogout,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBrown,
          side: BorderSide(color: AppColors.border(0.35)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
        child: const Text(
          'Log out',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
}
