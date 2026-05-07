import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../app_config.dart';

class MapboxService {
  static const String _baseUrl = 'https://api.mapbox.com/geocoding/v5/mapbox.places';

  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    final String token = AppConfig.mapboxToken;
    final String url = '$_baseUrl/$lng,$lat.json?access_token=$token&types=address,place,poi&limit=1';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          return data['features'][0]['place_name'] as String;
        }
      }
    } catch (e) {
      print('Mapbox Geocoding Error: $e');
    }
    return null;
  }

  Future<List<MapboxPrediction>> searchPlaces(String query, {double? lat, double? lng}) async {
    final String token = AppConfig.mapboxToken;
    String url = '$_baseUrl/${Uri.encodeComponent(query)}.json?access_token=$token&autocomplete=true&limit=5';
    
    if (lat != null && lng != null) {
      url += '&proximity=$lng,$lat';
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;
        return features.map((f) => MapboxPrediction.fromJson(f)).toList();
      }
    } catch (e) {
      print('Mapbox Search Error: $e');
    }
    return [];
  }
}

class MapboxPrediction {
  final String id;
  final String name;
  final String placeName;
  final double lat;
  final double lng;

  MapboxPrediction({
    required this.id,
    required this.name,
    required this.placeName,
    required this.lat,
    required this.lng,
  });

  factory MapboxPrediction.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List;
    return MapboxPrediction(
      id: json['id'] as String,
      name: json['text'] as String,
      placeName: json['place_name'] as String,
      lat: coordinates[1] as double,
      lng: coordinates[0] as double,
    );
  }
}
