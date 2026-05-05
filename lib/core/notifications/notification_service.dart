import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../firebase_options.dart';
import 'notification_models.dart';

/// Background message handler — must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Background messages are automatically shown by the system
  // We store them locally when the app opens via [NotificationService.syncPending]
}


class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  // Stream for notification taps → carries payload for routing
  final StreamController<AppNotification> _tapController =
      StreamController<AppNotification>.broadcast();
  Stream<AppNotification> get onNotificationTap => _tapController.stream;

  // Stream for new foreground notifications
  final StreamController<AppNotification> _newNotifController =
      StreamController<AppNotification>.broadcast();
  Stream<AppNotification> get onNewNotification => _newNotifController.stream;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  static const _channelId = 'afyalink_channel';
  static const _channelName = 'AfyaLink Notifications';
  static const _channelDesc = 'Notifications for orders, health tips, and more';

  Future<void> initialize() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Create Android notification channel
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Init local notifications
    const initAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initDarwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: initAndroid,
      iOS: initDarwin,
      macOS: initDarwin,
    );
    await _localNotif.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        final payload = details.payload;
        if (payload != null) {
          try {
            final notif = AppNotification.fromJsonString(payload);
            _tapController.add(notif);
          } catch (_) {}
        }
      },
    );

    // Request permission
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Get & cache FCM token
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await _fcm.getAPNSToken();
        if (apnsToken != null) {
          _fcmToken = await _fcm.getToken();
        } else {
          if (kDebugMode) print('[FCM] APNS token not yet available. Skipping FCM token retrieval.');
        }
      } else {
        _fcmToken = await _fcm.getToken();
      }
      if (kDebugMode && _fcmToken != null) print('[FCM] Token: $_fcmToken');
    } catch (e) {
      if (kDebugMode) print('[FCM] Error getting token: $e');
    }

    // Listen for token refreshes
    _fcm.onTokenRefresh.listen((token) {
      _fcmToken = token;
      if (kDebugMode) print('[FCM] Token refreshed: $token');
    });

    // ── Foreground messages ────────────────────────────────────────────────
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notif = _fromRemoteMessage(message);
      _newNotifController.add(notif);
      _showLocalNotification(notif);
    });

    // ── App opened from notification (background → foreground) ────────────
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final notif = _fromRemoteMessage(message);
      _tapController.add(notif);
      _newNotifController.add(notif);
    });

    // ── App launched from terminated state via notification ───────────────
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      final notif = _fromRemoteMessage(initial);
      // Slight delay so the app tree is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        _tapController.add(notif);
        _newNotifController.add(notif);
      });
    }
  }

  // ── Show a local notification (for foreground messages) ──────────────────
  Future<void> _showLocalNotification(AppNotification notif) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      ticker: notif.title,
      styleInformation: BigTextStyleInformation(notif.body),
      icon: '@mipmap/ic_launcher',
    );

    await _localNotif.show(
      notif.id.hashCode,
      notif.title,
      notif.body,
      NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: notif.toJsonString(),
    );
  }

  // ── Convert FCM RemoteMessage → AppNotification ──────────────────────────
  AppNotification _fromRemoteMessage(RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;
    final type = NotificationTypeX.fromKey(data['type'] as String?);

    return AppNotification(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: notification?.title ?? data['title'] as String? ?? 'AfyaLink',
      body: notification?.body ?? data['body'] as String? ?? '',
      type: type,
      timestamp: message.sentTime ?? DateTime.now(),
      isRead: false,
      payload: data.isNotEmpty ? jsonEncode(data) : null,
    );
  }

  void dispose() {
    _tapController.close();
    _newNotifController.close();
  }
}
