import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/api_client.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

class AuthRepository {
  static const String _loginMutation = r'''
    mutation Login($input: LoginUserInput!) {
      login(input: $input) {
        token
        refreshToken
        user {
          id
          username
          email
        }
      }
    }
  ''';

  static const String _registerMutation = r'''
    mutation Register($input: RegisterUserInput!) {
      register(input: $input) {
        user {
          id
          username
          email
        }
      }
    }
  ''';

  Future<String?> login(String usernameOrEmail, String password) async {
    final MutationOptions options = MutationOptions(
      document: gql(_loginMutation),
      variables: {
        'input': {
          'usernameOrEmail': usernameOrEmail,
          'password': password,
        }
      },
    );

    final QueryResult result = await ApiClient.client.value.mutate(options);

    if (result.hasException) {
      throw result.exception!;
    }

    final String? token = result.data?['login']?['token'];
    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      // We might need to notify ApiClient to update its headers
    }
    return token;
  }

  Future<bool> register(String username, String email, String password) async {
    final MutationOptions options = MutationOptions(
      document: gql(_registerMutation),
      variables: {
        'input': {
          'username': username,
          'email': email,
          'password': password,
        }
      },
    );

    final QueryResult result = await ApiClient.client.value.mutate(options);

    if (result.hasException) {
      throw result.exception!;
    }

    return result.data?['register']?['user'] != null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}
