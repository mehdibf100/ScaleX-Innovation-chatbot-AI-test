// lib/services/notification_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('BG message received: ${message.messageId}, data: ${message.data}');
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  // NOTE: ne pas initialiser FirebaseMessaging ici (évite d'appeler Firebase.app trop tôt)
  late final FirebaseMessaging _fm;
  final FlutterLocalNotificationsPlugin _flnp = FlutterLocalNotificationsPlugin();

  String _channelId = 'high_importance_channel';
  String? _token;
  String? get token => _token;

  /// Appeler APRES `await Firebase.initializeApp()` dans main()
  Future<void> init({String androidChannelId = 'high_importance_channel'}) async {
    _channelId = androidChannelId;

    // maintenant on initialise FirebaseMessaging (après Firebase.initializeApp)
    _fm = FirebaseMessaging.instance;

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _initLocalNotifications(_channelId);
    await _requestPermissions();

    // token
    _token = await _fm.getToken();
    debugPrint('FCM token: $_token');

    // token refresh
    _fm.onTokenRefresh.listen((t) {
      _token = t;
      debugPrint('Token refreshed: $_token');
    });

    // optional: subscribe to a topic for console sending
    try {
      await _fm.subscribeToTopic('all');
      debugPrint('Subscribed to topic "all"');
    } catch (e) {
      debugPrint('subscribe to topic failed: $e');
    }

    _listen();
  }

  Future<void> _initLocalNotifications(String channelId) async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    final iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestProvisionalPermission: false,
      requestCriticalPermission: false,
      defaultPresentAlert: true,
      defaultPresentSound: true,
      defaultPresentBadge: true,
      defaultPresentBanner: true,
      defaultPresentList: true,
    );

    await _flnp.initialize(
      InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (NotificationResponse resp) {
        debugPrint('Local notification tapped, payload: ${resp.payload}');
      },
    );

    final channel = AndroidNotificationChannel(
      channelId,
      'High Importance Notifications',
      description: 'Used for important notifications',
      importance: Importance.max,
    );

    await _flnp
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _requestPermissions() async {
    // iOS
    final settings = await _fm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('iOS permission: ${settings.authorizationStatus}');

    if (Platform.isAndroid) {
      debugPrint(
          'Android: ensure <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/> is declared for Android 13+.');
    }
  }

  void _listen() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('onMessage (foreground): ${message.messageId}');
      _showLocalNotificationFromRemoteMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('onMessageOpenedApp: ${message.data}');
    });

    _fm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('App opened from terminated by message: ${message.data}');
      }
    });
  }

  Future<void> _showLocalNotificationFromRemoteMessage(RemoteMessage message) async {
    final RemoteNotification? n = message.notification;
    if (n == null) return;

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      'High Importance Notifications',
      channelDescription: 'Used for important notifications',
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(n.body ?? ''),
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );

    await _flnp.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      n.title,
      n.body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: message.data.isNotEmpty ? message.data.toString() : null,
    );
  }

  Future<void> showAiReply(String text, {String title = 'Réponse AI'}) async {
    if (text.trim().isEmpty) return;

    final body = text.trim();
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      'High Importance Notifications',
      channelDescription: 'Used for important notifications',
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(body),
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );

    await _flnp.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body.length > 256 ? '${body.substring(0, 253)}...' : body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: 'ai_reply',
    );
  }

  /// Utility
  Future<String?> refreshToken() async {
    _token = await _fm.getToken();
    debugPrint('Refreshed token: $_token');
    return _token;
  }

  Future<void> unsubscribeFromTopicAll() async {
    await _fm.unsubscribeFromTopic('all');
    debugPrint('Unsubscribed from topic all');
  }
}
