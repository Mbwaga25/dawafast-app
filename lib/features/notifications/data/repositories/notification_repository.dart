import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api_client.dart';
import '../models/notification_model.dart';

final notificationRepositoryProvider = Provider((ref) => NotificationRepository());

class NotificationRepository {
  static const String _notificationsQuery = r'''
    query GetNotifications($isRead: Boolean) {
      myNotifications(isRead: $isRead) {
        id
        notificationType
        title
        message
        link
        isRead
        createdAt
        referralId
        appointmentId
      }
    }
  ''';

  static const String _markReadMutation = r'''
    mutation MarkNotificationRead($notificationId: ID!) {
      markNotificationRead(notificationId: $notificationId) {
        success
        notification {
          id
          isRead
        }
      }
    }
  ''';

  Future<List<AppNotification>> fetchNotifications({bool? isRead}) async {
    final QueryOptions options = QueryOptions(
      document: gql(_notificationsQuery),
      variables: isRead != null ? {'isRead': isRead} : {},
      fetchPolicy: FetchPolicy.networkOnly,
    );

    final QueryResult result = await ApiClient.client.value.query(options);
    if (result.hasException) throw result.exception!;

    final List data = result.data?['myNotifications'] ?? [];
    return data.map((json) => AppNotification.fromJson(json)).toList();
  }

  Future<bool> markAsRead(String id) async {
    final MutationOptions options = MutationOptions(
      document: gql(_markReadMutation),
      variables: {'notificationId': id},
    );

    final QueryResult result = await ApiClient.client.value.mutate(options);
    if (result.hasException) throw result.exception!;
    return result.data?['markNotificationRead']?['success'] ?? false;
  }
}

final notificationsProvider = FutureProvider.family<List<AppNotification>, bool?>((ref, isRead) async {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.fetchNotifications(isRead: isRead);
});

final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(notificationRepositoryProvider);
  final notifications = await repository.fetchNotifications(isRead: false);
  return notifications.length;
});
