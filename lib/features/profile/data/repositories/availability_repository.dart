import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/api_client.dart';

class AvailabilitySlot {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final bool isBooked;

  AvailabilitySlot({required this.id, required this.startTime, required this.endTime, required this.isBooked});

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return AvailabilitySlot(
      id: json['id'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      isBooked: json['isBooked'] ?? false,
    );
  }
}

class WeeklySlot {
  final int dayOfWeek; // 0=Mon, 6=Sun
  final String startTime; // HH:MM
  final String endTime; // HH:MM

  WeeklySlot({required this.dayOfWeek, required this.startTime, required this.endTime});

  factory WeeklySlot.fromJson(Map<String, dynamic> json) {
    return WeeklySlot(
      dayOfWeek: json['dayOfWeek'] ?? 0,
      startTime: json['startTime'] ?? '09:00',
      endTime: json['endTime'] ?? '17:00',
    );
  }

  Map<String, dynamic> toJson() => {
    'dayOfWeek': dayOfWeek,
    'startTime': startTime,
    'endTime': endTime,
  };
}

final availabilityRepositoryProvider = Provider((ref) => AvailabilityRepository());

class AvailabilityRepository {
  static const String _getDoctorAvailabilityQuery = r'''
    query GetDoctorAvailability {
      appointments {
        myAvailabilities {
          id
          startTime
          endTime
          isBooked
        }
      }
    }
  ''';

  static const String _createAvailabilityMutation = r'''
    mutation CreateAvailability($startTime: DateTime!, $endTime: DateTime!) {
      appointments {
        createAvailability(startTime: $startTime, endTime: $endTime) {
          success
          errors
          availability {
            id
            startTime
            endTime
            isBooked
          }
        }
      }
    }
  ''';

  static const String _addAvailabilitySlotsMutation = r'''
    mutation AddAvailabilitySlots($slots: [SlotInput!]!) {
      appointments {
        addAvailabilitySlots(slots: $slots) {
          success
          errors
        }
      }
    }
  ''';

  static const String _deleteAvailabilityMutation = r'''
    mutation DeleteAvailability($id: ID!) {
      appointments {
        deleteAvailability(id: $id) {
          success
          errors
        }
      }
    }
  ''';

  static const String _getMyWeeklyAvailabilityQuery = r'''
    query GetMyWeeklyAvailability {
      bookings {
        myAvailability {
          dayOfWeek
          startTime
          endTime
        }
      }
    }
  ''';

  static const String _updateWeeklyAvailabilityMutation = r'''
    mutation UpdateWeeklyAvailability($slots: [DoctorWeeklySlotInput!]!) {
      bookings {
        updateWeeklyAvailability(slots: $slots) {
          success
          errors
        }
      }
    }
  ''';

  Future<List<AvailabilitySlot>> fetchMyAvailabilities() async {
    final QueryOptions options = QueryOptions(
      document: gql(_getDoctorAvailabilityQuery),
      fetchPolicy: FetchPolicy.noCache,
    );

    final QueryResult result = await ApiClient.client.value.query(options);
    if (result.hasException) throw result.exception!;
    final List list = result.data?['appointments']?['myAvailabilities'] ?? [];
    return list.map((e) => AvailabilitySlot.fromJson(e)).toList();
  }

  Future<bool> createAvailability(DateTime startTime, DateTime endTime) async {
    final MutationOptions options = MutationOptions(
      document: gql(_createAvailabilityMutation),
      variables: {
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
      },
    );

    final QueryResult result = await ApiClient.client.value.mutate(options);
    if (result.hasException) throw result.exception!;
    final data = result.data?['appointments']?['createAvailability'];
    if (data?['success'] == false) {
       throw Exception((data?['errors'] as List?)?.join(', ') ?? 'Failed to create availability');
    }
    return true;
  }

  Future<bool> addAvailabilitySlots(List<Map<String, String>> slots) async {
    final MutationOptions options = MutationOptions(
      document: gql(_addAvailabilitySlotsMutation),
      variables: {
        'slots': slots,
      },
    );

    final QueryResult result = await ApiClient.client.value.mutate(options);
    if (result.hasException) throw result.exception!;
    final data = result.data?['appointments']?['addAvailabilitySlots'];
    if (data?['success'] == false) {
       throw Exception((data?['errors'] as List?)?.join(', ') ?? 'Failed to add availability slots');
    }
    return true;
  }

  Future<bool> deleteAvailability(String id) async {
    final MutationOptions options = MutationOptions(
      document: gql(_deleteAvailabilityMutation),
      variables: {'id': id},
    );

    final QueryResult result = await ApiClient.client.value.mutate(options);
    if (result.hasException) throw result.exception!;
    return result.data?['appointments']?['deleteAvailability']?['success'] ?? false;
  }

  Future<List<WeeklySlot>> fetchMyWeeklyAvailability() async {
    final QueryOptions options = QueryOptions(
      document: gql(_getMyWeeklyAvailabilityQuery),
      fetchPolicy: FetchPolicy.noCache,
    );

    final QueryResult result = await ApiClient.client.value.query(options);
    if (result.hasException) throw result.exception!;
    final List list = result.data?['bookings']?['myAvailability'] ?? [];
    return list.map((e) => WeeklySlot.fromJson(e)).toList();
  }

  Future<bool> updateWeeklyAvailability(List<WeeklySlot> slots) async {
    final MutationOptions options = MutationOptions(
      document: gql(_updateWeeklyAvailabilityMutation),
      variables: {
        'slots': slots.map((s) => s.toJson()).toList(),
      },
    );

    final QueryResult result = await ApiClient.client.value.mutate(options);
    if (result.hasException) throw result.exception!;
    final data = result.data?['bookings']?['updateWeeklyAvailability'];
    if (data?['success'] == false) {
       throw Exception((data?['errors'] as List?)?.join(', ') ?? 'Failed to update weekly availability');
    }
    return true;
  }
}

final myAvailabilitiesProvider = FutureProvider<List<AvailabilitySlot>>((ref) async {
  return ref.watch(availabilityRepositoryProvider).fetchMyAvailabilities();
});

final myWeeklyAvailabilityProvider = FutureProvider<List<WeeklySlot>>((ref) async {
  return ref.watch(availabilityRepositoryProvider).fetchMyWeeklyAvailability();
});
