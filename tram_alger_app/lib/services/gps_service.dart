import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../core/config.dart';

class GpsService {
  StreamSubscription<Position>? _positionStream;
  Position? _lastPosition;
  void Function(Position)? _onPositionUpdate;

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
    _onPositionUpdate = onPosition;
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 30,
      ),
    ).listen((Position position) {
      _onPositionUpdate!(position);
    });
  }

  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    _onPositionUpdate = null;
  }

  bool isMoving(Position position) {
    return position.speed * 3.6 > AppConfig.gpsMinSpeedKmh;
  }

  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) return null;
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      return null;
    }
  }
}
