import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/notifications/data/repositories/notification_repository.dart';
import 'package:app/features/notifications/data/models/notification_model.dart';

final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService(ref);
  service.init();
  return service;
});

class NotificationService {
  final Ref ref;
  Timer? _pollingTimer;
  String? _lastNotificationId;

  NotificationService(this.ref);

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true);
            
    const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
        
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {},
    );

    // Request permissions for Android 13+
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Start background polling
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 8), (timer) async {
      _pollForNewNotifications();
    });
  }

  Future<void> _pollForNewNotifications() async {
    try {
      final repository = ref.read(notificationRepositoryProvider);
      final unreadNotifications = await repository.fetchNotifications(isRead: false);
      
      if (unreadNotifications.isNotEmpty) {
        // We only want to ring for the newest one to avoid spam
        final newest = unreadNotifications.first;
        if (newest.id != _lastNotificationId) {
          _lastNotificationId = newest.id;
          await _showHighPriorityNotification(newest);
          
          // Refresh global state so UI updates if open
          ref.invalidate(notificationsProvider);
        }
      }
    } catch (e) {
      // Ignore network polling errors
    }
  }

  Future<void> _showHighPriorityNotification(AppNotification notif) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'dawafast_urgent_channel_id',
      'Urgent Notifications',
      channelDescription: 'Used for important alerts like calls, orders, and messages.',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.call,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentSound: true,
      presentAlert: true,
      presentBadge: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics, iOS: iOSPlatformChannelSpecifics);

    final int notifId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    // Dynamic title/message formatting based on backend standardized types
    String displayTitle = "DawaFast Alert";
    final type = notif.type.toUpperCase();
    
    if (type.contains('APPOINTMENT')) {
      displayTitle = "📅 Appointment Update";
    } else if (type.contains('ORDER')) {
      displayTitle = "📦 Order Update";
    } else if (type.contains('REFERRAL')) {
      displayTitle = "🏥 Referral Received";
    } else if (type.contains('CHAT') || type.contains('MESSAGE')) {
      displayTitle = "💬 New Message";
    }

    await flutterLocalNotificationsPlugin.show(
      id: notifId,
      title: notif.title.isNotEmpty ? notif.title : displayTitle,
      body: notif.message,
      notificationDetails: platformChannelSpecifics,
      payload: notif.id,
    );
  }

  void dispose() {
    _pollingTimer?.cancel();
  }
}

// Global provider block to initialize polling app-wide
final backgroundPollingProvider = Provider<void>((ref) {
  ref.watch(notificationServiceProvider);
});
