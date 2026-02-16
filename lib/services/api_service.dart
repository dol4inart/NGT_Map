import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/route.dart';
import '../models/vehicle_marker.dart';
import '../models/route_path.dart';

class ApiService {
  static const String baseUrl = 'https://map.nskgortrans.ru';

  Future<List<TransportRouteGroup>> getRoutes() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/listmarsh.php?r&r=false'))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        // Decode bytes explicitly to avoid any encoding edge-cases.
        final body = utf8.decode(response.bodyBytes, allowMalformed: true);
        final decoded = json.decode(body);
        if (decoded is! List) {
          throw Exception('Unexpected routes payload: ${decoded.runtimeType}');
        }
        return decoded.map((e) => TransportRouteGroup.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load routes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching routes: $e');
    }
  }

  Future<List<VehicleMarker>> getVehicleMarkers(String routeUrl) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/markers.php?r=$routeUrl'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final List<dynamic> markersJson = json['markers'] as List;
        return markersJson
            .map((marker) => VehicleMarker.fromJson(marker as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load markers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching markers: $e');
    }
  }

  Future<RoutePath> getRoutePath(String routeUrl) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/trasses.php?r=$routeUrl'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        return RoutePath.fromJson(json);
      } else {
        throw Exception('Failed to load route path: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching route path: $e');
    }
  }
}
