import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/lawyer_service.dart';
import '../../services/api_service.dart';
import '../../services/geocoding_service.dart';
import '../../services/cache_service.dart';

enum LawyerSortMode { name, nearest }

/// ViewModel for the lawyers list with dynamic search
class LawyerListViewModel extends ChangeNotifier {
  final LawyerService _lawyerService = LawyerService();
  final GeocodingService _geocodingService = GeocodingService();

  List<UserModel> _allLawyers = [];
  List<UserModel> _filteredLawyers = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  // Sort & location state
  LawyerSortMode _sortMode = LawyerSortMode.name;
  double? _userLat;
  double? _userLng;
  bool _locationLoading = false;

  // Selected lawyer for detail view
  UserModel? _selectedLawyer;
  bool _isLoadingDetail = false;
  String? _detailError;

  // Pagination
  static const int _pageSize = 10;
  int _displayCount = 10;

  List<UserModel> get lawyers {
    if (_displayCount >= _filteredLawyers.length) return _filteredLawyers;
    return _filteredLawyers.sublist(0, _displayCount);
  }
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  // Pagination getters
  int get totalFilteredCount => _filteredLawyers.length;
  bool get hasMoreItems => _displayCount < _filteredLawyers.length;

  LawyerSortMode get sortMode => _sortMode;
  double? get userLat => _userLat;
  double? get userLng => _userLng;
  bool get locationLoading => _locationLoading;
  bool get hasUserLocation => _userLat != null && _userLng != null;

  UserModel? get selectedLawyer => _selectedLawyer;
  bool get isLoadingDetail => _isLoadingDetail;
  String? get detailError => _detailError;

  static const String _cacheKey = 'lawyers_all';

  /// Load all lawyers from the API.
  /// Shows cached data immediately, then refreshes from the API.
  Future<void> loadLawyers() async {
    final cache = CacheService.instance;

    // Show cached data instantly if available
    final cached = cache.get<List<UserModel>>(_cacheKey);
    if (cached != null) {
      _allLawyers = cached;
      _applySearchAndSort();
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      // Refresh in background
      _fetchFreshLawyers();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    await _fetchFreshLawyers();
  }

  Future<void> _fetchFreshLawyers() async {
    try {
      _allLawyers = (await _lawyerService.getAllLawyers())
          .where((l) => l.isVerified == true)
          .toList();
      _applySearchAndSort();

      CacheService.instance.put<List<UserModel>>(_cacheKey, _allLawyers);
    } on ApiException catch (e) {
      if (_allLawyers.isEmpty) _errorMessage = e.message;
    } catch (e) {
      if (_allLawyers.isEmpty) _errorMessage = 'UNEXPECTED_ERROR';
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    // Silently fetch location in background
    fetchUserLocation();
  }

  /// Update the search query and filter the list
  void search(String query) {
    _searchQuery = query;
    _displayCount = _pageSize;
    _applySearchAndSort();
    notifyListeners();
  }

  /// Clear search
  void clearSearch() {
    _searchQuery = '';
    _displayCount = _pageSize;
    _applySearchAndSort();
    notifyListeners();
  }

  /// Set sort mode
  void setSortMode(LawyerSortMode mode) {
    _sortMode = mode;
    _displayCount = _pageSize;
    if (mode == LawyerSortMode.nearest && !hasUserLocation) {
      fetchUserLocation();
    }
    _applySearchAndSort();
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
        _applySearchAndSort();
      }
    } catch (_) {
      // Location unavailable — silent fail
    } finally {
      _locationLoading = false;
      notifyListeners();
    }
  }

  /// Get distance from user to a lawyer in km
  double? distanceToLawyer(UserModel lawyer) {
    if (_userLat == null || _userLng == null) return null;
    if (lawyer.latitude == null || lawyer.longitude == null) return null;
    return _haversineKm(_userLat!, _userLng!, lawyer.latitude!, lawyer.longitude!);
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

  /// Apply search filter + sorting on the local list
  void _applySearchAndSort() {
    List<UserModel> result;

    if (_searchQuery.isEmpty) {
      result = List.from(_allLawyers);
    } else {
      final q = _searchQuery.toLowerCase().trim();
      final searchExtended = q.length >= 3;
      result = _allLawyers.where((lawyer) {
        final nameMatch = lawyer.name.toLowerCase().contains(q) ||
            lawyer.lastName.toLowerCase().contains(q) ||
            lawyer.fullName.toLowerCase().contains(q);
        if (nameMatch) return true;

        if (searchExtended) {
          return lawyer.email.toLowerCase().contains(q) ||
              lawyer.phoneNumber.toLowerCase().contains(q);
        }

        return false;
      }).toList();
    }

    // Apply sort
    if (_sortMode == LawyerSortMode.nearest && hasUserLocation) {
      result.sort((a, b) {
        final distA = distanceToLawyer(a);
        final distB = distanceToLawyer(b);
        if (distA == null && distB == null) return 0;
        if (distA == null) return 1;
        if (distB == null) return -1;
        return distA.compareTo(distB);
      });
    } else {
      // Sort by name alphabetically
      result.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
    }

    _filteredLawyers = result;
  }

  /// Load a single lawyer's details by ID
  Future<void> loadLawyerDetail(String id) async {
    _isLoadingDetail = true;
    _detailError = null;
    notifyListeners();

    try {
      _selectedLawyer = await _lawyerService.getLawyerById(id);
    } on ApiException catch (e) {
      _detailError = e.message;
    } catch (e) {
      _detailError = 'UNEXPECTED_ERROR';
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  /// Clear selected lawyer
  void clearSelection() {
    _selectedLawyer = null;
    _detailError = null;
    notifyListeners();
  }
}
