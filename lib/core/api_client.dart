import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'services/secure_storage.dart';
import 'app_config.dart';

class ApiClient {
  static String get _baseUrl => AppConfig.baseUrl;
  static String get _apiKey => AppConfig.apiKey;

  static final ValueNotifier<GraphQLClient> _clientNotifier = ValueNotifier(_buildClient(useAuth: true));
  static final ValueNotifier<GraphQLClient> _publicClientNotifier = ValueNotifier(_buildClient(useAuth: false));

  static ValueNotifier<GraphQLClient> get client => _clientNotifier;
  static ValueNotifier<GraphQLClient> get publicClient => _publicClientNotifier;

  static Future<String?>? _refreshingFuture;

  static GraphQLClient _buildClient({bool useAuth = true}) {
    final httpLink = HttpLink(
      _baseUrl,
      defaultHeaders: {'X-API-KEY': _apiKey},
    );

    Link link = httpLink;

    if (useAuth) {
      final authLink = AuthLink(
        getToken: () async {
          final token = await SecureStorage.read('auth_token');
          return token == null ? null : 'Bearer $token';
        },
      );

      final errorLink = ErrorLink(
        onException: (Request request, NextLink forward, LinkException exception) async* {
          if (exception is ServerException && 
              (exception.parsedResponse?.errors?.any((e) => e.message.contains('Signature has expired') || e.message.contains('Error decoding signature')) ?? false)) {
            
            // Handle token refresh
            final newToken = await _performRefresh();
            if (newToken != null) {
              // Retry the original request
              yield* forward(request);
            }
          }
        },
        onGraphQLError: (Request request, NextLink forward, Response response) async* {
          if (response.errors?.any((e) => e.message.contains('Signature has expired') || e.message.contains('Error decoding signature') || e.message.contains('Unauthorized')) ?? false) {
            
            final newToken = await _performRefresh();
            if (newToken != null) {
              yield* forward(request);
            }
          }
        }
      );

      link = Link.from([errorLink, authLink, httpLink]);
    }

    return GraphQLClient(
      link: link,
      cache: GraphQLCache(store: HiveStore()),
    );
  }

  static Future<String?> _performRefresh() async {
    if (_refreshingFuture != null) return _refreshingFuture;

    _refreshingFuture = _doRefresh();
    final result = await _refreshingFuture;
    _refreshingFuture = null;
    return result;
  }

  static Future<String?> _doRefresh() async {
    try {
      final refreshToken = await SecureStorage.read('refresh_token');
      if (refreshToken == null) return null;

      final mutation = r'''
        mutation RefreshToken($refreshToken: String!) {
          refreshToken(refreshToken: $refreshToken) {
            token
            refreshToken
          }
        }
      ''';

      final QueryResult result = await publicClient.value.mutate(
        MutationOptions(
          document: gql(mutation),
          variables: {'refreshToken': refreshToken},
        ),
      );

      if (result.hasException) {
        // Refresh failed (e.g. refresh token also expired)
        await SecureStorage.delete('auth_token');
        await SecureStorage.delete('refresh_token');
        resetClient();
        return null;
      }

      final String? newToken = result.data?['refreshToken']?['token'];
      final String? newRefreshToken = result.data?['refreshToken']?['refreshToken'];

      if (newToken != null) {
        await SecureStorage.write('auth_token', newToken);
        if (newRefreshToken != null) {
          await SecureStorage.write('refresh_token', newRefreshToken);
        }
        resetClient();
        return newToken;
      }
    } catch (e) {
      debugPrint("Token refresh failed: $e");
    }
    return null;
  }

  static void resetClient() {
    _clientNotifier.value = _buildClient(useAuth: true);
    _publicClientNotifier.value = _buildClient(useAuth: false);
  }
}
