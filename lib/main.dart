import 'package:beanbloss/firebase_options.dart';
import 'package:beanbloss/screens/start/splash_screen.dart';
import 'package:beanbloss/services/notification_service.dart';
import 'package:beanbloss/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BeanBloss',
      theme: AppTheme.light,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final shortest = media.size.shortestSide;
        final maxScale = shortest < 600 ? 1.15 : 1.08;
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: maxScale,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashScreen(),
    );
  }
}
