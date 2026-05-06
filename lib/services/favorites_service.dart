import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import 'token_service.dart';

/// Service for managing favorite properties.
/// Uses SharedPreferences as the local cache and syncs with the backend
/// (POST/DELETE /users/favorites/:id) when a user is authenticated.
class FavoritesService extends ChangeNotifier {
  static const String _localKey = 'favorite_property_ids';

  Set<String> _favoriteIds = {};
  bool _loaded = false;

  Set<String> get favoriteIds => _favoriteIds;
  bool get isLoaded => _loaded;
  int get count => _favoriteIds.length;

  bool isFavorite(String propertyId) => _favoriteIds.contains(propertyId);

  /// Load favorites: try backend first, fall back to local cache.
  Future<void> loadFavorites() async {
    if (_loaded) return;
    // Load local cache immediately so UI renders fast
    final prefs = await SharedPreferences.getInstance();
    final local = prefs.getStringList(_localKey) ?? [];
    _favoriteIds = local.toSet();
    _loaded = true;
    notifyListeners();

    // Then sync from backend (overwrites local with server truth)
    await _syncFromBackend();
  }

  Future<void> _syncFromBackend() async {
    try {
      final token = await TokenService.getAccessToken();
      if (token == null) return;
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.favorites}');
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.isNotEmpty) {
          final decoded = jsonDecode(body);
          if (decoded is List) {
            final serverIds = decoded.map((e) => e.toString()).toSet();
            _favoriteIds = serverIds;
            await _persistLocal();
            notifyListeners();
          }
        }
      }
    } catch (_) {
      // Network unavailable — local cache is already loaded, nothing to do
    }
  }

  /// Toggle favorite status. Updates locally immediately, then syncs to backend.
  Future<void> toggleFavorite(String propertyId) async {
    final wasAdded = _favoriteIds.contains(propertyId);
    if (wasAdded) {
      _favoriteIds.remove(propertyId);
    } else {
      _favoriteIds.add(propertyId);
    }
    notifyListeners();
    await _persistLocal();
    await _pushToBackend(propertyId, add: !wasAdded);
  }

  Future<void> removeFavorite(String propertyId) async {
    if (!_favoriteIds.contains(propertyId)) return;
    _favoriteIds.remove(propertyId);
    notifyListeners();
    await _persistLocal();
    await _pushToBackend(propertyId, add: false);
  }

  Future<void> _pushToBackend(String propertyId, {required bool add}) async {
    try {
      final token = await TokenService.getAccessToken();
      if (token == null) return;
      final uri = Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.favoriteProperty(propertyId)}');
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };
      if (add) {
        await http.post(uri, headers: headers).timeout(const Duration(seconds: 10));
      } else {
        await http.delete(uri, headers: headers).timeout(const Duration(seconds: 10));
      }
    } catch (_) {
      // Backend unreachable — local state already reflects the change
    }
  }

  Future<void> _persistLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_localKey, _favoriteIds.toList());
  }
}
