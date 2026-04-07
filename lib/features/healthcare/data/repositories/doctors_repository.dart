import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api_client.dart';
import '../models/doctor_model.dart';
import '../models/referral_model.dart';

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
      appointments {
        requestInstantCall(appointmentId: $appointmentId) {
          success
          message
          appointment {
            id
            status
          }
        }
      }
    }
  ''';

  static const String _startCallSessionMutation = r'''
    mutation StartCallSession($appointmentId: String!) {
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
    query GetCallSession($appointmentId: String!) {
      appointments {
        callSessionByAppointmentId(appointmentId: $appointmentId) {
          id
          roomId
          status
          mobileSupported
        }
      }
    }
  ''';

  static const String _rejectAppointmentMutation = r'''
    mutation RejectAppointment($appointmentId: String!, $reason: String) {
      appointments {
        cancelAppointment(appointmentId: $appointmentId, reason: $reason) {
          success
          errors
        }
      }
    }
  ''';

  static const String _receivedReferralsQuery = r'''
    query GetReceivedReferrals($status: String) {
      receivedReferrals(status: $status) {
        id
        status
        reason
        notes
        createdAt
        patient {
          id
          user {
            firstName
            lastName
            email
          }
        }
        referringDoctor {
          id
          user {
            firstName
            lastName
          }
        }
        attachments {
          id
          fileName
          fileType
          fileUrl
        }
      }
    }
  ''';

  static const String _sentReferralsQuery = r'''
    query GetSentReferrals($status: String) {
      sentReferrals(status: $status) {
        id
        status
        reason
        notes
        createdAt
        patient {
          id
          user {
            firstName
            lastName
            email
          }
        }
        targetDoctor {
          id
          user {
            firstName
            lastName
          }
        }
        targetStore {
          id
          name
          storeType
        }
        attachments {
          id
          fileName
          fileType
          fileUrl
        }
      }
    }
  ''';

  static const String _myReferralsQuery = r'''
    query GetMyReferrals($status: String) {
      appointments {
        myReferrals(status: $status) {
          id
          status
          reason
          notes
          createdAt
          referringDoctor {
            id
            user {
              firstName
              lastName
            }
          }
          referringStore {
            id
            name
            storeType
          }
          targetDoctor {
            id
            user {
              firstName
              lastName
            }
          }
          targetStore {
            id
            name
            storeType
          }
        }
      }
    }
  ''';

  static const String _appointmentByIdQuery = r'''
    query GetAppointmentById($id: ID!) {
      appointmentById(id: $id) {
        id
        status
        doctor {
          id
          specialty
          user {
            firstName
            lastName
            profilePicture
          }
        }
      }
    }
  ''';

  static const String _patientHistoryQuery = r'''
    query GetPatientHistory($patientId: ID!) {
      patientHistory(patientId: $patientId) {
        id
        createdAt
        issue
        consultationNotes
        prescription
        doctor {
          id
          user {
            lastName
          }
        }
      }
    }
  ''';

  static const String _doctorByAppointmentQuery = r'''
    query GetDoctorByAppointment($appointmentId: ID!) {
      appointmentById(id: $appointmentId) {
        doctor {
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
    }
  ''';

  static const String _referPatientMutation = r'''
    mutation ReferPatient(
      $patientId: ID!,
      $providerType: String!,
      $providerId: ID!,
      $reason: String!,
      $notes: String,
      $labTestIds: [ID!],
      $productIds: [ID!]
    ) {
      referPatient(
        patientId: $patientId,
        providerType: $providerType,
        providerId: $providerId,
        reason: $reason,
        notes: $notes,
        labTestIds: $labTestIds,
        productIds: $productIds
      ) {
        success
        errors
        referral {
          id
          status
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

  static const String _confirmAppointmentMutation = r'''
    mutation ConfirmAppointment($appointmentId: ID!) {
      appointments {
        confirmAppointment(appointmentId: $appointmentId) {
          appointment {
            id
            status
          }
        }
      }
    }
  ''';

  Future<Map<String, dynamic>> confirmAppointment(String appointmentId) async {
    final MutationOptions options = MutationOptions(
      document: gql(_confirmAppointmentMutation),
      variables: {'appointmentId': appointmentId},
    );

    final QueryResult result = await ApiClient.client.value.mutate(options);
    if (result.hasException) throw result.exception!;
    return result.data?['appointments']?['confirmAppointment']?['appointment'] ?? {};
  }

  Future<Map<String, dynamic>> requestInstantCall(String appointmentId) async {
    final MutationOptions options = MutationOptions(
      document: gql(_requestInstantCallMutation),
      variables: {'appointmentId': appointmentId},
    );

    final QueryResult result = await ApiClient.client.value.mutate(options);
    if (result.hasException) throw result.exception!;
    return result.data?['appointments']?['requestInstantCall'] ?? {};
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
    return result.data?['appointments']?['callSessionByAppointmentId'];
  }

  Future<bool> rejectAppointment(String appointmentId, {String? reason}) async {
    final MutationOptions options = MutationOptions(
      document: gql(_rejectAppointmentMutation),
      variables: {'appointmentId': appointmentId, 'reason': reason},
    );

    final QueryResult result = await ApiClient.client.value.mutate(options);
    if (result.hasException) throw result.exception!;
    return result.data?['appointments']?['cancelAppointment']?['success'] ?? false;
  }

  Future<List<Map<String, dynamic>>> fetchReceivedReferrals({String? status}) async {
    final QueryOptions options = QueryOptions(
      document: gql(_receivedReferralsQuery),
      variables: {'status': status},
      fetchPolicy: FetchPolicy.noCache,
    );

    final QueryResult result = await ApiClient.client.value.query(options);
    if (result.hasException) throw result.exception!;
    return List<Map<String, dynamic>>.from(result.data?['receivedReferrals'] ?? []);
  }

  Future<List<Map<String, dynamic>>> fetchSentReferrals({String? status}) async {
    final QueryOptions options = QueryOptions(
      document: gql(_sentReferralsQuery),
      variables: {'status': status},
      fetchPolicy: FetchPolicy.noCache,
    );

    final QueryResult result = await ApiClient.client.value.query(options);
    if (result.hasException) throw result.exception!;
    return List<Map<String, dynamic>>.from(result.data?['sentReferrals'] ?? []);
  }

  Future<List<Referral>> fetchMyReferrals({String? status}) async {
    final QueryOptions options = QueryOptions(
      document: gql(_myReferralsQuery),
      variables: status != null ? {'status': status} : {},
      fetchPolicy: FetchPolicy.networkOnly,
    );

    final QueryResult result = await ApiClient.client.value.query(options);
    if (result.hasException) throw result.exception!;

    final List data = result.data?['appointments']?['myReferrals'] ?? [];
    return data.map((json) => Referral.fromJson(json)).toList();
  }

  Future<Doctor?> fetchDoctorByAppointmentId(String id) async {
    final QueryOptions options = QueryOptions(
      document: gql(_doctorByAppointmentQuery),
      variables: {'appointmentId': id},
      fetchPolicy: FetchPolicy.noCache,
    );

    final QueryResult result = await ApiClient.client.value.query(options);
    if (result.hasException) throw result.exception!;
    final doctorData = result.data?['appointmentById']?['doctor'];
    if (doctorData == null) return null;
    return Doctor.fromJson(doctorData);
  }

  Future<List<Map<String, dynamic>>> fetchPatientHistory(String patientId) async {
    final QueryOptions options = QueryOptions(
      document: gql(_patientHistoryQuery),
      variables: {'patientId': patientId},
      fetchPolicy: FetchPolicy.noCache,
    );

    final QueryResult result = await ApiClient.client.value.query(options);
    if (result.hasException) throw result.exception!;
    return List<Map<String, dynamic>>.from(result.data?['patientHistory'] ?? []);
  }

  Future<bool> referPatient({
    required String patientId,
    required String providerType,
    required String providerId,
    required String reason,
    String? notes,
    List<String>? labTestIds,
    List<String>? productIds,
  }) async {
    final MutationOptions options = MutationOptions(
      document: gql(_referPatientMutation),
      variables: {
        'patientId': patientId,
        'providerType': providerType,
        'providerId': providerId,
        'reason': reason,
        'notes': notes,
        'labTestIds': labTestIds,
        'productIds': productIds,
      },
    );

    final QueryResult result = await ApiClient.client.value.mutate(options);
    if (result.hasException) throw result.exception!;
    final data = result.data?['referPatient'];
    if (data?['success'] == false) {
      final errorMsg = (data?['errors'] as List?)?.join(', ') ?? 'Unknown referral error';
      throw Exception(errorMsg);
    }
    return true;
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

final receivedReferralsProvider = FutureProvider.family<List<Referral>, String?>((ref, status) async {
  final repository = ref.watch(doctorsRepositoryProvider);
  final data = await repository.fetchReceivedReferrals(status: status);
  return data.map((json) => Referral.fromJson(json)).toList();
});

final sentReferralsProvider = FutureProvider.family<List<Referral>, String?>((ref, status) async {
  final repository = ref.watch(doctorsRepositoryProvider);
  final data = await repository.fetchSentReferrals(status: status);
  return data.map((json) => Referral.fromJson(json)).toList();
});

final patientHistoryProvider = FutureProvider.family<List<PatientHistoryRecord>, String>((ref, patientId) async {
  final repository = ref.watch(doctorsRepositoryProvider);
  final data = await repository.fetchPatientHistory(patientId);
  return data.map((json) => PatientHistoryRecord.fromJson(json)).toList();
});

final myReferralsProvider = FutureProvider.family<List<Referral>, String?>((ref, status) async {
  final repository = ref.watch(doctorsRepositoryProvider);
  return repository.fetchMyReferrals(status: status);
});
