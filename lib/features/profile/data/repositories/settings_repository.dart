import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api_client.dart';

class CurrencySettings {
  final String baseCurrency;
  final String symbol;
  final String name;

  CurrencySettings({
    required this.baseCurrency,
    required this.symbol,
    required this.name,
  });

  factory CurrencySettings.fromJson(Map<String, dynamic> json) {
    return CurrencySettings(
      baseCurrency: json['baseCurrency'] ?? 'TZS',
      symbol: json['currencySymbol'] ?? 'Tsh',
      name: json['currencyName'] ?? 'Tanzanian Shilling',
    );
  }
}

class MapSettings {
  final String? mapboxToken;
  final String? googleMapsKey;

  MapSettings({
    this.mapboxToken,
    this.googleMapsKey,
  });

  factory MapSettings.fromJson(Map<String, dynamic> json) {
    return MapSettings(
      mapboxToken: json['mapboxToken'],
      googleMapsKey: json['googleMapsKey'],
    );
  }
}

class SettingsRepository {
  Future<CurrencySettings?> fetchCurrencySettings() async {
    const String query = r'''
      query GetCurrencySettings {
        currencySettings {
          baseCurrency
          currencySymbol
          currencyName
        }
      }
    ''';

    final QueryOptions options = QueryOptions(
      document: gql(query),
      fetchPolicy: FetchPolicy.networkOnly,
    );

    final QueryResult result = await ApiClient.client.value.query(options);

    if (result.hasException) {
      // It's possible the settings aren't configured yet, fallback to defaults
      return CurrencySettings(baseCurrency: 'TZS', symbol: 'Tsh', name: 'Tanzanian Shilling');
    }

    final data = result.data?['currencySettings'];
    if (data == null) return null;
    return CurrencySettings.fromJson(data);
  }

  Future<MapSettings?> fetchMapSettings() async {
    const String query = r'''
      query GetMapSettings {
        geo {
          mapSettings {
            mapboxToken
            googleMapsKey
          }
        }
      }
    ''';

    final QueryOptions options = QueryOptions(
      document: gql(query),
      fetchPolicy: FetchPolicy.cacheFirst,
    );

    try {
      final QueryResult result = await ApiClient.publicClient.value.query(options);

      if (result.hasException) {
        return null;
      }

      final data = result.data?['geo']?['mapSettings'];
      if (data == null) return null;
      return MapSettings.fromJson(data);
    } catch (e) {
      return null;
    }
  }
}

final settingsRepositoryProvider = Provider((ref) => SettingsRepository());

final currencySettingsProvider = FutureProvider<CurrencySettings?>((ref) async {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.fetchCurrencySettings();
});

final mapSettingsProvider = FutureProvider<MapSettings?>((ref) async {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.fetchMapSettings();
});
