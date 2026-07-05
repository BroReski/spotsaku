/// GPS location service wrapping `geolocator`.
///
/// Handles permission requests and current-position retrieval with
/// graceful fallback when the user denies location access.
library;

import 'package:geolocator/geolocator.dart';

/// Result of a location-fetch attempt.
sealed class LocationResult {
  const LocationResult();
}

class LocationSuccess extends LocationResult {
  const LocationSuccess(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}

class LocationDenied extends LocationResult {
  const LocationDenied(this.message);
  final String message;
}

class LocationError extends LocationResult {
  const LocationError(this.message);
  final String message;
}

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  /// Requests permission (if needed) and returns the current position.
  ///
  /// Returns [LocationDenied] when the user refuses permission so the UI
  /// can fall back to the manual URL field.
  Future<LocationResult> getCurrentLocation() async {
    try {
      // 1. Check if location services are enabled.
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationDenied(
          'Layanan lokasi nonaktif. Aktifkan GPS pada perangkat Anda.',
        );
      }

      // 2. Request / check permission.
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const LocationDenied(
          'Izin lokasi ditolak. Anda dapat memasukkan tautan Maps secara manual.',
        );
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationDenied(
          'Izin lokasi ditolak permanen. Aktifkan di pengaturan perangkat.',
        );
      }

      // 3. Get the current position.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return LocationSuccess(position.latitude, position.longitude);
    } catch (e) {
      return LocationError('Gagal mendapatkan lokasi: $e');
    }
  }
}
