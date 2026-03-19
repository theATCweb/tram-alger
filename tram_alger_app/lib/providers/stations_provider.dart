import 'package:flutter/material.dart';
import '../core/config.dart';
import '../models/station.dart';
import '../services/api_service.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class StationsProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Station> _outboundStations = [];
  List<Station> _inboundStations = [];
  bool _loading = false;
  String? _error;

  List<Station> get outboundStations => _outboundStations;
  List<Station> get inboundStations => _inboundStations;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadStations() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _outboundStations = await _apiService.getStations(AppConfig.outboundRouteId);
      _inboundStations = await _apiService.getStations(AppConfig.inboundRouteId);
      
      if (_outboundStations.isEmpty) {
        _outboundStations = await _loadFallbackStations(AppConfig.outboundRouteId);
      }
    } catch (e) {
      _error = e.toString();
      _outboundStations = await _loadFallbackStations(AppConfig.outboundRouteId);
    }

    _loading = false;
    notifyListeners();
  }

  Future<List<Station>> _loadFallbackStations(int routeId) async {
    try {
      final jsonString = await rootBundle.loadString('assets/stations_fallback.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((e) => Station.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }
}
