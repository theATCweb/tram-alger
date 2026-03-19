import 'package:dio/dio.dart';
import '../core/config.dart';
import '../models/station.dart';
import '../models/eta_result.dart';
import 'cache_service.dart';

class ApiService {
  final Dio _dio;

  ApiService() : _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<List<Station>> getStations(int routeId) async {
    final cached = await CacheService.getStations(routeId);
    if (cached != null) {
      return cached.map((e) => Station.fromJson(e)).toList();
    }

    try {
      final response = await _dio.get('${AppConfig.apiBaseUrl}/stations/?route_id=$routeId');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final stations = data.map((e) => Station.fromJson(e)).toList();
        await CacheService.cacheStations(routeId, data.cast<Map<String, dynamic>>());
        return stations;
      }
    } catch (e) {
      if (cached != null) {
        return cached.map((e) => Station.fromJson(e)).toList();
      }
    }
    return [];
  }

  Future<EtaResult> getEta(int stationId, int direction) async {
    final cached = await CacheService.getEta(stationId, direction);
    if (cached != null) {
      return EtaResult.fromJson(cached);
    }

    try {
      final routeId = direction == 0 ? AppConfig.outboundRouteId : AppConfig.inboundRouteId;
      final response = await _dio.get(
        '${AppConfig.apiBaseUrl}/eta/$stationId?direction=$direction&route_id=$routeId',
      );
      if (response.statusCode == 200) {
        final eta = EtaResult.fromJson(response.data);
        await CacheService.cacheEta(stationId, direction, response.data);
        return eta;
      }
    } catch (e) {
      if (cached != null) {
        return EtaResult.fromJson(cached);
      }
    }
    return EtaResult.noData(stationId, direction);
  }

  Future<bool> sendGpsPing({
    required String deviceToken,
    required double lat,
    required double lng,
    required double accuracyM,
    required double speedKmh,
    required int bearing,
    required int direction,
  }) async {
    try {
      final routeId = direction == 0 ? AppConfig.outboundRouteId : AppConfig.inboundRouteId;
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/gps/ping',
        data: {
          'device_token': deviceToken,
          'lat': lat,
          'lng': lng,
          'accuracy_m': accuracyM,
          'speed_kmh': speedKmh,
          'bearing': bearing,
          'route_id': routeId,
          'direction': direction,
          'sequence': 0,
        },
      );
      if (response.statusCode == 200) {
        return response.data['accepted'] ?? false;
      }
    } catch (e) {
      // Silently ignore GPS ping failures
    }
    return false;
  }
}
