import 'package:flutter/material.dart';
import '../../models/property_model.dart';
import '../../services/property_service.dart';
import '../../services/api_service.dart';

/// ViewModel for listing properties
class PropertyListViewModel extends ChangeNotifier {
  final PropertyService _propertyService = PropertyService();

  // State
  List<PropertyModel> _properties = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<PropertyModel> get properties => _properties;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasProperties => _properties.isNotEmpty;

  /// Load current user's properties
  Future<void> loadProperties() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _properties = await _propertyService.getMyProperties();
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load properties: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete a property
  Future<bool> deleteProperty(String id) async {
    try {
      await _propertyService.deleteProperty(id);
      _properties.removeWhere((p) => p.id == id);
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
    _properties.insert(0, property);
    notifyListeners();
  }

  /// Update a property in the list (after edit)
  void updateProperty(PropertyModel property) {
    final index = _properties.indexWhere((p) => p.id == property.id);
    if (index != -1) {
      _properties[index] = property;
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh properties
  Future<void> refresh() async {
    await loadProperties();
  }
}
