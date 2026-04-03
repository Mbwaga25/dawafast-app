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
      // If unauthorized, return null
      if (result.exception!.graphqlErrors.any((e) => e.message.contains('Unauthorized'))) {
        return null;
      }
      throw result.exception!;
    }

    final Map<String, dynamic>? data = result.data?['me'];
    if (data == null) return null;

    return User.fromJson(data);
  }

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
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
          if (phoneNumber != null) 'profile': {'phoneNumber': phoneNumber},
        }
      },
    );

    final QueryResult result = await ApiClient.client.value.mutate(options);

    if (result.hasException) {
      throw result.exception!;
    }

    return result.data?['updateProfile']?['success'] ?? false;
  }
  Future<List<User>> searchUsers(String query) async {
    const String searchUsersQuery = r'''
      query SearchUsers($query: String!) {
        users {
          allUsers(search: $query) {
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
      variables: {'query': query},
      fetchPolicy: FetchPolicy.noCache,
    );

    final QueryResult result = await ApiClient.client.value.query(options);
    if (result.hasException) throw result.exception!;

    final List usersData = result.data?['users']?['allUsers'] ?? [];
    return usersData.map((u) => User.fromJson(u)).toList();
  }
}

final currentUserProvider = FutureProvider<User?>((ref) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.fetchMe();
});
