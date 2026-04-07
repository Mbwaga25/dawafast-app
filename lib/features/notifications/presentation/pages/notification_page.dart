import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme.dart';
import 'package:app/features/notifications/data/repositories/notification_repository.dart';
import 'package:app/features/notifications/data/models/notification_model.dart';
import 'package:app/features/appointments/presentation/pages/chat_page.dart';

class NotificationPage extends ConsumerWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryTeal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No notifications yet', style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            );
          }
          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final n = notifications[index];
              return _NotificationTile(notification: n);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading notifications: $err')),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final AppNotification notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: notification.isRead ? Colors.transparent : Colors.blue.withOpacity(0.05),
      child: ListTile(
        onTap: () {
          ref.read(notificationRepositoryProvider).markAsRead(notification.id);
          ref.invalidate(notificationsProvider(null));
          ref.invalidate(unreadNotificationsCountProvider);

          if (notification.appointmentId != null) {
             Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(appointmentId: notification.appointmentId!)));
          }
        },
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor().withOpacity(0.1),
          child: Icon(_getCategoryIcon(), color: _getCategoryColor(), size: 20),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Text(notification.timeAgo, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  IconData _getCategoryIcon() {
    switch (notification.type.toUpperCase()) {
      case 'CHAT': return Icons.chat_outlined;
      case 'APPOINTMENT': return Icons.calendar_today;
      case 'REFERRAL': return Icons.forward;
      default: return Icons.info_outline;
    }
  }

  Color _getCategoryColor() {
    switch (notification.type.toUpperCase()) {
      case 'CHAT': return Colors.blue;
      case 'APPOINTMENT': return Colors.green;
      case 'REFERRAL': return Colors.orange;
      default: return Colors.blueGrey;
    }
  }
}
