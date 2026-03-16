import 'package:flutter/material.dart';
import '../models/route.dart';
import '../services/api_service.dart';
import '../services/favorites_service.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final FavoritesService _favoritesService = FavoritesService();
  
  List<TransportRouteGroup> _routes = [];
  List<RouteWay> _favorites = [];
  bool _isLoading = true;
  RouteWay? _selectedRoute;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final routes = await _apiService.getRoutes();
      final favorites = await _favoritesService.getFavorites();
      
      setState(() {
        _routes = routes;
        _favorites = favorites;
        _isLoading = false;
      });
    } catch (e) {
      // Helpful for debugging on desktop / emulator logs.
      // ignore: avoid_print
      print('HomeScreen _loadData error: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки данных: $e')),
        );
      }
    }
  }

  Future<void> _openMapScreen(RouteWay route) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(selectedRoute: route),
      ),
    );

    // После возврата с экрана карты обновляем избранное/список маршрутов,
    // т.к. пользователь мог изменить избранное на карте.
    if (!mounted) return;
    _loadData();
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
        title: const Text('Карта общественного транспорта'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_routes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Маршруты не загрузились.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _loadData,
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
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
                
                // Favorites section
                if (_favorites.isNotEmpty)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Избранные маршруты',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _favorites.length,
                            itemBuilder: (context, index) {
                              final favorite = _favorites[index];
                              return _buildRouteCard(favorite, isFavorite: true);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            )),
    );
  }

  Widget _buildRouteDropdown() {
    return DropdownButtonFormField<RouteWay>(
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Выберите маршрут',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.directions_bus),
      ),
      initialValue: _selectedRoute,
      items: _buildDropdownItems(),
      onChanged: (RouteWay? route) {
        if (route != null) {
          setState(() {
            _selectedRoute = route;
          });
          _openMapScreen(route);
        }
      },
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
            child: Text(
              'Избранные',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
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

  Widget _buildRouteCard(RouteWay route, {bool isFavorite = false}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTransportColor(route.type),
          child: Text(
            route.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(route.name),
        subtitle: Text('${route.stopb} → ${route.stope}'),
        trailing: IconButton(
          icon: Icon(
            isFavorite ? Icons.star : Icons.star_border,
            color: isFavorite ? Colors.amber : Colors.grey,
          ),
          onPressed: () => _toggleFavorite(route),
        ),
        onTap: () => _openMapScreen(route),
      ),
    );
  }

  Color _getTransportColor(int type) {
    switch (type) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.green;
      case 2:
        return Colors.red;
      case 7:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
