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
      id: json['id'],
      name: json['name'],
      nameAr: json['name_ar'],
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      sequence: json['sequence'],
      routeId: json['route_id'],
      isTerminal: json['is_terminal'],
    );
  }
}
