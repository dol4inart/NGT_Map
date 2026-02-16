class RoutePath {
  final List<RoutePathPoint> points;

  RoutePath({required this.points});

  factory RoutePath.fromJson(Map<String, dynamic> json) {
    final trasses = json['trasses'] as List;
    final points = <RoutePathPoint>[];
    
    for (var trass in trasses) {
      final r = trass['r'] as List;
      for (var route in r) {
        final u = route['u'] as List;
        for (var point in u) {
          final pointData = point as Map<String, dynamic>;
          if (pointData.containsKey('lat') && pointData.containsKey('lng')) {
            points.add(RoutePathPoint.fromJson(pointData));
          }
        }
      }
    }
    
    return RoutePath(points: points);
  }
}

class RoutePathPoint {
  final String? id;
  final String? name;
  final double lat;
  final double lng;
  final String len;

  RoutePathPoint({
    this.id,
    this.name,
    required this.lat,
    required this.lng,
    required this.len,
  });

  factory RoutePathPoint.fromJson(Map<String, dynamic> json) {
    return RoutePathPoint(
      id: json['id'] as String?,
      name: json['n'] as String?,
      lat: double.parse(json['lat'] as String),
      lng: double.parse(json['lng'] as String),
      len: json['len'] as String? ?? '0',
    );
  }

  bool get isStop => name != null && name!.isNotEmpty;
}
