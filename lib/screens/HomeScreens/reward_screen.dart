import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:beanbloss/widgets/app_bottom_nav.dart';
import 'package:beanbloss/widgets/app_buttons.dart';
import 'package:beanbloss/widgets/app_fab.dart';
import 'package:beanbloss/widgets/app_page_header.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({Key? key}) : super(key: key);

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen>
    with TickerProviderStateMixin {

  late AnimationController _animationController;
  late AnimationController _cardController;
  late AnimationController _progressController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _cardAnimation;
  late Animation<double> _progressAnimation;

  int _currentPoints = 1250;
  int _pointsToNextReward = 250; // Points needed for next reward
  int _totalPointsForNextLevel = 1500;
  String _currentTier = 'Gold';
  String _nextTier = 'Platinum';

  // Consistent color scheme
  static const Color primaryBg = Color(0xFFF5F1EB);
  static const Color cardBg = Color(0xFFFFFBF7);
  static const Color primaryBrown = Color(0xFF8B4513);
  static const Color accentGold = Color(0xFFD4A574);
  static const Color textDark = Color(0xFF2C1810);
  static const Color textLight = Color(0xFF8B7355);
  static const Color lightBrown = Color(0xFFA0522D);

  final List<RewardItem> availableRewards = [
    RewardItem(
      title: 'Free Coffee',
      description: 'Any regular coffee of your choice',
      points: 500,
      icon: Icons.coffee_rounded,
      color: Colors.brown,
      isAvailable: true,
    ),
    RewardItem(
      title: 'Free Pastry',
      description: 'Choose any pastry from our selection',
      points: 300,
      icon: Icons.cake_rounded,
      color: Colors.orange,
      isAvailable: true,
    ),
    RewardItem(
      title: '20% Off Next Order',
      description: 'Discount on your entire next purchase',
      points: 750,
      icon: Icons.discount_rounded,
      color: Colors.green,
      isAvailable: true,
    ),
    RewardItem(
      title: 'Free Latte Upgrade',
      description: 'Upgrade any coffee to a latte',
      points: 400,
      icon: Icons.upgrade_rounded,
      color: Colors.blue,
      isAvailable: true,
    ),
    RewardItem(
      title: 'Free Extra Shot',
      description: 'Add an extra espresso shot for free',
      points: 200,
      icon: Icons.add_circle_rounded,
      color: Colors.purple,
      isAvailable: true,
    ),
    RewardItem(
      title: 'VIP Experience',
      description: 'Skip the line and priority service',
      points: 1000,
      icon: Icons.star_rounded,
      color: Colors.amber,
      isAvailable: false,
    ),
  ];

  final List<PointsHistory> pointsHistory = [
    PointsHistory(
      title: 'Purchase - Caramel Macchiato',
      points: 25,
      date: 'Today, 2:30 PM',
      type: PointsType.earned,
    ),
    PointsHistory(
      title: 'Redeemed - Free Coffee',
      points: -500,
      date: 'Yesterday, 10:15 AM',
      type: PointsType.redeemed,
    ),
    PointsHistory(
      title: 'Purchase - Chocolate Croissant',
      points: 15,
      date: 'Yesterday, 10:10 AM',
      type: PointsType.earned,
    ),
    PointsHistory(
      title: 'Bonus Points - Weekend Special',
      points: 100,
      date: '2 days ago',
      type: PointsType.bonus,
    ),
    PointsHistory(
      title: 'Purchase - Iced Americano',
      points: 20,
      date: '3 days ago',
      type: PointsType.earned,
    ),
  ];

  final List<TierBenefit> tierBenefits = [
    TierBenefit(
      title: 'Bronze Benefits',
      benefits: ['Earn 1 point per \$1', 'Birthday reward', 'Member-only offers'],
      color: Colors.brown.shade400,
    ),
    TierBenefit(
      title: 'Silver Benefits',
      benefits: ['Earn 1.25 points per \$1', 'Free drink on birthday', 'Early access to new products'],
      color: Colors.grey.shade400,
    ),
    TierBenefit(
      title: 'Gold Benefits',
      benefits: ['Earn 1.5 points per \$1', 'Free drink + pastry on birthday', 'Priority customer service'],
      color: accentGold,
    ),
    TierBenefit(
      title: 'Platinum Benefits',
      benefits: ['Earn 2 points per \$1', 'Monthly free drink', 'VIP events access', 'Personal barista'],
      color: Colors.grey.shade300,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setSystemUIStyle();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.elasticOut),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: _currentPoints / _totalPointsForNextLevel).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _cardController.forward();
    _progressController.forward();
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
    _animationController.dispose();
    _cardController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _redeemReward(RewardItem reward) {
    if (_currentPoints >= reward.points && reward.isAvailable) {
      setState(() {
        _currentPoints -= reward.points;
      });

      HapticFeedback.mediumImpact();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Reward Redeemed!'),
                    Text(
                      '${reward.title} - ${reward.points} points used',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: primaryBrown,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBg,
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
                    _buildRewardsCard(),
                    _buildQuickActions(),
                    _buildAvailableRewards(),
                    _buildPointsHistory(),
                    _buildTierBenefits(),
                    const SizedBox(height: 100), // Space for bottom nav
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: const AppCartFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }

  Widget _buildAppBar() {
    return AppSliverHeader(
      title: 'Rewards',
      subtitle: '$_currentPoints points · $_currentTier member',
      icon: Icons.card_giftcard_rounded,
      showBack: false,
      trailing: AppIconButton(
        icon: Icons.info_outline_rounded,
        onPressed: _showRewardsInfo,
      ),
    );
  }

  Widget _buildRewardsCard() {
    return ScaleTransition(
      scale: _cardAnimation,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryBrown,
              lightBrown,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accentGold.withOpacity(0.18)),
          boxShadow: [
            BoxShadow(
              color: primaryBrown.withOpacity(0.18),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Points',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentPoints.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: accentGold,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_currentTier Member',
                    style: TextStyle(
                      color: textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Progress to $_nextTier',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: _progressAnimation.value,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(accentGold),
                        minHeight: 8,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$_pointsToNextReward more',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.trending_up, color: accentGold, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Earning 1.5x points as $_currentTier member',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionCard(
              'Scan QR',
              Icons.qr_code_scanner_rounded,
              Colors.blue,
              () => _showActionSheet(
                title: 'Scan QR',
                body:
                    'Point your camera at the BeanBloss counter QR to earn bonus points after pickup.',
                actionLabel: 'Simulate scan',
                onAction: () {
                  setState(() => _currentPoints += 25);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('+25 points from QR scan'),
                      backgroundColor: primaryBrown,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionCard(
              'Refer Friend',
              Icons.person_add_rounded,
              Colors.green,
              () => _showActionSheet(
                title: 'Refer a friend',
                body:
                    'Share code BEANFRIEND. You both get 100 points when they place their first order.',
                actionLabel: 'Copy code',
                onAction: () {
                  Clipboard.setData(const ClipboardData(text: 'BEANFRIEND'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Referral code copied'),
                      backgroundColor: primaryBrown,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionCard(
              'Gift Points',
              Icons.card_giftcard_rounded,
              Colors.purple,
              () => _showActionSheet(
                title: 'Gift points',
                body:
                    'Send 100 points to a friend\'s BeanBloss account. You have $_currentPoints pts.',
                actionLabel: 'Gift 100 pts',
                onAction: () {
                  if (_currentPoints < 100) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Not enough points'),
                        backgroundColor: primaryBrown,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                    return;
                  }
                  setState(() => _currentPoints -= 100);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('100 points gifted'),
                      backgroundColor: primaryBrown,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showActionSheet({
    required String title,
    required String body,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: textLight.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: textDark,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(
                color: textLight,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  onAction();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBrown,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: textDark,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableRewards() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available Rewards',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppLinkButton(
                  label: 'View All',
                  onPressed: () {
                    // Show all rewards
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: availableRewards.length,
              itemBuilder: (context, index) {
                final reward = availableRewards[index];
                return _buildRewardCard(reward, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard(RewardItem reward, int index) {
    final canRedeem = _currentPoints >= reward.points && reward.isAvailable;

    return GestureDetector(
      onTap: canRedeem ? () => _redeemReward(reward) : null,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: canRedeem
                ? accentGold.withOpacity(0.45)
                : accentGold.withOpacity(0.18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: reward.color.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Center(
                child: Icon(
                  reward.icon,
                  color: reward.color,
                  size: 40,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reward.title,
                      style: TextStyle(
                        color: textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reward.description,
                      style: TextStyle(
                        color: textLight,
                        fontSize: 12,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: canRedeem ? accentGold.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${reward.points} pts',
                            style: TextStyle(
                              color: canRedeem ? primaryBrown : textLight,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (canRedeem)
                          Icon(Icons.check_circle, color: accentGold, size: 20)
                        else if (!reward.isAvailable)
                          Icon(Icons.lock, color: Colors.grey, size: 16),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsHistory() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Points History',
                style: TextStyle(
                  color: textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppLinkButton(
                label: 'View All',
                onPressed: () {
                  // Show full history
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...pointsHistory.take(5).map((history) => _buildHistoryItem(history)).toList(),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(PointsHistory history) {
    Color pointsColor;
    IconData icon;

    switch (history.type) {
      case PointsType.earned:
        pointsColor = Colors.green;
        icon = Icons.add_circle_rounded;
        break;
      case PointsType.redeemed:
        pointsColor = Colors.red;
        icon = Icons.remove_circle_rounded;
        break;
      case PointsType.bonus:
        pointsColor = accentGold;
        icon = Icons.star_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryBg.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: pointsColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: pointsColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  history.title,
                  style: TextStyle(
                    color: textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  history.date,
                  style: TextStyle(
                    color: textLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${history.points > 0 ? '+' : ''}${history.points}',
            style: TextStyle(
              color: pointsColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierBenefits() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Membership Tiers',
            style: TextStyle(
              color: textDark,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...tierBenefits.map((tier) => _buildTierCard(tier)).toList(),
        ],
      ),
    );
  }

  Widget _buildTierCard(TierBenefit tier) {
    final isCurrentTier = tier.title.contains(_currentTier);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentTier ? tier.color.withOpacity(0.1) : primaryBg.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: isCurrentTier ? Border.all(color: tier.color, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: tier.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                tier.title,
                style: TextStyle(
                  color: textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isCurrentTier) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: tier.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Current',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          ...tier.benefits.map((benefit) => Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 4),
            child: Row(
              children: [
                Icon(Icons.check, color: tier.color, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    benefit,
                    style: TextStyle(
                      color: textLight,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  void _showRewardsInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How Rewards Work',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildInfoItem(
                      Icons.coffee_rounded,
                      'Earn Points',
                      'Get points for every purchase. Higher tiers earn more points per dollar spent.',
                    ),
                    _buildInfoItem(
                      Icons.redeem_rounded,
                      'Redeem Rewards',
                      'Use your points to get free drinks, food, and exclusive perks.',
                    ),
                    _buildInfoItem(
                      Icons.trending_up_rounded,
                      'Level Up',
                      'Reach higher tiers for better benefits and exclusive rewards.',
                    ),
                    _buildInfoItem(
                      Icons.star_rounded,
                      'Special Offers',
                      'Get access to member-only promotions and early access to new products.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accentGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentGold, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: textLight,
                    fontSize: 14,
                    height: 1.4,
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

// Data Models
class RewardItem {
  final String title;
  final String description;
  final int points;
  final IconData icon;
  final Color color;
  final bool isAvailable;

  RewardItem({
    required this.title,
    required this.description,
    required this.points,
    required this.icon,
    required this.color,
    required this.isAvailable,
  });
}

class PointsHistory {
  final String title;
  final int points;
  final String date;
  final PointsType type;

  PointsHistory({
    required this.title,
    required this.points,
    required this.date,
    required this.type,
  });
}

enum PointsType { earned, redeemed, bonus }

class TierBenefit {
  final String title;
  final List<String> benefits;
  final Color color;

  TierBenefit({
    required this.title,
    required this.benefits,
    required this.color,
  });
}