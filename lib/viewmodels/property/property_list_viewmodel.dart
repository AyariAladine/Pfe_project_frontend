import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/property_model.dart';
import '../../services/property_service.dart';
import '../../services/api_service.dart';
import '../../services/geocoding_service.dart';
import '../../services/cache_service.dart';

enum PropertySortMode { newest, nearest }

/// ViewModel for listing properties
class PropertyListViewModel extends ChangeNotifier {
  final PropertyService _propertyService = PropertyService();
  final GeocodingService _geocodingService = GeocodingService();

  // Raw data
  List<PropertyModel> _myProperties = [];
  List<PropertyModel> _allProperties = [];

  // State
  bool _isLoading = false;
  String? _error;

  // Search & Filter state
  String _searchQuery = '';
  PropertyType? _filterType;
  PropertyStatus? _filterStatus;
  PropertySortMode _sortMode = PropertySortMode.newest;

  // User location
  double? _userLat;
  double? _userLng;
  bool _locationLoading = false;

  // Pagination
  static const int _pageSize = 10;
  int _displayCount = 10;

  // Getters (raw)
  List<PropertyModel> get myProperties => _myProperties;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasProperties => _myProperties.isNotEmpty;

  // Filter getters
  String get searchQuery => _searchQuery;
  PropertyType? get filterType => _filterType;
  PropertyStatus? get filterStatus => _filterStatus;
  PropertySortMode get sortMode => _sortMode;
  double? get userLat => _userLat;
  double? get userLng => _userLng;
  bool get locationLoading => _locationLoading;
  bool get hasUserLocation => _userLat != null && _userLng != null;

  // Pagination getters
  int get displayCount => _displayCount;
  bool get hasMoreItems {
    final total = _filteredAvailableProperties.length;
    return _displayCount < total;
  }

  /// Full filtered + sorted available properties (internal)
  List<PropertyModel> get _filteredAvailableProperties {
    // When no status filter is active, show only available properties by default.
    // When a status filter is set, respect it and show all matching statuses.
    var list = _filterStatus != null
        ? _allProperties.toList()
        : _allProperties
            .where((p) => p.propertyStatus == PropertyStatus.available)
            .toList();

    // Apply search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) {
        return p.propertyAddress.toLowerCase().contains(q) ||
            (p.ownerName?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    // Apply type filter
    if (_filterType != null) {
      list = list.where((p) => p.propertyType == _filterType).toList();
    }

    // Apply status filter
    if (_filterStatus != null) {
      list = list.where((p) => p.propertyStatus == _filterStatus).toList();
    }

    // Apply sorting
    if (_sortMode == PropertySortMode.nearest && hasUserLocation) {
      list.sort((a, b) {
        final distA = _distanceTo(a);
        final distB = _distanceTo(b);
        if (distA == null && distB == null) return 0;
        if (distA == null) return 1;
        if (distB == null) return -1;
        return distA.compareTo(distB);
      });
    } else {
      // newest first
      list.sort((a, b) {
        final dateA = a.createdAt ?? DateTime(1970);
        final dateB = b.createdAt ?? DateTime(1970);
        return dateB.compareTo(dateA);
      });
    }

    return list;
  }

  /// Paginated available properties for the UI
  List<PropertyModel> get availableProperties {
    final all = _filteredAvailableProperties;
    if (_displayCount >= all.length) return all;
    return all.sublist(0, _displayCount);
  }

  bool get hasAvailableProperties => availableProperties.isNotEmpty;

  /// Get distance from user to a property in km (null if no coords)
  double? distanceToProperty(PropertyModel property) => _distanceTo(property);

  double? _distanceTo(PropertyModel property) {
    if (_userLat == null || _userLng == null) return null;
    final lat = double.tryParse(property.latitude ?? '');
    final lng = double.tryParse(property.longitude ?? '');
    if (lat == null || lng == null) return null;
    return _haversineKm(_userLat!, _userLng!, lat, lng);
  }

  static double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _deg2rad(double deg) => deg * (pi / 180);

  // ── Actions ──

  void setSearchQuery(String query) {
    _searchQuery = query;
    _displayCount = _pageSize;
    notifyListeners();
  }

  void setFilterType(PropertyType? type) {
    _filterType = type;
    _displayCount = _pageSize;
    notifyListeners();
  }

  void setFilterStatus(PropertyStatus? status) {
    _filterStatus = status;
    _displayCount = _pageSize;
    notifyListeners();
  }

  void setSortMode(PropertySortMode mode) {
    _sortMode = mode;
    _displayCount = _pageSize;
    if (mode == PropertySortMode.nearest && !hasUserLocation) {
      fetchUserLocation();
    }
    notifyListeners();
  }

  /// Load next page of results
  void loadMore() {
    if (!hasMoreItems) return;
    _displayCount += _pageSize;
    notifyListeners();
  }

  /// Fetch user GPS location
  Future<void> fetchUserLocation() async {
    if (_locationLoading) return;
    _locationLoading = true;
    notifyListeners();

    try {
      final position = await _geocodingService.getCurrentLocation();
      if (position != null) {
        _userLat = position.latitude;
        _userLng = position.longitude;
      }
    } catch (_) {
      // Location unavailable — silent fail
    } finally {
      _locationLoading = false;
      notifyListeners();
    }
  }

  /// Get nearby properties (for dashboard) — top 5 nearest
  List<PropertyModel> get nearbyProperties {
    if (!hasUserLocation) return [];
    final available = _allProperties
        .where((p) => p.propertyStatus == PropertyStatus.available)
        .where((p) => _distanceTo(p) != null)
        .toList();
    available.sort((a, b) => _distanceTo(a)!.compareTo(_distanceTo(b)!));
    return available.take(5).toList();
  }

  /// Stats for dashboard
  int get totalPropertyCount => _allProperties.length;
  int get myPropertyCount => _myProperties.length;
  int get availablePropertyCount =>
      _allProperties.where((p) => p.propertyStatus == PropertyStatus.available).length;
  int get forRentCount =>
      _allProperties.where((p) => p.propertyType == PropertyType.rent &&
          p.propertyStatus == PropertyStatus.available).length;
  int get forSaleCount =>
      _allProperties.where((p) => p.propertyType == PropertyType.sale &&
          p.propertyStatus == PropertyStatus.available).length;

  static const String _cacheKeyMy = 'properties_my';
  static const String _cacheKeyAll = 'properties_all';

  /// Load current user's properties AND all available properties.
  /// Shows cached data immediately, then refreshes from the API.
  Future<void> loadProperties() async {
    final cache = CacheService.instance;

    // Show cached data instantly if available
    final cachedMy = cache.get<List<PropertyModel>>(_cacheKeyMy);
    final cachedAll = cache.get<List<PropertyModel>>(_cacheKeyAll);
    if (cachedMy != null && cachedAll != null) {
      _myProperties = cachedMy;
      _allProperties = cachedAll;
      _isLoading = false;
      _error = null;
      notifyListeners();
      // Refresh in background
      _fetchFreshProperties();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();
    await _fetchFreshProperties();
  }

  Future<void> _fetchFreshProperties() async {
    try {
      final results = await Future.wait([
        _propertyService.getMyProperties(),
        _propertyService.getAllProperties(),
      ]);
      _myProperties = results[0];
      _allProperties = results[1];
      _error = null;

      // Update cache
      final cache = CacheService.instance;
      cache.put<List<PropertyModel>>(_cacheKeyMy, _myProperties);
      cache.put<List<PropertyModel>>(_cacheKeyAll, _allProperties);
    } on ApiException catch (e) {
      // Only show error if we have no data at all
      if (_allProperties.isEmpty) _error = e.message;
    } catch (e) {
      if (_allProperties.isEmpty) _error = 'Failed to load properties: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
      fetchUserLocation();
    }
  }

  /// Delete a property
  Future<bool> deleteProperty(String id) async {
    try {
      await _propertyService.deleteProperty(id);
      _myProperties.removeWhere((p) => p.id == id);
      _allProperties.removeWhere((p) => p.id == id);
      _invalidateCache();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to delete property: $e';
      notifyListeners();
      return false;
    }
  }

  /// Add a property to the list (after creation)
  void addProperty(PropertyModel property) {
    _myProperties.insert(0, property);
    _allProperties.insert(0, property);
    _invalidateCache();
    notifyListeners();
  }

  /// Update a property in the list (after edit)
  void updateProperty(PropertyModel property) {
    final idx1 = _myProperties.indexWhere((p) => p.id == property.id);
    if (idx1 != -1) _myProperties[idx1] = property;
    final idx2 = _allProperties.indexWhere((p) => p.id == property.id);
    if (idx2 != -1) _allProperties[idx2] = property;
    _invalidateCache();
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Invalidate cached property data
  void _invalidateCache() {
    CacheService.instance.removeByPrefix('properties_');
  }

  /// Refresh properties (force fresh fetch)
  Future<void> refresh() async {
    _invalidateCache();
    _isLoading = true;
    _error = null;
    notifyListeners();
    await _fetchFreshProperties();
  }
}
