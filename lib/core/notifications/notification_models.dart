import 'dart:convert';

enum NotificationType {
  orderUpdate,
  promo,
  healthTip,
  doctorMessage,
  labResult,
  system,
}

extension NotificationTypeX on NotificationType {
  String get key {
    switch (this) {
      case NotificationType.orderUpdate: return 'order_update';
      case NotificationType.promo: return 'promo';
      case NotificationType.healthTip: return 'health_tip';
      case NotificationType.doctorMessage: return 'doctor_message';
      case NotificationType.labResult: return 'lab_result';
      case NotificationType.system: return 'system';
    }
  }

  static NotificationType fromKey(String? key) {
    switch (key) {
      case 'order_update': return NotificationType.orderUpdate;
      case 'promo': return NotificationType.promo;
      case 'health_tip': return NotificationType.healthTip;
      case 'doctor_message': return NotificationType.doctorMessage;
      case 'lab_result': return NotificationType.labResult;
      default: return NotificationType.system;
    }
  }
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String? payload; // JSON string for deep-link routing

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.payload,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    String? payload,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      payload: payload ?? this.payload,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'type': type.key,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
    'payload': payload,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: NotificationTypeX.fromKey(json['type'] as String?),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
      payload: json['payload'] as String?,
    );
  }

  String toJsonString() => jsonEncode(toJson());
  factory AppNotification.fromJsonString(String s) =>
      AppNotification.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
