import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/station.dart';
import '../models/eta_response.dart';

class ApiService {
  static const String baseUrl = 'https://tram-alger-production.up.railway.app';
  static const int outboundRouteId = 4;
  static const int inboundRouteId = 5;

  Future<List<Station>> getStations({required int routeId}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/stations/?route_id=$routeId'),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Station.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load stations: ${response.statusCode}');
    }
  }

  Future<ETAResponse> getETA({
    required int stationId,
    required int direction,
  }) async {
    final routeId = direction == 0 ? outboundRouteId : inboundRouteId;
    final response = await http.get(
      Uri.parse('$baseUrl/eta/$stationId?direction=$direction&route_id=$routeId'),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return ETAResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load ETA: ${response.statusCode}');
    }
  }

  Future<bool> sendGPSPing({
    required String deviceToken,
    required double lat,
    required double lng,
    required double accuracyM,
    required double speedKmh,
    required int bearing,
    required int direction,
  }) async {
    final routeId = direction == 0 ? outboundRouteId : inboundRouteId;
    final response = await http.post(
      Uri.parse('$baseUrl/gps/ping'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'device_token': deviceToken,
        'lat': lat,
        'lng': lng,
        'accuracy_m': accuracyM,
        'speed_kmh': speedKmh,
        'bearing': bearing,
        'route_id': routeId,
        'direction': direction,
        'sequence': 0,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['accepted'] ?? false;
    }
    return false;
  }

  Future<Map<String, dynamic>> getStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/stats'),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return {};
  }
}
