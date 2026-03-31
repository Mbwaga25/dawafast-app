import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String _baseUrl = 'http://127.0.0.1:8000/graphql/';
  static const String _apiKey = 'AfyaLink_Secure_API_Key_2024_verfied';

  static HttpLink get _httpLink => HttpLink(
        _baseUrl,
        defaultHeaders: {'X-API-KEY': _apiKey},
      );

  static AuthLink _authLink() => AuthLink(
        getToken: () async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          return token == null ? null : 'Bearer $token';
        },
      );

  static Link get _link => _authLink().concat(_httpLink);

  static ValueNotifier<GraphQLClient> get client => ValueNotifier(
        GraphQLClient(
          link: _link,
          cache: GraphQLCache(store: InMemoryStore()),
        ),
      );
}
