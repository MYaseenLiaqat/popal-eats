import 'package:geolocator/geolocator.dart';

import '../models/group_member_location.dart';

/// Reads device GPS coordinates with permission handling.
class DeviceLocationService {
  Future<bool> isLocationServiceEnabled() => Geolocator.isLocationServiceEnabled();

  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  Future<LocationPermission> requestPermission() => Geolocator.requestPermission();

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  Future<void> openAppSettings() => Geolocator.openAppSettings();

  Future<DevicePosition> getCurrentPosition() async {
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationAccessException(
        LocationAccessFailure.serviceDisabled,
        'Location services are turned off on this device.',
      );
    }

    var permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw LocationAccessException(
        LocationAccessFailure.permissionDenied,
        'Location permission is required to share your position with the group.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationAccessException(
        LocationAccessFailure.permissionDeniedForever,
        'Location permission was permanently denied. Enable it in app settings.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return DevicePosition(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      throw LocationAccessException(
        LocationAccessFailure.unavailable,
        'Could not determine your current location. Try again.',
      );
    }
  }
}
