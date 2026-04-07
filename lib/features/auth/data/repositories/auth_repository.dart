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

  static const String _refreshTokenMutation = r'''
    mutation RefreshToken($refreshToken: String!) {
      refreshToken(refreshToken: $refreshToken) {
        token
        refreshToken
        payload
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

    final QueryResult result = await ApiClient.publicClient.value.mutate(options);

    if (result.hasException) {
      throw result.exception!;
    }

    final String? token = result.data?['login']?['token'];
    final String? refreshToken = result.data?['login']?['refreshToken'];
    
    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      if (refreshToken != null) {
        await prefs.setString('refresh_token', refreshToken);
      }
      ApiClient.resetClient();
    }
    return token;
  }

  Future<String?> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final currentRefreshToken = prefs.getString('refresh_token');
    
    if (currentRefreshToken == null) return null;

    final MutationOptions options = MutationOptions(
      document: gql(_refreshTokenMutation),
      variables: {
        'refreshToken': currentRefreshToken,
      },
    );

    final QueryResult result = await ApiClient.publicClient.value.mutate(options);

    if (result.hasException) {
      await logout();
      return null;
    }

    final String? newToken = result.data?['refreshToken']?['token'];
    final String? newRefreshToken = result.data?['refreshToken']?['refreshToken'];

    if (newToken != null) {
      await prefs.setString('auth_token', newToken);
      if (newRefreshToken != null) {
        await prefs.setString('refresh_token', newRefreshToken);
      }
      ApiClient.resetClient();
    }
    return newToken;
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

    final QueryResult result = await ApiClient.publicClient.value.mutate(options);

    if (result.hasException) {
      throw result.exception!;
    }

    return result.data?['register']?['user'] != null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
    ApiClient.resetClient();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}
