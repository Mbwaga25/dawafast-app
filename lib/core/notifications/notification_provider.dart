import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_models.dart';
import 'notification_service.dart';

const _kPrefsKey = 'afyalink_notifications';
const _kMaxStored = 100; // keep last 100 notifications

// ─── State Notifier ──────────────────────────────────────────────────────────
class NotificationNotifier extends StateNotifier<List<AppNotification>> {
  NotificationNotifier() : super([]) {
    _load();
    _subscribeToService();
  }

  StreamSubscription<AppNotification>? _sub;

  void _subscribeToService() {
    _sub = NotificationService.instance.onNewNotification.listen((notif) {
      addNotification(notif);
    });
  }

  // ── Persistence ────────────────────────────────────────────────────────────
  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kPrefsKey);
      if (raw != null) {
        final list = (jsonDecode(raw) as List)
            .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
            .toList();
        // Sort newest first
        list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        state = list;
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final limited = state.take(_kMaxStored).toList();
      await prefs.setString(
        _kPrefsKey,
        jsonEncode(limited.map((n) => n.toJson()).toList()),
      );
    } catch (_) {}
  }

  // ── Public API ──────────────────────────────────────────────────────────────
  void addNotification(AppNotification notif) {
    // Deduplicate by id
    final exists = state.any((n) => n.id == notif.id);
    if (exists) return;
    state = [notif, ...state];
    _save();
  }

  void markRead(String id) {
    state = state.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
    _save();
  }

  void markAllRead() {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
    _save();
  }

  void deleteNotification(String id) {
    state = state.where((n) => n.id != id).toList();
    _save();
  }

  void clearAll() {
    state = [];
    _save();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────
final notificationProvider =
    StateNotifierProvider<NotificationNotifier, List<AppNotification>>(
  (ref) => NotificationNotifier(),
);

final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).where((n) => !n.isRead).length;
});

final filteredNotificationsProvider =
    Provider.family<List<AppNotification>, NotificationType?>(
  (ref, type) {
    final all = ref.watch(notificationProvider);
    if (type == null) return all;
    return all.where((n) => n.type == type).toList();
  },
);
