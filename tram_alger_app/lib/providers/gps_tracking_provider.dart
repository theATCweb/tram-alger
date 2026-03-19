import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../core/config.dart';
import '../core/device_id.dart';
import '../services/api_service.dart';
import '../services/gps_service.dart';

class GpsTrackingProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final GpsService _gpsService = GpsService();
  
  bool _isTracking = false;
  bool _hasPermission = false;
  int _direction = 0;
  Timer? _pingTimer;
  Timer? _autoStopTimer;

  bool get isTracking => _isTracking;
  bool get hasPermission => _hasPermission;
  int get direction => _direction;

  Future<bool> checkPermission() async {
    _hasPermission = await _gpsService.checkPermission();
    notifyListeners();
    return _hasPermission;
  }

  Future<void> startTracking(int direction) async {
    _direction = direction;
    _hasPermission = await _gpsService.checkPermission();
    
    if (!_hasPermission) {
      notifyListeners();
      return;
    }

    _isTracking = true;
    notifyListeners();

    _gpsService.startTracking(_onPosition);

    _pingTimer = Timer.periodic(
      Duration(seconds: AppConfig.gpsPingIntervalSec),
      (_) => _sendPing(),
    );

    _autoStopTimer = Timer(
      Duration(seconds: AppConfig.gpsAutoStopSec),
      stopTracking,
    );
  }

  void _onPosition(Position position) {
    if (_gpsService.isMoving(position)) {
      _sendPing();
    }
  }

  Future<void> _sendPing() async {
    final position = await _gpsService.getCurrentPosition();
    if (position == null) return;

    final deviceToken = await DeviceId.get();
    await _apiService.sendGpsPing(
      deviceToken: deviceToken,
      lat: position.latitude,
      lng: position.longitude,
      accuracyM: position.accuracy,
      speedKmh: position.speed * 3.6,
      bearing: position.heading.toInt(),
      direction: _direction,
    );
  }

  void stopTracking() {
    _isTracking = false;
    _pingTimer?.cancel();
    _pingTimer = null;
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    _gpsService.stopTracking();
    notifyListeners();
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}
