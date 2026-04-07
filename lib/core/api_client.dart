import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String _baseUrl = 'http://127.0.0.1:8000/graphql/';
  //static const String _baseUrl = "https://api.afyalink.com/";
  static const String _apiKey = 'AfyaLink_Secure_API_Key_2024_verfied';

  // Standard client (with AuthLink)
  static final ValueNotifier<GraphQLClient> _clientNotifier = ValueNotifier(_buildClient(useAuth: true));
  
  // Public client (no AuthLink) for login/register
  static final ValueNotifier<GraphQLClient> _publicClientNotifier = ValueNotifier(_buildClient(useAuth: false));

  static ValueNotifier<GraphQLClient> get client => _clientNotifier;
  static ValueNotifier<GraphQLClient> get publicClient => _publicClientNotifier;

  static GraphQLClient _buildClient({bool useAuth = true}) {
    final httpLink = HttpLink(
      _baseUrl,
      defaultHeaders: {'X-API-KEY': _apiKey},
    );
    
    Link link = httpLink;
    
    if (useAuth) {
      final authLink = AuthLink(
        getToken: () async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          return token == null ? null : 'Bearer $token';
        },
      );
      link = authLink.concat(httpLink);
    }

    return GraphQLClient(
      link: link,
      cache: GraphQLCache(store: InMemoryStore()),
    );
  }

  /// Call this after login or logout to reset the client with the new token
  static void resetClient() {
    _clientNotifier.value = _buildClient(useAuth: true);
    _publicClientNotifier.value = _buildClient(useAuth: false);
  }
}
