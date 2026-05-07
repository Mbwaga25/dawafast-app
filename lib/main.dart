import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'features/profile/data/repositories/settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'core/theme.dart';
import 'core/app_config.dart';
import 'core/api_client.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'core/notifications/notification_service.dart';
import 'core/notifications/notification_models.dart';
import 'firebase_options.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/notifications/presentation/pages/notifications_page.dart';
import 'core/router.dart';
import 'package:go_router/go_router.dart';

void main() async {
  debugPrint('[Main] Starting main()...');
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  debugPrint('[Main] WidgetsFlutterBinding initialized & Splash preserved.');

  try {
    // ── Firebase init ────────────────────────────────────────────────────────
    debugPrint('[Main] Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('[Main] Firebase initialized.');

    // ── Hive init for GraphQL ───────────────────────────────────────────────
    debugPrint('[Main] Initializing Hive...');
    await initHiveForFlutter();
    ApiClient.init();
    debugPrint('[Main] Hive and ApiClient initialized.');
    
    // ── Crashlytics init (skip on Web) ──────────────────────────────────────
    if (!kIsWeb) {
      debugPrint('[Main] Configuring Crashlytics...');
      FlutterError.onError = (errorDetails) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
      debugPrint('[Main] Crashlytics configured.');
    }

    // Initialize notifications without blocking launch
    debugPrint('[Main] Initializing NotificationService (async)...');
    NotificationService.instance.initialize();

    // ── Pre-fetch Map Settings (Non-blocking) ────────────────────────────────
    // We don't 'await' this here to avoid hanging the app if the network is slow.
    // Instead, we start the fetch and let the app proceed.
    final container = ProviderContainer();
    _fetchMapSettings(container);

    debugPrint('[Main] Running runApp...');
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const MyApp(),
      ),
    );
  } catch (e, stack) {
    debugPrint('[Main] CRITICAL ERROR during initialization: $e');
    debugPrint('[Main] Stack trace: $stack');
    // Even if something fails, try to run the app so it doesn't stay black
    runApp(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Something went wrong during startup.')),
          ),
        ),
      ),
    );
  } finally {
    // Remove splash screen after a small delay to ensure smooth transition
    Future.delayed(const Duration(milliseconds: 500), () {
      FlutterNativeSplash.remove();
    });
  }
}

/// Fetches map settings in the background and updates AppConfig
Future<void> _fetchMapSettings(ProviderContainer container) async {
  try {
    debugPrint('[Main] Background: Fetching Map Settings...');
    final mapSettings = await container.read(mapSettingsProvider.future);
    if (mapSettings != null) {
      AppConfig.updateTokens(
        mapboxToken: mapSettings.mapboxToken,
        googleMapsKey: mapSettings.googleMapsKey,
      );
      debugPrint('[Main] Background: Map Settings updated.');
    }
  } catch (e) {
    debugPrint('[Main] Background: Error fetching Map Settings: $e');
    // Falls back to local defaults automatically in AppConfig
  }
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
