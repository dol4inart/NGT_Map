class TransportRouteGroup {
  final int type;
  final List<RouteWay> ways;

  TransportRouteGroup({
    required this.type,
    required this.ways,
  });

  factory TransportRouteGroup.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as int;
    return TransportRouteGroup(
      type: type,
      ways: (json['ways'] as List)
          .map((way) => RouteWay.fromJson(way as Map<String, dynamic>, type))
          .toList(),
    );
  }

  String get transportTypeName {
    switch (type) {
      case 0:
        return 'Автобус';
      case 1:
        return 'Троллейбус';
      case 2:
        return 'Трамвай';
      case 7:
        return 'Маршрутное такси';
      default:
        return 'Неизвестно';
    }
  }

  int get apiType => type + 1;
}

class RouteWay {
  final String marsh;
  final String name;
  final String stopb;
  final String stope;
  final int type;

  RouteWay({
    required this.marsh,
    required this.name,
    required this.stopb,
    required this.stope,
    required this.type,
  });

  factory RouteWay.fromJson(Map<String, dynamic> json, int type) {
    return RouteWay(
      marsh: (json['marsh'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      stopb: (json['stopb'] ?? '').toString(),
      stope: (json['stope'] ?? '').toString(),
      type: type,
    );
  }

  String get displayName => '$name ($stopb - $stope)';

  String get apiUrl {
    final apiType = type + 1;
    return '$apiType-$marsh-W-$name';
  }

  Map<String, dynamic> toJson() {
    return {
      'marsh': marsh,
      'name': name,
      'stopb': stopb,
      'stope': stope,
      'type': type,
    };
  }

  factory RouteWay.fromJsonMap(Map<String, dynamic> json) {
    return RouteWay(
      marsh: (json['marsh'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      stopb: (json['stopb'] ?? '').toString(),
      stope: (json['stope'] ?? '').toString(),
      type: (json['type'] is int) ? (json['type'] as int) : int.tryParse((json['type'] ?? '0').toString()) ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RouteWay &&
        other.type == type &&
        other.marsh == marsh &&
        other.name == name;
  }

  @override
  int get hashCode => Object.hash(type, marsh, name);
}
