import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api_client.dart';
import '../models/user_model.dart';

final userRepositoryProvider = Provider((ref) => UserRepository());

class UserRepository {
  static const String _meQuery = r'''
    query GetCurrentUser {
      me {
        id
        username
        email
        firstName
        lastName
        phoneNumber
        role
        patientProfile {
          id
          bloodType
          gender
          location
        }
        doctorProfile {
          id
          specialty
          isVerified
        }
        pharmacistProfile {
          id
          pharmacyName
          isVerified
        }
        labProfile {
          id
          labName
          isVerified
        }
      }
    }
  ''';

  Future<User?> fetchMe() async {
    final QueryOptions options = QueryOptions(
      document: gql(_meQuery),
      fetchPolicy: FetchPolicy.networkOnly,
    );

    final QueryResult result = await ApiClient.client.value.query(options);

    if (result.hasException) {
      // If unauthorized or signature expired, return null
      final errors = result.exception!.graphqlErrors;
      if (errors.any((e) => e.message.contains('Unauthorized') || e.message.contains('Signature has expired'))) {
        return null;
      }
      throw result.exception ?? Exception('User fetch failed');
    }

    final Map<String, dynamic>? data = result.data?['me'];
    if (data == null) return null;

    return User.fromJson(data);
  }

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? bloodType,
    String? gender,
    String? location,
    String? specialty,
    String? licenseNumber,
  }) async {
    const String updateProfileMutation = r'''
      mutation UpdateProfile($input: UpdateAdminUserInput!) {
        updateProfile(input: $input) {
          success
          errors
          user {
            id
            firstName
            lastName
            phoneNumber
            patientProfile { id bloodType gender location }
            doctorProfile { id specialty isVerified }
          }
        }
      }
    ''';

    final MutationOptions options = MutationOptions(
      document: gql(updateProfileMutation),
      variables: {
        'input': {
          if (firstName != null) 'firstName': firstName,
          if (lastName != null) 'lastName': lastName,
          'profile': {
            if (phoneNumber != null) 'phoneNumber': phoneNumber,
            if (gender != null) 'gender': gender,
            if (bloodType != null) 'bloodType': bloodType,
            if (location != null) 'location': location,
          },
          if (specialty != null) 'specialty': specialty,
          if (licenseNumber != null) 'licenseNumber': licenseNumber,
        }
      },
    );

    final QueryResult result = await ApiClient.client.value.mutate(options);

    if (result.hasException) {
      throw result.exception ?? Exception('Update failed');
    }

    return result.data?['updateProfile']?['success'] ?? false;
  }
  Future<List<User>> searchUsers(String query) async {
    const String searchUsersQuery = r'''
      query SearchUsers($search: String!) {
        users {
          searchUsers(search: $search) {
            id
            username
            email
            firstName
            lastName
            role
            doctorProfile { specialty }
          }
        }
      }
    ''';

    final QueryOptions options = QueryOptions(
      document: gql(searchUsersQuery),
      variables: {'search': query},
      fetchPolicy: FetchPolicy.noCache,
    );

    final QueryResult result = await ApiClient.client.value.query(options);
    if (result.hasException) throw result.exception ?? Exception('Search failed');

    final List usersData = result.data?['users']?['searchUsers'] ?? [];
    return usersData.map((u) => User.fromJson(u)).toList();
  }
}

final currentUserProvider = FutureProvider<User?>((ref) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.fetchMe();
});
