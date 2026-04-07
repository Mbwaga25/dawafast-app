import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/healthcare/presentation/pages/meeting_page.dart';

import 'core/services/notification_service.dart';

import 'package:graphql_flutter/graphql_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHiveForFlutter();
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize notification ring polling
    ref.watch(backgroundPollingProvider);

    return MaterialApp(
      title: 'AfyaLink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomePage(),
      onGenerateRoute: (settings) {
        if (settings.name != null && settings.name!.startsWith('/meeting/')) {
          final id = settings.name!.replaceFirst('/meeting/', '');
          return MaterialPageRoute(
            builder: (_) => MeetingPage(appointmentId: id),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}

