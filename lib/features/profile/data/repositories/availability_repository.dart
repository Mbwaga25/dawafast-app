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
}

final myAvailabilitiesProvider = FutureProvider<List<AvailabilitySlot>>((ref) async {
  return ref.watch(availabilityRepositoryProvider).fetchMyAvailabilities();
});
