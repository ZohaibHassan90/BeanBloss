import 'dart:io';

import 'package:beanbloss/firebase_options.dart';
import 'package:beanbloss/models/app_order.dart';
import 'package:beanbloss/services/user_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// FCM token registration + local notifications for order status.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();

  static const _channelId = 'beanbloss_orders';
  static const _channelName = 'Order updates';

  bool _ready = false;
  int _localId = 1000;

  Future<void> init() async {
    if (_ready) return;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    final androidPlugin = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'BeanBloss pickup order status updates',
        importance: Importance.high,
      ),
    );

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    _ready = true;
  }

  Future<void> requestPermissionAndSyncToken() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }

      if (Platform.isAndroid) {
        final androidPlugin = _local.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.requestNotificationsPermission();
      }

      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await UserService.instance.saveFcmToken(token);
      }

      _messaging.onTokenRefresh.listen((t) {
        UserService.instance.saveFcmToken(t);
      });
    } catch (e) {
      debugPrint('NotificationService permission/token: $e');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final title = message.notification?.title ??
        message.data['title'] ??
        'BeanBloss';
    final body = message.notification?.body ??
        message.data['body'] ??
        'You have a new update';
    showLocal(title: title, body: body);
  }

  Future<void> showLocal({
    required String title,
    required String body,
  }) async {
    if (!_ready) await init();
    await _local.show(
      _localId++,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'BeanBloss pickup order status updates',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> notifyOrderStatus({
    required String orderNumber,
    required OrderStatus status,
  }) async {
    final title = switch (status) {
      OrderStatus.received => 'Order placed',
      OrderStatus.preparing => 'Brewing your order',
      OrderStatus.almostReady => 'Almost ready',
      OrderStatus.ready => 'Ready for pickup!',
      OrderStatus.completed => 'Order complete',
      OrderStatus.cancelled => 'Order cancelled',
    };
    final body = switch (status) {
      OrderStatus.received =>
        '$orderNumber received · Pay at the counter when you collect.',
      OrderStatus.preparing => '$orderNumber is being prepared.',
      OrderStatus.almostReady => '$orderNumber is almost ready.',
      OrderStatus.ready =>
        '$orderNumber is ready · Show your ID and pay at pickup.',
      OrderStatus.completed => 'Thanks for visiting BeanBloss!',
      OrderStatus.cancelled => '$orderNumber was cancelled.',
    };
    await showLocal(title: title, body: body);
  }
}
