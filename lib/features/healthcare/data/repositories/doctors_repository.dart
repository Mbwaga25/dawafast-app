import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api_client.dart';
import '../models/doctor_model.dart';

final doctorsRepositoryProvider = Provider((ref) => DoctorsRepository());

class DoctorsRepository {
  static const String _allDoctorsQuery = r'''
    query GetAllDoctors($specialty: String, $search: String) {
      allDoctors(specialty: $specialty, search: $search) {
        id
        specialty
        isVerified
        licenseNumber
        experience
        consultationFee
        languages
        rating
        reviewCount
        availability
        hospital {
          id
          name
          slug
          city
          addressLine1
        }
        user {
          id
          firstName
          lastName
          email
          username
          profile {
            bio
            avatar
            phoneNumber
          }
        }
      }
    }
  ''';

  static const String _doctorDetailQuery = r'''
    query GetDoctor($id: ID!) {
      doctor(id: $id) {
        id
        specialty
        isVerified
        licenseNumber
        experience
        consultationFee
        languages
        rating
        reviewCount
        availability
        hospital {
          id
          name
          slug
          city
          addressLine1
        }
        user {
          id
          firstName
          lastName
          email
          username
          profile {
            bio
            avatar
            phoneNumber
          }
        }
      }
    }
  ''';

  static const String _specialtiesQuery = r'''
    query GetDoctorSpecialties {
      doctorSpecialties
    }
  ''';

  static const String _availableSlotsQuery = r'''
    query GetAvailableSlots($doctorId: ID!, $date: Date!) {
      appointments {
        availableSlots(doctorId: $doctorId, date: $date) {
          id
          startTime
          endTime
          isBooked
        }
      }
    }
  ''';

  static const String _bookAppointmentMutation = r'''
    mutation BookAppointment(
      $availabilityId: ID!, 
      $appointmentType: String!,
      $patientName: String,
      $issue: String
    ) {
      appointments {
        bookAppointment(
          availabilityId: $availabilityId, 
          appointmentType: $appointmentType,
          patientName: $patientName,
          issue: $issue
        ) {
          appointment {
            id
            status
            scheduledTime
          }
        }
      }
    }
  ''';

  static const String _requestInstantCallMutation = r'''
    mutation RequestInstantCall($appointmentId: ID!) {
       requestInstantCall(appointmentId: $appointmentId) {
         success
         message
         appointment {
           id
           status
         }
       }
    }
  ''';

  static const String _startCallSessionMutation = r'''
    mutation StartCallSession($appointmentId: ID!) {
      appointments {
        startCallSession(appointmentId: $appointmentId) {
          callSession {
            id
            roomId
            status
            mobileSupported
          }
        }
      }
    }
  ''';

  static const String _getCallSessionQuery = r'''
    query GetCallSession($appointmentId: ID!) {
      appointments {
        getCallSession(appointmentId: $appointmentId) {
          id
          roomId
          status
          mobileSupported
        }
      }
    }
  ''';

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
            user {
              firstName
              lastName
            }
          }
        }
      }
    }
  ''';

  Future<List<Map<String, dynamic>>> fetchMyAppointments() async {
    final QueryOptions options = QueryOptions(
      document: gql(_myAppointmentsQuery),
      fetchPolicy: FetchPolicy.noCache,
    );

    final QueryResult result = await ApiClient.client.value.query(options);
    if (result.hasException) throw result.exception!;
    final List appointments = result.data?['appointments']?['myAppointments'] ?? [];
    return List<Map<String, dynamic>>.from(appointments);
  }

  Future<List<Doctor>> fetchDoctors({String? specialty, String? search}) async {
    final QueryOptions options = QueryOptions(
      document: gql(_allDoctorsQuery),
      variables: {
        if (specialty != null && specialty != 'All') 'specialty': specialty,
        if (search != null && search.isNotEmpty) 'search': search,
      },
      fetchPolicy: FetchPolicy.noCache,
    );

    final QueryResult result = await ApiClient.client.value.query(options);

    if (result.hasException) {
      throw result.exception!;
    }

    final List doctors = result.data?['allDoctors'] ?? [];
    return doctors.map((json) => Doctor.fromJson(json)).toList();
  }

  Future<Doctor?> fetchDoctorDetail(String id) async {
    final QueryOptions options = QueryOptions(
      document: gql(_doctorDetailQuery),
      variables: {'id': id},
      fetchPolicy: FetchPolicy.noCache,
    );

    final QueryResult result = await ApiClient.client.value.query(options);

    if (result.hasException) {
      throw result.exception!;
    }

    final data = result.data?['doctor'];
    if (data == null) return null;
    return Doctor.fromJson(data);
  }

  Future<List<String>> fetchSpecialties() async {
    final QueryOptions options = QueryOptions(
      document: gql(_specialtiesQuery),
      fetchPolicy: FetchPolicy.cacheAndNetwork,
    );

    final QueryResult result = await ApiClient.client.value.query(options);

    if (result.hasException) {
      throw result.exception!;
    }

    final List specialties = result.data?['doctorSpecialties'] ?? [];
    return specialties.map((e) => e.toString()).toList();
  }

  Future<List<Map<String, dynamic>>> fetchAvailableSlots(String doctorId, String date) async {
    final QueryOptions options = QueryOptions(
      document: gql(_availableSlotsQuery),
      variables: {'doctorId': doctorId, 'date': date},
      fetchPolicy: FetchPolicy.noCache,
    );

    final QueryResult result = await ApiClient.client.value.query(options);
    if (result.hasException) throw result.exception!;

    final List slots = result.data?['appointments']?['availableSlots'] ?? [];
    return List<Map<String, dynamic>>.from(slots);
  }

  Future<Map<String, dynamic>> bookAppointment({
    required String availabilityId,
    required String appointmentType,
    String? patientName,
    String? issue,
  }) async {
    final MutationOptions options = MutationOptions(
      document: gql(_bookAppointmentMutation),
      variables: {
        'availabilityId': availabilityId,
        'appointmentType': appointmentType,
        'patientName': patientName,
        'issue': issue,
      },
    );

    final QueryResult result = await ApiClient.client.value.mutate(options);
    if (result.hasException) throw result.exception!;

    return result.data?['appointments']?['bookAppointment']?['appointment'] ?? {};
  }

  Future<Map<String, dynamic>> requestInstantCall(String appointmentId) async {
    final MutationOptions options = MutationOptions(
      document: gql(_requestInstantCallMutation),
      variables: {'appointmentId': appointmentId},
    );

    final QueryResult result = await ApiClient.client.value.mutate(options);
    if (result.hasException) throw result.exception!;
    return result.data?['requestInstantCall'] ?? {};
  }

  Future<Map<String, dynamic>> startCallSession(String appointmentId) async {
    final MutationOptions options = MutationOptions(
      document: gql(_startCallSessionMutation),
      variables: {'appointmentId': appointmentId},
    );

    final QueryResult result = await ApiClient.client.value.mutate(options);
    if (result.hasException) throw result.exception!;
    return result.data?['appointments']?['startCallSession']?['callSession'] ?? {};
  }

  Future<Map<String, dynamic>?> getCallSession(String appointmentId) async {
    final QueryOptions options = QueryOptions(
      document: gql(_getCallSessionQuery),
      variables: {'appointmentId': appointmentId},
      fetchPolicy: FetchPolicy.noCache,
    );

    final QueryResult result = await ApiClient.client.value.query(options);
    if (result.hasException) throw result.exception!;
    return result.data?['appointments']?['getCallSession'];
  }
}

final doctorsProvider = FutureProvider.family<List<Doctor>, ({String? specialty, String? search})>((ref, args) async {
  final repository = ref.watch(doctorsRepositoryProvider);
  return repository.fetchDoctors(specialty: args.specialty, search: args.search);
});

final doctorDetailProvider = FutureProvider.family<Doctor?, String>((ref, id) async {
  final repository = ref.watch(doctorsRepositoryProvider);
  return repository.fetchDoctorDetail(id);
});

final specialtiesProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(doctorsRepositoryProvider);
  return repository.fetchSpecialties();
});

final doctorSearchQueryProvider = StateProvider<String>((ref) => '');
final doctorSpecialtyFilterProvider = StateProvider<String>((ref) => 'All');

final availableSlotsProvider = FutureProvider.family<List<Map<String, dynamic>>, ({String doctorId, String date})>((ref, args) async {
  final repository = ref.watch(doctorsRepositoryProvider);
  return repository.fetchAvailableSlots(args.doctorId, args.date);
});

final myAppointmentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(doctorsRepositoryProvider);
  return repository.fetchMyAppointments();
});
