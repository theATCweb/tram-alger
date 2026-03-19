import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../core/config.dart';

class GpsService {
  StreamSubscription<Position>? _positionSubscription;
  Position? _lastPosition;

  Future<bool> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  Position? get lastPosition => _lastPosition;

  void startTracking(void Function(Position) onPosition) {
    _positionSubscription = Geolocator.getPositionStream(
      desiredAccuracy: LocationAccuracy.medium,
      distanceFilter: 30,
    ).listen((position) {
      _lastPosition = position;
      onPosition(position);
    });
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  bool isMoving(Position position) {
    return position.speed * 3.6 > AppConfig.gpsMinSpeedKmh;
  }

  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) return null;
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      return null;
    }
  }
}
