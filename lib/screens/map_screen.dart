import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

import '../models/route.dart';
import '../models/vehicle_marker.dart';
import '../models/route_path.dart';
import '../services/api_service.dart';
import '../services/favorites_service.dart';

class MapScreen extends StatefulWidget {
  final RouteWay selectedRoute;

  const MapScreen({super.key, required this.selectedRoute});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final ApiService _apiService = ApiService();
  final FavoritesService _favoritesService = FavoritesService();

  final MapController _mapController = MapController();

  List<TransportRouteGroup> _routes = [];
  List<RouteWay> _favorites = [];
  RouteWay? _currentRoute;
  List<VehicleMarker> _vehicleMarkers = [];
  RoutePath? _routePath;
  bool _isLoading = false;
  String? _selectedStopName;
  VehicleMarker? _selectedVehicle;

  final List<Marker> _stopMarkers = [];
  final List<Marker> _vehicleMarkersLayer = [];
  final List<Polyline> _polylines = [];

  @override
  void initState() {
    super.initState();
    _currentRoute = widget.selectedRoute;
    _loadData();
    _loadRouteData();
  }

  Future<void> _loadData() async {
    try {
      final routes = await _apiService.getRoutes();
      final favorites = await _favoritesService.getFavorites();
      
      setState(() {
        _routes = routes;
        _favorites = favorites;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки данных: $e')),
        );
      }
    }
  }

  Future<void> _loadRouteData() async {
    if (_currentRoute == null) return;

    setState(() {
      _isLoading = true;
      _selectedStopName = null;
      _selectedVehicle = null;
      _stopMarkers.clear();
      _vehicleMarkersLayer.clear();
      _polylines.clear();
    });

    try {
      final routeUrl = _currentRoute!.apiUrl;
      
      final markers = await _apiService.getVehicleMarkers(routeUrl);
      final path = await _apiService.getRoutePath(routeUrl);
      
      setState(() {
        _vehicleMarkers = markers;
        _routePath = path;
        _isLoading = false;
      });
      
      _updateMapObjects(moveCameraToRoute: true);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки маршрута: $e')),
        );
      }
    }
  }

  Future<void> _refreshVehicleMarkers() async {
    if (_currentRoute == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final routeUrl = _currentRoute!.apiUrl;
      final markers = await _apiService.getVehicleMarkers(routeUrl);

      setState(() {
        _vehicleMarkers = markers;
        _isLoading = false;
      });

      _updateVehicleMarkersLayer();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обновления транспорта: $e')),
        );
      }
    }
  }

  String _vehicleKey(VehicleMarker v) =>
      '${v.idTypetr}|${v.marsh}|${v.graph}|${v.direction}|${v.segmentOrder}';

  void _updateMapObjects({required bool moveCameraToRoute}) {
    _stopMarkers.clear();
    _polylines.clear();

    // Линия маршрута
    if (_routePath != null && _routePath!.points.isNotEmpty) {
      final routePoints = _routePath!.points
          .map((p) => LatLng(p.lat, p.lng))
          .toList();

      _polylines.add(
        Polyline(
          points: routePoints,
          color: Colors.blueAccent,
          strokeWidth: 4,
        ),
      );

      // Остановки
      for (var i = 0; i < _routePath!.points.length; i++) {
        final p = _routePath!.points[i];
        if (p.isStop && (p.name?.isNotEmpty ?? false)) {
          final stopName = p.name!;
          _stopMarkers.add(
            Marker(
              point: LatLng(p.lat, p.lng),
              width: 32,
              height: 32,
              builder: (ctx) => GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedStopName = stopName;
                    _selectedVehicle = null;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.directions_bus,
                    size: 16,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ),
          );
        }
      }

      if (moveCameraToRoute) {
        _moveCameraToCenter(_routePath!.points);
      }
    }

    _updateVehicleMarkersLayer();

    setState(() {});
  }

  void _updateVehicleMarkersLayer() {
    _vehicleMarkersLayer.clear();

    final selectedKey =
        _selectedVehicle == null ? null : _vehicleKey(_selectedVehicle!);
    VehicleMarker? refreshedSelected;

    // Маркеры транспорта
    for (final marker in _vehicleMarkers) {
      if (selectedKey != null && _vehicleKey(marker) == selectedKey) {
        refreshedSelected = marker;
      }
      // Коррекция поворота стрелки:
      // ((-apiAz + 85) % 360 + 360) % 360
      final int apiAz = marker.azimuth;
      final int correctedAz =
          (((-apiAz + 85) % 360) + 360) % 360; // в градусах, 0–359
      final double angleRad = correctedAz * math.pi / 180.0;

      _vehicleMarkersLayer.add(
        Marker(
          point: LatLng(marker.lat, marker.lng),
          width: 32,
          height: 32,
          builder: (ctx) => GestureDetector(
            onTap: () {
              setState(() {
                _selectedVehicle = marker;
                _selectedStopName = null;
              });
            },
            child: Transform.rotate(
              angle: angleRad,
              child: const Icon(
                Icons.navigation, // стрелка
                color: Colors.black87,
                size: 24,
              ),
            ),
          ),
        ),
      );
    }

    if (_selectedVehicle != null) {
      setState(() {
        _selectedVehicle = refreshedSelected;
        if (refreshedSelected == null) {
          // Выбранный транспорт пропал из онлайна
          _selectedVehicle = null;
        }
      });
    }
  }

  void _moveCameraToCenter(List<RoutePathPoint> points) {
    if (points.isEmpty) return;

    double minLat = points.first.lat;
    double maxLat = points.first.lat;
    double minLng = points.first.lng;
    double maxLng = points.first.lng;

    for (final p in points) {
      if (p.lat < minLat) minLat = p.lat;
      if (p.lat > maxLat) maxLat = p.lat;
      if (p.lng < minLng) minLng = p.lng;
      if (p.lng > maxLng) maxLng = p.lng;
    }

    final center = LatLng(
      (minLat + maxLat) / 2,
      (minLng + maxLng) / 2,
    );

    _mapController.move(center, 12);
  }

  Future<void> _toggleFavorite(RouteWay route) async {
    final isFavorite = await _favoritesService.isFavorite(route);
    
    if (isFavorite) {
      await _favoritesService.removeFavorite(route);
    } else {
      await _favoritesService.addFavorite(route);
    }
    
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Карта маршрута'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Обновить транспорт',
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshVehicleMarkers,
          ),
          if (_currentRoute != null)
            FutureBuilder<bool>(
              future: _favoritesService.isFavorite(_currentRoute!),
              builder: (context, snapshot) {
                final isFav = snapshot.data ?? false;
                return IconButton(
                  tooltip: isFav ? 'Убрать из избранного' : 'В избранное',
                  icon: Icon(
                    isFav ? Icons.star_rounded : Icons.star_border_rounded,
                    color: isFav ? Colors.amber : Colors.white,
                  ),
                  onPressed: () => _toggleFavorite(_currentRoute!),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Route selection dropdown
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: _buildRouteDropdown(),
          ),
          
          // Map
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: LatLng(55.0084, 82.9357),
                    zoom: 12,
                    minZoom: 5,
                    maxZoom: 18,
                    onTap: (_, _) {
                      setState(() {
                        _selectedStopName = null;
                        _selectedVehicle = null;
                      });
                    },
                  ),
                  children: [
                    // OpenStreetMap tiles
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.dolphinart.nsk_transport_map',
                      tileSize: 256,
                    ),
                    PolylineLayer(
                      polylines: _polylines,
                    ),
                    MarkerLayer(
                      markers: [
                        ..._stopMarkers,
                        ..._vehicleMarkersLayer,
                      ],
                    ),
                  ],
                ),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),

                // Баббл остановки сверху
                if (_selectedStopName != null)
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
                      child: _buildStopBubble(),
                    ),
                  ),

                // Баббл транспорта снизу
                if (_selectedVehicle != null)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildVehicleBubble(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteDropdown() {
    final onlineCount = _vehicleMarkers.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<RouteWay>(
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Выберите маршрут',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.directions_bus),
          ),
          initialValue: _currentRoute,
          items: _buildDropdownItems(),
          onChanged: (RouteWay? route) {
            if (route != null) {
              setState(() {
                _currentRoute = route;
              });
              _loadRouteData();
            }
          },
        ),
        const SizedBox(height: 6),
        Text(
          'Онлайн: $onlineCount',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  List<DropdownMenuItem<RouteWay>> _buildDropdownItems() {
    final items = <DropdownMenuItem<RouteWay>>[];
    
    // Add favorites first
    if (_favorites.isNotEmpty) {
      items.add(
        DropdownMenuItem<RouteWay>(
          enabled: false,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  fit: FlexFit.loose,
                  child: Text(
                    'Избранные',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      
      for (var favorite in _favorites) {
        items.add(
          DropdownMenuItem<RouteWay>(
            value: favorite,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  fit: FlexFit.loose,
                  child: Text(
                    favorite.displayName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      
      items.add(
        DropdownMenuItem<RouteWay>(
          enabled: false,
          child: Container(
            height: 1,
            color: Colors.grey[300],
            margin: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      );
    }
    
    // Add routes grouped by type
    for (var route in _routes) {
      items.add(
        DropdownMenuItem<RouteWay>(
          enabled: false,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Text(
              route.transportTypeName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
        ),
      );
      
      for (var way in route.ways) {
        final isFav = _favorites.any((fav) => 
            fav.marsh == way.marsh && fav.type == way.type);
        // На экране карты не дублируем избранные маршруты:
        // если маршрут уже в секции "Избранные", в общем списке его пропускаем.
        if (isFav) {
          continue;
        }

        items.add(
          DropdownMenuItem<RouteWay>(
            value: way,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isFav) ...[
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                ] else ...[
                  const SizedBox(width: 28),
                ],
                Flexible(
                  fit: FlexFit.loose,
                  child: Text(
                    way.displayName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    
    return items;
  }

  Widget _buildStopBubble() {
    final stopName = _selectedStopName ?? '';
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedStopName = null;
          });
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.directions_bus,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  stopName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleBubble() {
    final v = _selectedVehicle!;
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedVehicle = null;
          });
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.directions_bus,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Маршрут ${v.title}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'График ${v.graph} • Скорость ${v.speed} км/ч',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Обновлено: ${v.timeNav}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                v.scheduleText,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                v.rampText,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
