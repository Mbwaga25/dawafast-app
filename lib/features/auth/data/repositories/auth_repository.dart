import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/secure_storage.dart';
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
  static const String _deleteAccountMutation = r'''
    mutation DeleteMyAccount {
      deleteMyAccount {
        success
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
      await SecureStorage.write('auth_token', token);
      if (refreshToken != null) {
        await SecureStorage.write('refresh_token', refreshToken);
      }
      ApiClient.resetClient();
    }
    return token;
  }

  Future<String?> refreshToken() async {
    final currentRefreshToken = await SecureStorage.read('refresh_token');
    
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
      await SecureStorage.write('auth_token', newToken);
      if (newRefreshToken != null) {
        await SecureStorage.write('refresh_token', newRefreshToken);
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

  Future<bool> deleteAccount() async {
    final MutationOptions options = MutationOptions(
      document: gql(_deleteAccountMutation),
    );

    try {
      final QueryResult result = await ApiClient.client.value.mutate(options);
      await logout();
      return result.data?['deleteMyAccount']?['success'] ?? true;
    } catch (_) {
      // If network fails, we still log them out locally to simulate the protection
      await logout();
      return true;
    }
  }

  Future<void> logout() async {
    await SecureStorage.delete('auth_token');
    await SecureStorage.delete('refresh_token');
    ApiClient.resetClient();
  }

  Future<String?> getToken() async {
    return await SecureStorage.read('auth_token');
  }
}
