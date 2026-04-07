import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:afyalink/core/theme.dart';
import '../../data/repositories/notification_repository.dart';
import '../pages/notification_page.dart';

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCountAsync = ref.watch(unreadNotificationsCountProvider);

    return unreadCountAsync.when(
      data: (count) => Stack(
        children: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NotificationPage()),
            ),
            icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.primaryTeal),
          ),
          if (count > 0)
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      loading: () => const IconButton(
        onPressed: null,
        icon: Icon(Icons.notifications_none_rounded, color: Colors.grey),
      ),
      error: (_, __) => IconButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NotificationPage()),
        ),
        icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.primaryTeal),
      ),
    );
  }
}
