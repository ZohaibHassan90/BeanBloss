import 'package:beanbloss/services/auth_service.dart';
import 'package:beanbloss/services/notification_service.dart';
import 'package:beanbloss/theme/app_colors.dart';
import 'package:beanbloss/utils/responsive.dart';
import 'package:beanbloss/widgets/app_buttons.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../HomeScreens/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _controller = PageController();
  late AnimationController _animationController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool isLastPage = false;
  int currentPage = 0;

  final List<OnboardingItem> items = [
    OnboardingItem(
      title: 'Discover Premium Coffee',
      description:
          'Explore our carefully curated selection of artisanal coffee beans from around the world',
      icon: Icons.coffee_outlined,
      backgroundColor: AppColors.primaryBrown,
      textColor: Colors.white,
      highlightColor: AppColors.accentGold,
    ),
    OnboardingItem(
      title: 'Order with Ease',
      description:
          'Skip the wait with our seamless mobile ordering experience and pickup notifications',
      icon: Icons.shopping_cart_outlined,
      backgroundColor: AppColors.accentGold,
      textColor: AppColors.textDark,
      highlightColor: AppColors.primaryBrown,
    ),
    OnboardingItem(
      title: 'Earn & Indulge',
      description:
          'Get rewarded for every sip with our exclusive loyalty program and special offers',
      icon: Icons.star_outline,
      backgroundColor: AppColors.lightBrown,
      textColor: Colors.white,
      highlightColor: AppColors.accentGold,
    ),
    OnboardingItem(
      title: 'Coffee Culture',
      description:
          'Join our community of coffee enthusiasts and connect with master baristas worldwide',
      icon: Icons.people_outline,
      backgroundColor: const Color(0xFF654321),
      textColor: Colors.white,
      highlightColor: AppColors.accentGold,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );

    _animationController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      currentPage = index;
      isLastPage = index == items.length - 1;
    });
    _animationController.reset();
    _slideController.reset();
    _animationController.forward();
    _slideController.forward();
  }

  void _navigateToAuth() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AuthScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              items[currentPage].backgroundColor,
              items[currentPage].backgroundColor.withOpacity(0.85),
              items[currentPage].backgroundColor.withOpacity(0.7),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: items[currentPage].highlightColor.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.15,
              left: -60,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: items[currentPage].highlightColor.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -120,
              left: -120,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: items[currentPage].highlightColor.withOpacity(0.03),
                ),
              ),
            ),
            ...List.generate(
              12,
              (index) => _buildCoffeeBean(index, screenWidth, screenHeight),
            ),
            PageView.builder(
              controller: _controller,
              onPageChanged: _onPageChanged,
              itemCount: items.length,
              itemBuilder: (context, index) {
                return OnboardingPage(
                  item: items[index],
                  fadeAnimation: _fadeAnimation,
                  slideAnimation: _slideAnimation,
                  screenHeight: screenHeight,
                );
              },
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(28),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SmoothPageIndicator(
                        controller: _controller,
                        count: items.length,
                        effect: WormEffect(
                          dotColor: AppColors.textLight.withOpacity(0.3),
                          activeDotColor: items[currentPage].backgroundColor,
                          dotHeight: 12,
                          dotWidth: 12,
                          spacing: 20,
                          radius: 10,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      items[currentPage].backgroundColor,
                                  foregroundColor:
                                      items[currentPage].textColor,
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadii.md),
                                  ),
                                ),
                                onPressed: () {
                                  if (isLastPage) {
                                    _navigateToAuth();
                                  } else {
                                    _controller.nextPage(
                                      duration:
                                          const Duration(milliseconds: 500),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      isLastPage ? 'Get Started' : 'Next',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: items[currentPage].textColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      isLastPage
                                          ? Icons.rocket_launch_rounded
                                          : Icons.arrow_forward_rounded,
                                      color: items[currentPage].textColor,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (!isLastPage) ...[
                            const SizedBox(width: 16),
                            AppLinkButton(
                              label: 'Skip',
                              secondary: true,
                              onPressed: () {
                                _controller.animateToPage(
                                  items.length - 1,
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                          ],
                        ],
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

  Widget _buildCoffeeBean(int index, double screenWidth, double screenHeight) {
    final random = (index * 47) % 100;
    final left = (random % 80) * screenWidth / 100;
    final top = ((random * 13) % 60) * screenHeight / 100;
    final size = 3.0 + (random % 4);
    final opacity = 0.1 + (random % 20) / 100;

    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: items[currentPage].highlightColor.withOpacity(opacity),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final Color highlightColor;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.highlightColor,
  });
}

class OnboardingPage extends StatelessWidget {
  final OnboardingItem item;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;
  final double screenHeight;

  const OnboardingPage({
    Key? key,
    required this.item,
    required this.fadeAnimation,
    required this.slideAnimation,
    required this.screenHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 220),
        child: FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: item.highlightColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: item.highlightColor.withOpacity(0.35),
                    ),
                  ),
                  child: Icon(
                    item.icon,
                    size: 70,
                    color: item.highlightColor,
                  ),
                ),
                const SizedBox(height: 60),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: item.textColor,
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 17,
                          color: item.textColor.withOpacity(0.85),
                          height: 1.6,
                          letterSpacing: 0.2,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  bool isSignIn = true;
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return 'Password must contain uppercase, lowercase and number';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  void _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (!isSignIn && !_acceptTerms) {
        _showErrorSnackBar('Please accept the terms and conditions');
        return;
      }

      setState(() => _isLoading = true);

      try {
        if (isSignIn) {
          await AuthService.instance.signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
        } else {
          await AuthService.instance.signUp(
            email: _emailController.text,
            password: _passwordController.text,
            name: _nameController.text,
          );
        }

        if (mounted) {
          setState(() => _isLoading = false);
          // Best-effort: save FCM token for order alerts.
          // ignore: unawaited_futures
          NotificationService.instance.requestPermissionAndSyncToken();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (_) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showErrorSnackBar(AuthService.messageFor(e));
        }
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.destructive,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primaryBrown,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: r.formMaxWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: r.pagePadding),
                  child: Column(
                    children: [
                      const SizedBox(height: 4),
                      _buildHeader(),
                      const SizedBox(height: 16),
                      Expanded(
                        child: isSignIn
                            ? LayoutBuilder(
                                builder: (context, constraints) {
                                  return Align(
                                    alignment: Alignment.topCenter,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.topCenter,
                                      child: SizedBox(
                                        width: constraints.maxWidth,
                                        child: _buildAuthCard(dense: true),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.only(bottom: 20),
                                child: _buildAuthCard(dense: false),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        SizedBox(
          // Tight around the cup so Sign In fits without overflow;
          // cup size itself stays 120×80.
          height: 148,
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              ...List.generate(15, (index) => _buildCoffeeBean(index)),
              Container(
                height: 120,
                width: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryBrown,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border(0.35)),
                ),
                child: const Icon(
                  Icons.local_cafe,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          AppBrand.name,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isSignIn ? 'Welcome back!' : 'Join our community',
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textLight,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCoffeeBean(int index) {
    final random = (index * 37) % 100;
    final left = (random % 80) + 10.0;
    final top = ((random * 7) % 50) + 12.0;
    final size = 4.0 + (random % 3);

    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.primaryBrown.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildAuthCard({required bool dense}) {
    final pad = dense ? 20.0 : 28.0;
    final sectionGap = dense ? 18.0 : 32.0;
    final fieldGap = dense ? 14.0 : 20.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(pad, pad, pad, dense ? 18 : 24),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        border: Border.all(color: AppColors.border(0.2)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildToggleButtons(),
            SizedBox(height: sectionGap),
            if (!isSignIn) ...[
              _buildInputField(
                controller: _nameController,
                label: 'Full Name',
                hint: 'Enter your full name',
                icon: Icons.person_outline_rounded,
                validator: _validateName,
              ),
              SizedBox(height: fieldGap),
            ],
            _buildInputField(
              controller: _emailController,
              label: 'Email Address',
              hint: 'Enter your email',
              icon: Icons.email_outlined,
              validator: _validateEmail,
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: fieldGap),
            _buildInputField(
              controller: _passwordController,
              label: 'Password',
              hint: 'Enter your password',
              icon: Icons.lock_outline_rounded,
              validator: _validatePassword,
              isPassword: true,
              obscureText: _obscurePassword,
              onToggleVisibility: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            if (!isSignIn) ...[
              SizedBox(height: fieldGap),
              _buildInputField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                hint: 'Confirm your password',
                icon: Icons.lock_outline_rounded,
                validator: _validateConfirmPassword,
                isPassword: true,
                obscureText: _obscureConfirmPassword,
                onToggleVisibility: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
              ),
              const SizedBox(height: 20),
              _buildTermsCheckbox(),
            ],
            SizedBox(height: sectionGap),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.primaryBg,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.border(0.18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isSignIn = true),
              child: Container(
                decoration: BoxDecoration(
                  color: isSignIn ? AppColors.primaryBrown : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Center(
                  child: Text(
                    'Sign In',
                    style: TextStyle(
                      color: isSignIn ? Colors.white : AppColors.textLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isSignIn = false),
              child: Container(
                decoration: BoxDecoration(
                  color:
                      !isSignIn ? AppColors.primaryBrown : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Center(
                  child: Text(
                    'Sign Up',
                    style: TextStyle(
                      color: !isSignIn ? Colors.white : AppColors.textLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
  }) {
    final radius = BorderRadius.circular(AppRadii.md);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textDark,
            fontWeight: FontWeight.w500,
          ),
          cursorColor: AppColors.primaryBrown,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textLight.withOpacity(0.7)),
            prefixIcon: Icon(icon, color: AppColors.accentGold, size: 22),
            filled: true,
            fillColor: AppColors.cardBg,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: AppColors.border(0.22)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: AppColors.border(0.22)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(
                color: AppColors.accentGold,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(color: AppColors.destructive),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(
                color: AppColors.destructive,
                width: 1.5,
              ),
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textLight,
                      size: 22,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (value) => setState(() => _acceptTerms = value ?? false),
          activeColor: AppColors.accentGold,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text.rich(
              TextSpan(
                text: 'I agree to the ',
                style: const TextStyle(color: AppColors.textLight, fontSize: 14),
                children: [
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                      color: AppColors.accentGold,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: AppColors.accentGold,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit = !_isLoading && (isSignIn || _acceptTerms);
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: canSubmit ? _handleSubmit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBrown,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.textLight.withOpacity(0.25),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSignIn
                        ? Icons.login_rounded
                        : Icons.person_add_rounded,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isSignIn ? 'Sign In' : 'Create Account',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
