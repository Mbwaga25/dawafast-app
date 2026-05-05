import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Completer<LocationPermission>? _permissionCompleter;
  
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    
    // If permission is denied, handle it with a shared completer to prevent concurrent UI dialogs
    if (permission == LocationPermission.denied) {
      if (_permissionCompleter != null && !_permissionCompleter!.isCompleted) {
        try {
          permission = await _permissionCompleter!.future;
        } catch (_) {
          permission = await Geolocator.checkPermission();
        }
      } else {
        _permissionCompleter = Completer<LocationPermission>();
        try {
          final result = await Geolocator.requestPermission();
          if (!_permissionCompleter!.isCompleted) {
            _permissionCompleter!.complete(result);
          }
          permission = result;
        } catch (e) {
          if (!_permissionCompleter!.isCompleted) {
            _permissionCompleter!.completeError(e);
          }
          permission = await Geolocator.checkPermission();
        } finally {
          // Keep the completer for a while to avoid immediate re-triggering
          Future.delayed(const Duration(seconds: 5), () {
            _permissionCompleter = null;
          });
        }
      }
      
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 10,
        ),
      );
    } catch (e) {
      final errorMsg = e.toString();
      // Silencing the 'Position update is unavailable' error which spams logs on Chrome/Web
      if (!errorMsg.contains("Position update is unavailable")) {
        debugPrint("Location update failed: $e");
      }
      return null;
    }
  }

  double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, LatLng(startLat, startLng), LatLng(endLat, endLng)) / 1000;
  }

  String estimateTravelTime(double distanceKm) {
    // Average speed in city: 30 km/h
    final totalMinutes = (distanceKm / 30) * 60;
    if (totalMinutes < 1) return 'Less than 1 min';
    if (totalMinutes < 60) return '${totalMinutes.round()} mins';
    final hours = (totalMinutes / 60).floor();
    final mins = (totalMinutes % 60).round();
    return '${hours}h ${mins}m';
  }
}
