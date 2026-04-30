import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'core/theme.dart';

import 'core/notifications/notification_service.dart';
import 'core/notifications/notification_models.dart';
import 'firebase_options.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/notifications/presentation/pages/notifications_page.dart';
import 'core/router.dart';
import 'package:go_router/go_router.dart';

// Global navigator key is now in core/router.dart
// final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase init ────────────────────────────────────────────────────────
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ── Hive init for GraphQL ───────────────────────────────────────────────
  await initHiveForFlutter();
  
  // ── Crashlytics init (skip on Web) ──────────────────────────────────────
  if (!kIsWeb) {
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  await NotificationService.instance.initialize();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Wire notification taps → routing
    NotificationService.instance.onNotificationTap.listen(_handleNotificationTap);
  }

  void _handleNotificationTap(AppNotification notif) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    switch (notif.type) {
      case NotificationType.orderUpdate:
        // TODO: navigate to Orders page
        _pushNotificationsPage(context);
        break;
      case NotificationType.doctorMessage:
        // TODO: navigate to Telemedicine page
        _pushNotificationsPage(context);
        break;
      case NotificationType.labResult:
        // TODO: navigate to Lab Results page
        _pushNotificationsPage(context);
        break;
      default:
        _pushNotificationsPage(context);
    }
  }

  void _pushNotificationsPage(BuildContext context) {
    context.push('/notifications');
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'AfyaLink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
