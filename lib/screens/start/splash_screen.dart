import 'package:beanbloss/services/notification_service.dart';
import 'package:beanbloss/services/order_service.dart';
import 'package:beanbloss/services/product_service.dart';
import 'package:beanbloss/services/user_service.dart';
import 'package:beanbloss/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../HomeScreens/home_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback? onAnimationComplete;

  const SplashScreen({Key? key, this.onAnimationComplete}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _steamController;
  late AnimationController _bloomController;
  late AnimationController _textController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _steamOpacity;
  late Animation<double> _steamHeight;
  late Animation<double> _bloomScale;
  late Animation<double> _bloomRotation;
  late Animation<double> _textOpacity;
  late Animation<double> _textSlide;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _steamController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _bloomController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Setup animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _steamOpacity = Tween<double>(begin: 0.0, end: 0.8).animate(
      CurvedAnimation(parent: _steamController, curve: const Interval(0.0, 0.7)),
    );

    _steamHeight = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _steamController, curve: Curves.easeOut),
    );

    _bloomScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bloomController, curve: Curves.elasticOut),
    );

    _bloomRotation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _bloomController, curve: Curves.easeInOut),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    _textSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _fadeController.forward();

    await Future.delayed(const Duration(milliseconds: 800));
    _steamController.forward();

    await Future.delayed(const Duration(milliseconds: 1200));
    _bloomController.forward();

    await Future.delayed(const Duration(milliseconds: 800));
    _textController.forward();

    await Future.delayed(const Duration(milliseconds: 2000));

    // Fade out
    _fadeController.reverse();
    await Future.delayed(const Duration(milliseconds: 500));

    if (widget.onAnimationComplete != null) {
      widget.onAnimationComplete!();
    }
    if (!mounted) return;
    final signedIn = FirebaseAuth.instance.currentUser != null;
    if (signedIn) {
      try {
        await UserService.instance.loadCurrentUser(forceRefresh: true);
      } catch (_) {
        // Continue to Home even if profile fetch fails (offline, etc.).
      }
      try {
        await ProductService.instance.loadProducts();
      } catch (_) {
        // Menu falls back to local seed inside ProductService.
      }
      try {
        await OrderService.instance.loadActiveOrder();
      } catch (_) {
        // Track can load again later.
      }
      try {
        await NotificationService.instance.requestPermissionAndSyncToken();
      } catch (_) {
        // Notifications are optional.
      }
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            signedIn ? const HomeScreen() : const OnboardingScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _steamController.dispose();
    _bloomController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryBg,
              AppColors.primaryBg.withOpacity(0.96),
              const Color(0xFFEDE4D8),
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _fadeController,
            _steamController,
            _bloomController,
            _textController,
          ]),
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo area
                    SizedBox(
                      width: 200,
                      height: 250,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Coffee cup
                          Positioned(
                            bottom: 30,
                            child: _buildCoffeeCup(),
                          ),

                          // Steam
                          Positioned(
                            bottom: 95,
                            child: _buildSteam(),
                          ),

                          // Blooming flower
                          Positioned(
                            top: 0,
                            child: Transform.scale(
                              scale: _bloomScale.value,
                              child: Transform.rotate(
                                angle: _bloomRotation.value,
                                child: _buildFlower(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // App name
                    Transform.translate(
                      offset: Offset(0, _textSlide.value),
                      child: Opacity(
                        opacity: _textOpacity.value,
                        child: const Text(
                          AppBrand.name,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBrown,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Tagline
                    Transform.translate(
                      offset: Offset(0, _textSlide.value),
                      child: Opacity(
                        opacity: _textOpacity.value * 0.8,
                        child: const Text(
                          AppBrand.tagline,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textLight,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCoffeeCup() {
    return Container(
      width: 80,
      height: 100,
      child: CustomPaint(
        painter: CoffeeCupPainter(),
      ),
    );
  }

  Widget _buildSteam() {
    return Opacity(
      opacity: _steamOpacity.value,
      child: Container(
        width: 60,
        height: 120 * _steamHeight.value,
        child: CustomPaint(
          painter: SteamPainter(_steamController.value),
        ),
      ),
    );
  }

  Widget _buildFlower() {
    return Container(
      width: 100,
      height: 100,
      child: CustomPaint(
        painter: FlowerPainter(),
      ),
    );
  }
}

class CoffeeCupPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Cup body gradient
    final cupRect = Rect.fromLTWH(10, 20, size.width - 20, size.height - 30);
    final cupGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF8B4513), // Saddle brown
        const Color(0xFF6B4423), // Dark brown
      ],
    );
    paint.shader = cupGradient.createShader(cupRect);

    // Draw cup body
    final cupPath = Path()
      ..moveTo(15, 25)
      ..lineTo(size.width - 15, 25)
      ..lineTo(size.width - 25, size.height - 10)
      ..lineTo(25, size.height - 10)
      ..close();
    canvas.drawPath(cupPath, paint);

    // Cup handle
    paint.shader = null;
    paint.color = const Color(0xFF6B4423);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 4;

    final handlePath = Path()
      ..moveTo(size.width - 10, 35)
      ..quadraticBezierTo(size.width + 10, 45, size.width - 5, 65);
    canvas.drawPath(handlePath, paint);

    // Coffee surface
    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFF3C1810); // Very dark brown
    final coffeeEllipse = Rect.fromLTWH(12, 22, size.width - 24, 12);
    canvas.drawOval(coffeeEllipse, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class SteamPainter extends CustomPainter {
  final double animationValue;

  SteamPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE8DDD4).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Draw wavy steam lines
    for (int i = 0; i < 3; i++) {
      final path = Path();
      final startX = (size.width / 4) + (i * size.width / 6);
      final waveHeight = size.height * animationValue;

      path.moveTo(startX, size.height);

      for (double y = size.height; y > size.height - waveHeight; y -= 10) {
        final waveOffset = math.sin((y / 20) + (animationValue * 2 * math.pi) + (i * 0.5)) * 8;
        path.lineTo(startX + waveOffset, y);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(SteamPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

class FlowerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Flower petals
    final petalPaint = Paint()
      ..style = PaintingStyle.fill;

    // Petal colors - soft blush pinks
    final petalColors = [
      const Color(0xFFE8B4CB), // Soft pink
      const Color(0xFFD4A5A5), // Dusty rose
      const Color(0xFFC19A6B), // Light brown-pink
    ];

    // Draw 5 petals
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi / 5) - math.pi / 2;
      petalPaint.color = petalColors[i % petalColors.length];

      final petalPath = Path();
      final petalLength = 35.0;
      final petalWidth = 20.0;

      final petalTip = Offset(
        center.dx + math.cos(angle) * petalLength,
        center.dy + math.sin(angle) * petalLength,
      );

      final leftControl = Offset(
        center.dx + math.cos(angle - 0.5) * (petalLength * 0.7),
        center.dy + math.sin(angle - 0.5) * (petalLength * 0.7),
      );

      final rightControl = Offset(
        center.dx + math.cos(angle + 0.5) * (petalLength * 0.7),
        center.dy + math.sin(angle + 0.5) * (petalLength * 0.7),
      );

      petalPath.moveTo(center.dx, center.dy);
      petalPath.quadraticBezierTo(leftControl.dx, leftControl.dy, petalTip.dx, petalTip.dy);
      petalPath.quadraticBezierTo(rightControl.dx, rightControl.dy, center.dx, center.dy);

      canvas.drawPath(petalPath, petalPaint);
    }

    // Flower center
    final centerPaint = Paint()
      ..color = const Color(0xFFD4A574) // Warm golden center
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 8, centerPaint);

    // Small details in center
    final detailPaint = Paint()
      ..color = const Color(0xFF8B6B47)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final detailOffset = Offset(
        center.dx + math.cos(angle) * 4,
        center.dy + math.sin(angle) * 4,
      );
      canvas.drawCircle(detailOffset, 1.5, detailPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
