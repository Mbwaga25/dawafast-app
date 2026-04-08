import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/notifications/notification_models.dart';
import '../../../../../core/notifications/notification_provider.dart';
import '../../../../../core/theme.dart';
import '../widgets/notification_card.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage>
    with SingleTickerProviderStateMixin {
  NotificationType? _selectedFilter;
  late AnimationController _emptyAnim;
  late Animation<double> _emptyFade;

  @override
  void initState() {
    super.initState();
    _emptyAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _emptyFade = CurvedAnimation(parent: _emptyAnim, curve: Curves.easeIn);
    _emptyAnim.forward();
  }

  @override
  void dispose() {
    _emptyAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allNotifs = ref.watch(notificationProvider);
    final unreadCount = ref.watch(unreadCountProvider);

    final filtered = _selectedFilter == null
        ? allNotifs
        : allNotifs.where((n) => n.type == _selectedFilter).toList();

    // Group notifications
    final grouped = _groupByDate(filtered);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: AppTheme.borderColor,
        title: Row(
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () => ref.read(notificationProvider.notifier).markAllRead(),
              child: const Text(
                'Mark all read',
                style: TextStyle(color: AppTheme.primaryBlue, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          if (allNotifs.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
              onSelected: (val) {
                if (val == 'clear') {
                  _confirmClear(context);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_outlined, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Clear all'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Filter Chips ────────────────────────────────────────────────────
          _buildFilterChips(),

          // ── Notification List ────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _countItems(grouped),
                    itemBuilder: (context, index) {
                      return _buildItem(grouped, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      (null, 'All', Icons.apps_outlined),
      (NotificationType.orderUpdate, 'Orders', Icons.receipt_long_outlined),
      (NotificationType.promo, 'Offers', Icons.local_offer_outlined),
      (NotificationType.healthTip, 'Health', Icons.favorite_outline),
      (NotificationType.doctorMessage, 'Doctors', Icons.video_call_outlined),
      (NotificationType.labResult, 'Lab', Icons.biotech_outlined),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isSelected = _selectedFilter == f.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: FilterChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(f.$3, size: 14,
                          color: isSelected ? Colors.white : AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(f.$2),
                    ],
                  ),
                  onSelected: (_) => setState(() => _selectedFilter = f.$1),
                  selectedColor: AppTheme.primaryBlue,
                  backgroundColor: const Color(0xFFF0F4FF),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? AppTheme.primaryBlue : AppTheme.borderColor,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Group notifications by date label ────────────────────────────────────────
  Map<String, List<AppNotification>> _groupByDate(List<AppNotification> notifs) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<AppNotification>> grouped = {};
    for (final n in notifs) {
      final d = DateTime(n.timestamp.year, n.timestamp.month, n.timestamp.day);
      String label;
      if (d == today) {
        label = 'Today';
      } else if (d == yesterday) {
        label = 'Yesterday';
      } else {
        label = 'Earlier';
      }
      grouped.putIfAbsent(label, () => []).add(n);
    }
    return grouped;
  }

  int _countItems(Map<String, List<AppNotification>> grouped) {
    int count = 0;
    for (final entry in grouped.entries) {
      count += 1 + entry.value.length; // header + items
    }
    return count;
  }

  Widget _buildItem(Map<String, List<AppNotification>> grouped, int index) {
    int i = 0;
    for (final entry in grouped.entries) {
      if (i == index) return _buildDateHeader(entry.key, entry.value.length);
      i++;
      for (final notif in entry.value) {
        if (i == index) {
          return NotificationCard(
            notification: notif,
            onTap: () => _handleTap(notif),
          );
        }
        i++;
      }
    }
    return const SizedBox.shrink();
  }

  Widget _buildDateHeader(String label, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppTheme.borderColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _emptyFade,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_none_outlined,
                  size: 52,
                  color: AppTheme.primaryBlue.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "You're all caught up!",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedFilter == null
                    ? 'No notifications yet. We\'ll let you know\nwhen something important happens.'
                    : 'No notifications in this category.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap(AppNotification notif) {
    // Route based on type
    switch (notif.type) {
      case NotificationType.orderUpdate:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening your orders...')),
        );
        break;
      case NotificationType.doctorMessage:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening telemedicine...')),
        );
        break;
      case NotificationType.labResult:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening lab results...')),
        );
        break;
      default:
        break;
    }
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear all notifications?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('This will permanently delete all your notifications.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () {
              ref.read(notificationProvider.notifier).clearAll();
              Navigator.pop(context);
            },
            child: const Text('Clear all', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
