class ETAResponse {
  final int stationId;
  final int direction;
  final String? etaIso;
  final int? secondsAway;
  final String source;
  final double confidence;
  final String? message;

  ETAResponse({
    required this.stationId,
    required this.direction,
    this.etaIso,
    this.secondsAway,
    required this.source,
    required this.confidence,
    this.message,
  });

  factory ETAResponse.fromJson(Map<String, dynamic> json) {
    return ETAResponse(
      stationId: json['station_id'],
      direction: json['direction'],
      etaIso: json['eta_iso'],
      secondsAway: json['seconds_away'],
      source: json['source'] ?? 'none',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      message: json['message'],
    );
  }

  String get formattedTime {
    if (secondsAway == null) return '--';
    final mins = secondsAway! ~/ 60;
    final secs = secondsAway! % 60;
    return '${mins}m ${secs}s';
  }
}
