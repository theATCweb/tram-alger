class EtaResult {
  final int stationId;
  final int direction;
  final String? etaIso;
  final int? secondsAway;
  final String source;
  final double confidence;
  final String? message;

  EtaResult({
    required this.stationId,
    required this.direction,
    this.etaIso,
    this.secondsAway,
    required this.source,
    required this.confidence,
    this.message,
  });

  factory EtaResult.fromJson(Map<String, dynamic> json) {
    return EtaResult(
      stationId: json['station_id'] as int,
      direction: json['direction'] as int,
      etaIso: json['eta_iso'] as String?,
      secondsAway: json['seconds_away'] as int?,
      source: json['source'] as String? ?? 'none',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      message: json['message'] as String?,
    );
  }

  factory EtaResult.noData(int stationId, int direction) {
    return EtaResult(
      stationId: stationId,
      direction: direction,
      source: 'none',
      confidence: 0.0,
      message: 'No data available',
    );
  }

  bool get hasData => source != 'none' && secondsAway != null;

  String get formattedTime {
    if (secondsAway == null) return '--';
    final mins = secondsAway! ~/ 60;
    final secs = secondsAway! % 60;
    return '${mins}m ${secs}s';
  }

  String get formattedMinutes {
    if (secondsAway == null) return '--';
    return '${secondsAway! ~/ 60} min';
  }

  String get exactTime {
    if (etaIso == null) return '--';
    try {
      final time = etaIso!.split('T')[1].split('+')[0];
      return time.substring(0, 5);
    } catch (_) {
      return '--';
    }
  }

  String get sourceLabel {
    switch (source) {
      case 'gps':
        return 'GPS temps reel';
      case 'schedule':
        return 'Horaire';
      default:
        return 'Aucune donnee';
    }
  }
}
