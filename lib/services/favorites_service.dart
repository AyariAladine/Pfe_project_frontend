import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing favorite properties using local storage
class FavoritesService extends ChangeNotifier {
  static const String _key = 'favorite_property_ids';
  Set<String> _favoriteIds = {};
  bool _loaded = false;

  Set<String> get favoriteIds => _favoriteIds;
  bool get isLoaded => _loaded;

  /// Load favorites from local storage
  Future<void> loadFavorites() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    _favoriteIds = list.toSet();
    _loaded = true;
    notifyListeners();
  }

  /// Check if a property is favorited
  bool isFavorite(String propertyId) => _favoriteIds.contains(propertyId);

  /// Toggle favorite status
  Future<void> toggleFavorite(String propertyId) async {
    if (_favoriteIds.contains(propertyId)) {
      _favoriteIds.remove(propertyId);
    } else {
      _favoriteIds.add(propertyId);
    }
    notifyListeners();
    await _persist();
  }

  /// Remove from favorites
  Future<void> removeFavorite(String propertyId) async {
    _favoriteIds.remove(propertyId);
    notifyListeners();
    await _persist();
  }

  int get count => _favoriteIds.length;

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _favoriteIds.toList());
  }
}
