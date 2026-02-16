class VehicleMarker {
  final String title;
  final String idTypetr;
  final String marsh;
  final String graph;
  final String direction;
  final double lat;
  final double lng;
  final String timeNav;
  final int azimuth;
  final String rasp;
  final int speed;
  final String segmentOrder;
  final int ramp;

  VehicleMarker({
    required this.title,
    required this.idTypetr,
    required this.marsh,
    required this.graph,
    required this.direction,
    required this.lat,
    required this.lng,
    required this.timeNav,
    required this.azimuth,
    required this.rasp,
    required this.speed,
    required this.segmentOrder,
    required this.ramp,
  });

  factory VehicleMarker.fromJson(Map<String, dynamic> json) {
    return VehicleMarker(
      title: json['title'] as String,
      idTypetr: json['id_typetr'] as String,
      marsh: json['marsh'] as String,
      graph: json['graph'] as String,
      timeNav: json['time_nav'] as String,
      direction: json['direction'] as String,
      lat: double.parse(json['lat'] as String),
      lng: double.parse(json['lng'] as String),
      azimuth: int.parse(json['azimuth'] as String),
      rasp: json['rasp'] as String,
      speed: int.parse(json['speed'] as String),
      segmentOrder: json['segment_order'] as String,
      ramp: int.parse(json['ramp'] as String),
    );
  }

  String get rampText => ramp == 1 
      ? 'Есть низкий пол/аппарель' 
      : 'Нет низкого пола/аппарели';

  String get scheduleText {
    if (rasp.contains('Обеденный+перерыв')) {
      return 'Перерыв';
    }
    return rasp.replaceAll('|', '\n').replaceAll('+', ' - ');
  }
}
