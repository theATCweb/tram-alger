import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/config.dart';

class CacheService {
  static const String _stationsBox = 'stations_cache';
  static const String _etaBox = 'eta_cache';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_stationsBox);
    await Hive.openBox(_etaBox);
  }

  static Box get _stations => Hive.box(_stationsBox);
  static Box get _eta => Hive.box(_etaBox);

  static Future<List<Map<String, dynamic>>?> getStations(int routeId) async {
    final key = 'stations_$routeId';
    final data = _stations.get(key);
    if (data != null) {
      final timestamp = _stations.get('${key}_timestamp') as int?;
      if (timestamp != null) {
        final age = DateTime.now().millisecondsSinceEpoch - timestamp;
        final maxAge = AppConfig.stationCacheHours * 60 * 60 * 1000;
        if (age < maxAge) {
          return List<Map<String, dynamic>>.from(
            (data as List).map((e) => Map<String, dynamic>.from(e)),
          );
        }
      }
    }
    return null;
  }

  static Future<void> cacheStations(int routeId, List<Map<String, dynamic>> stations) async {
    final key = 'stations_$routeId';
    await _stations.put(key, stations);
    await _stations.put('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  static Future<Map<String, dynamic>?> getEta(int stationId, int direction) async {
    final key = 'eta_${stationId}_$direction';
    final data = _eta.get(key);
    if (data != null) {
      final timestamp = _eta.get('${key}_timestamp') as int?;
      if (timestamp != null) {
        final age = DateTime.now().millisecondsSinceEpoch - timestamp;
        final maxAge = AppConfig.etaCacheSec * 1000;
        if (age < maxAge) {
          return Map<String, dynamic>.from(data);
        }
      }
    }
    return null;
  }

  static Future<void> cacheEta(int stationId, int direction, Map<String, dynamic> eta) async {
    final key = 'eta_${stationId}_$direction';
    await _eta.put(key, eta);
    await _eta.put('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
  }
}
