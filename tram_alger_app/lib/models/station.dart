class Station {
  final int id;
  final String name;
  final String? nameAr;
  final double lat;
  final double lng;
  final int sequence;
  final int routeId;
  final bool isTerminal;

  Station({
    required this.id,
    required this.name,
    this.nameAr,
    required this.lat,
    required this.lng,
    required this.sequence,
    required this.routeId,
    required this.isTerminal,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'] as int,
      name: json['name'] as String,
      nameAr: json['name_ar'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      sequence: json['sequence'] as int,
      routeId: json['route_id'] as int,
      isTerminal: json['is_terminal'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_ar': nameAr,
      'lat': lat,
      'lng': lng,
      'sequence': sequence,
      'route_id': routeId,
      'is_terminal': isTerminal,
    };
  }
}
