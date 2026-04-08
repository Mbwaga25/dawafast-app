import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/notifications/notification_models.dart';
import '../../../../../core/notifications/notification_provider.dart';
import '../../../../../core/theme.dart';

class NotificationCard extends ConsumerWidget {
  final AppNotification notification;
  final VoidCallback? onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = _getTypeConfig(notification.type);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 26),
            SizedBox(height: 4),
            Text('Delete', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      onDismissed: (_) {
        ref.read(notificationProvider.notifier).deleteNotification(notification.id);
      },
      child: GestureDetector(
        onTap: () {
          ref.read(notificationProvider.notifier).markRead(notification.id);
          onTap?.call();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.white : config.bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: notification.isRead
                  ? AppTheme.borderColor
                  : config.accentColor.withOpacity(0.35),
              width: notification.isRead ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon circle
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: config.accentColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(config.icon, color: config.accentColor, size: 22),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 6),
                              decoration: BoxDecoration(
                                color: config.accentColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: config.accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              config.label,
                              style: TextStyle(
                                fontSize: 10,
                                color: config.accentColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _timeAgo(notification.timestamp),
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─── Type configurations ──────────────────────────────────────────────────────
class _TypeConfig {
  final IconData icon;
  final Color accentColor;
  final Color bgColor;
  final String label;
  const _TypeConfig({
    required this.icon,
    required this.accentColor,
    required this.bgColor,
    required this.label,
  });
}

_TypeConfig _getTypeConfig(NotificationType type) {
  switch (type) {
    case NotificationType.orderUpdate:
      return const _TypeConfig(
        icon: Icons.receipt_long_outlined,
        accentColor: Color(0xFF1565C0),
        bgColor: Color(0xFFE3F2FD),
        label: 'Order',
      );
    case NotificationType.promo:
      return const _TypeConfig(
        icon: Icons.local_offer_outlined,
        accentColor: Color(0xFFE65100),
        bgColor: Color(0xFFFFF3E0),
        label: 'Offer',
      );
    case NotificationType.healthTip:
      return const _TypeConfig(
        icon: Icons.favorite_outline,
        accentColor: Color(0xFF2E7D32),
        bgColor: Color(0xFFE8F5E9),
        label: 'Health',
      );
    case NotificationType.doctorMessage:
      return const _TypeConfig(
        icon: Icons.video_call_outlined,
        accentColor: Color(0xFF6A1B9A),
        bgColor: Color(0xFFF3E5F5),
        label: 'Doctor',
      );
    case NotificationType.labResult:
      return const _TypeConfig(
        icon: Icons.biotech_outlined,
        accentColor: Color(0xFF00695C),
        bgColor: Color(0xFFE0F2F1),
        label: 'Lab Result',
      );
    case NotificationType.system:
      return const _TypeConfig(
        icon: Icons.notifications_outlined,
        accentColor: Color(0xFF546E7A),
        bgColor: Color(0xFFECEFF1),
        label: 'System',
      );
  }
}
