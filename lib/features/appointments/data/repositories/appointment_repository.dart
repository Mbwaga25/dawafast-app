import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:afyalink/core/api_client.dart';
import 'package:afyalink/features/appointments/data/models/appointment_model.dart';
import 'package:afyalink/features/appointments/data/models/chat_model.dart';
import 'package:afyalink/features/auth/data/repositories/user_repository.dart';

final appointmentRepositoryProvider = Provider((ref) => AppointmentRepository());

class AppointmentRepository {
  static const String _myAppointmentsQuery = r'''
    query GetMyAppointments {
      appointments {
        myAppointments {
          id
          status
          appointmentType
          scheduledTime
          doctor {
            id
            specialty
            user {
              firstName
              lastName
            }
          }
        }
      }
    }
  ''';

  static const String _appointmentMessagesQuery = r'''
    query GetAppointmentMessages($id: ID!) {
      appointmentById(id: $id) {
        id
        messages {
          id
          message
          imageUrl
          expiresAt
          timestamp
          user {
            id
            firstName
            lastName
            role
          }
        }
      }
    }
  ''';

  static const String _sendMessageMutation = r'''
    mutation SendAppointmentMessage($appointment_id: ID!, $content: String!) {
      appointments {
        sendAppointmentMessage(appointmentId: $appointment_id, content: $content) {
          success
          chatMessage {
            id
            message
            imageUrl
            expiresAt
            timestamp
            user {
              id
              firstName
              lastName
              role
            }
          }
        }
      }
    }
  ''';

  Future<List<Appointment>> fetchMyAppointments() async {
    final QueryOptions options = QueryOptions(
      document: gql(_myAppointmentsQuery),
      fetchPolicy: FetchPolicy.networkOnly,
    );

    final QueryResult result = await ApiClient.client.value.query(options);
    if (result.hasException) throw result.exception!;

    final List data = result.data?['appointments']?['myAppointments'] ?? [];
    return data.map((json) {
      final doctorJson = json['doctor'] ?? {};
      final doctorUser = doctorJson['user'] ?? {};
      return Appointment(
        id: json['id'],
        doctorName: 'Dr. ${doctorUser['firstName'] ?? ''} ${doctorUser['lastName'] ?? ''}'.trim(),
        specialization: doctorJson['specialty'] ?? 'Specialist',
        date: json['scheduledTime'] != null ? DateTime.parse(json['scheduledTime']) : DateTime.now(),
        status: json['status']?.toLowerCase() ?? 'pending',
        type: json['appointmentType']?.toLowerCase() ?? 'in-person',
      );
    }).toList();
  }

  Future<List<ChatMessage>> fetchChatMessages(String appointmentId) async {
    if (appointmentId == 'instant_meeting') return [];
    
    final QueryOptions options = QueryOptions(
      document: gql(_appointmentMessagesQuery),
      variables: {'id': appointmentId},
      fetchPolicy: FetchPolicy.networkOnly,
    );

    final QueryResult result = await ApiClient.client.value.query(options);
    if (result.hasException) throw result.exception!;

    final List data = result.data?['appointmentById']?['messages'] ?? [];
    return data.map((json) => ChatMessage.fromJson(json)).toList();
  }

  Future<ChatMessage?> sendMessage(String appointmentId, String content) async {
    if (appointmentId == 'instant_meeting') return null;
    
    final MutationOptions options = MutationOptions(
      document: gql(_sendMessageMutation),
      variables: {
        'appointment_id': appointmentId,
        'content': content,
      },
    );

    final QueryResult result = await ApiClient.client.value.mutate(options);
    if (result.hasException) throw result.exception!;

    final chatJson = result.data?['appointments']?['sendAppointmentMessage']?['chatMessage'];
    if (chatJson == null) return null;
    return ChatMessage.fromJson(chatJson);
  }

  static const String _startDirectChatMutation = r'''
    mutation StartDirectChat($target_user_id: ID!) {
      appointments {
        startDirectChat(targetUserId: $target_user_id) {
          success
          errors
          appointment {
            id
          }
        }
      }
    }
  ''';

  static const String _createReviewMutation = r'''
    mutation CreateReview($target_user_id: ID!, $rating: Int!, $comment: String!) {
      users {
        createReview(targetUserId: $target_user_id, rating: $rating, comment: $comment) {
          success
          errors
        }
      }
    }
  ''';

  Future<String?> startDirectChat(String targetUserId) async {
    final MutationOptions options = MutationOptions(
      document: gql(_startDirectChatMutation),
      variables: {'target_user_id': targetUserId},
    );

    final result = await ApiClient.client.value.mutate(options);
    if (result.hasException) throw result.exception!;

    final data = result.data?['appointments']?['startDirectChat'];
    if (data?['success'] == true) {
      return data['appointment']?['id'];
    }
    throw data?['errors']?.join(', ') ?? 'Failed to start chat';
  }

  Future<bool> createReview(String targetUserId, int rating, String comment) async {
    final MutationOptions options = MutationOptions(
      document: gql(_createReviewMutation),
      variables: {
        'target_user_id': targetUserId,
        'rating': rating,
        'comment': comment,
      },
    );

    final QueryResult result = await ApiClient.client.value.mutate(options);
    if (result.hasException) throw result.exception!;

    return result.data?['users']?['createReview']?['success'] ?? false;
  }

  static const String _uploadMediaMutation = r'''
    mutation UploadChatMedia($appointment_id: ID!, $image: Upload!) {
      appointments {
        uploadChatMedia(appointmentId: $appointment_id, image: $image) {
          success
          message {
            id
            message
            imageUrl
            expiresAt
            timestamp
            user {
              id
              firstName
              lastName
              role
            }
          }
        }
      }
    }
  ''';

  Future<ChatMessage?> uploadChatMedia(String appointmentId, List<int> bytes, String filename) async {
    if (appointmentId == 'instant_meeting') return null;

    final http.MultipartFile multipartFile = http.MultipartFile.fromBytes(
      'image',
      bytes,
      filename: filename,
    );

    final MutationOptions options = MutationOptions(
      document: gql(_uploadMediaMutation),
      variables: {
        'appointment_id': appointmentId,
        'image': multipartFile,
      },
    );

    final QueryResult result = await ApiClient.client.value.mutate(options);
    if (result.hasException) throw result.exception!;

    final chatJson = result.data?['appointments']?['uploadChatMedia']?['message'];
    if (chatJson == null) return null;
    return ChatMessage.fromJson(chatJson);
  }
}

// Providers
final upcomingAppointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  final repository = ref.watch(appointmentRepositoryProvider);
  final all = await repository.fetchMyAppointments();
  final now = DateTime.now();
  return all.where((a) => a.date.isAfter(now) || a.status == 'pending' || a.status == 'confirmed').toList();
});

final pastAppointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  final repository = ref.watch(appointmentRepositoryProvider);
  final all = await repository.fetchMyAppointments();
  final now = DateTime.now();
  return all.where((a) => a.date.isBefore(now) && a.status != 'pending' && a.status != 'confirmed').toList();
});

final chatMessagesProvider = FutureProvider.family<List<ChatMessage>, String>((ref, appointmentId) async {
  final repository = ref.watch(appointmentRepositoryProvider);
  return repository.fetchChatMessages(appointmentId);
});

// ------------- DOCTOR PROVIDERS (Restored for Dashboard compatibility) ------------- //

class DoctorAppointmentsNotifier extends StateNotifier<AsyncValue<List<Appointment>>> {
  final AppointmentRepository repository;
  
  DoctorAppointmentsNotifier(this.repository) : super(const AsyncValue.loading()) {
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    try {
      final data = await repository.fetchMyAppointments();
      state = AsyncValue.data(data);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void updateAppointmentStatus(String appointmentId, String newStatus) {
    if (state is AsyncData) {
      final list = state.value!;
      final updatedList = list.map((a) {
        if (a.id == appointmentId) {
          return Appointment(
            id: a.id,
            doctorName: a.doctorName,
            patientName: a.patientName,
            patientId: a.patientId,
            isTransferred: a.isTransferred,
            transferredFrom: a.transferredFrom,
            specialization: a.specialization,
            date: a.date,
            status: newStatus,
            type: a.type,
            imageUrl: a.imageUrl,
            issue: a.issue,
            consultationNotes: a.consultationNotes,
            prescription: a.prescription,
            notes: a.notes,
          );
        }
        return a;
      }).toList();
      state = AsyncValue.data(List<Appointment>.from(updatedList));
    }
  }
}

final doctorAppointmentsProvider = StateNotifierProvider<DoctorAppointmentsNotifier, AsyncValue<List<Appointment>>>((ref) {
  return DoctorAppointmentsNotifier(ref.read(appointmentRepositoryProvider));
});

final myPatientsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return [
    {'id': '101', 'name': 'John Doe', 'condition': 'Hypertension', 'lastVisit': '2023-11-01', 'status': 'Assigned'},
    {'id': '102', 'name': 'Sarah Connor', 'condition': 'Routine Checkup', 'lastVisit': '2023-10-15', 'status': 'Attended'},
  ];
});

final transferredPatientsProvider = FutureProvider<List<Appointment>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 700));
  return [
    Appointment(
      id: '201',
      doctorName: 'Me',
      isTransferred: true,
      transferredFrom: 'Dr. Emily Chen',
      specialization: 'Cardiology',
      date: DateTime.now().subtract(const Duration(days: 1)),
      status: 'accomplished',
      type: 'in-person',
    ),
  ];
});
