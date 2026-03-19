import 'dart:async';
import 'package:flutter/material.dart';
import '../models/eta_result.dart';
import '../services/api_service.dart';

class EtaProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  final Map<String, EtaResult> _etas = {};
  Timer? _refreshTimer;

  Map<String, EtaResult> get etas => _etas;

  EtaResult? getEta(int stationId, int direction) {
    return _etas['${stationId}_$direction'];
  }

  Future<void> loadEta(int stationId, int direction) async {
    final eta = await _apiService.getEta(stationId, direction);
    _etas['${stationId}_$direction'] = eta;
    notifyListeners();
  }

  Future<void> loadAllEtas(List<int> stationIds, int direction) async {
    for (final id in stationIds) {
      await loadEta(id, direction);
    }
  }

  void startAutoRefresh(List<int> stationIds, int direction) {
    stopAutoRefresh();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      loadAllEtas(stationIds, direction);
    });
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}
