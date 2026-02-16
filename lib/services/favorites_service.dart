import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/route.dart';

class FavoritesService {
  static const String _favoritesKey = 'favorite_routes';

  Future<List<RouteWay>> getFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? favoritesJson = prefs.getString(_favoritesKey);
      
      if (favoritesJson == null || favoritesJson.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(favoritesJson);
      return jsonList
          .map((json) => RouteWay.fromJsonMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addFavorite(RouteWay route) async {
    try {
      final favorites = await getFavorites();
      
      // Check if already exists
      if (favorites.any((fav) => 
          fav.marsh == route.marsh && fav.type == route.type)) {
        return;
      }

      favorites.add(route);
      await _saveFavorites(favorites);
    } catch (e) {
      throw Exception('Error adding favorite: $e');
    }
  }

  Future<void> removeFavorite(RouteWay route) async {
    try {
      final favorites = await getFavorites();
      favorites.removeWhere((fav) => 
          fav.marsh == route.marsh && fav.type == route.type);
      await _saveFavorites(favorites);
    } catch (e) {
      throw Exception('Error removing favorite: $e');
    }
  }

  Future<bool> isFavorite(RouteWay route) async {
    final favorites = await getFavorites();
    return favorites.any((fav) => 
        fav.marsh == route.marsh && fav.type == route.type);
  }

  Future<void> _saveFavorites(List<RouteWay> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = json.encode(
      favorites.map((fav) => fav.toJson()).toList(),
    );
    await prefs.setString(_favoritesKey, jsonString);
  }
}
