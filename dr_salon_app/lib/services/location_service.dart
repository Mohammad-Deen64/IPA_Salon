import 'package:geolocator/geolocator.dart';

class UserLocation {
  const UserLocation({this.latitude, this.longitude, required this.message, required this.usedGps});

  final double? latitude;
  final double? longitude;
  final String message;
  final bool usedGps;
}

class LocationService {
  Future<UserLocation> current() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        return const UserLocation(
          message: 'Location is turned off. Browsing all salons.',
          usedGps: false,
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const UserLocation(
          message: 'Location permission denied. Browsing all salons.',
          usedGps: false,
        );
      }
      if (permission == LocationPermission.deniedForever) {
        return const UserLocation(
          message: 'Location permission is blocked. Browsing all salons.',
          usedGps: false,
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 3),
        ),
      );
      return UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        message: 'Showing salons near you.',
        usedGps: true,
      );
    } catch (_) {
      return const UserLocation(
        message: 'Could not read your location. Browsing all salons.',
        usedGps: false,
      );
    }
  }
}
