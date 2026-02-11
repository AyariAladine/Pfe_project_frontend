import 'package:flutter/material.dart';
import '../../models/property_model.dart';
import '../../services/property_service.dart';
import '../../services/api_service.dart';

/// ViewModel for creating/editing properties
class PropertyFormViewModel extends ChangeNotifier {
  final PropertyService _propertyService = PropertyService();

  // Form controllers
  final TextEditingController propertyAddressController = TextEditingController();
  final TextEditingController propertyImageController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // State
  PropertyType _selectedPropertyType = PropertyType.rent;
  bool _isLoading = false;
  String? _error;
  PropertyModel? _createdProperty;

  // Getters
  PropertyType get selectedPropertyType => _selectedPropertyType;
  bool get isLoading => _isLoading;
  String? get error => _error;
  PropertyModel? get createdProperty => _createdProperty;

  // Form values
  String get propertyAddress => propertyAddressController.text.trim();
  String get propertyImage => propertyImageController.text.trim();

  /// Set property type
  void setPropertyType(PropertyType type) {
    _selectedPropertyType = type;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Validate form
  bool validateForm() {
    return formKey.currentState?.validate() ?? false;
  }

  /// Create property
  Future<bool> createProperty() async {
    if (!validateForm()) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final dto = CreatePropertyDto(
        propertyAddress: propertyAddress,
        propertyType: _selectedPropertyType,
        propertyImage: propertyImage.isNotEmpty ? propertyImage : null,
      );

      _createdProperty = await _propertyService.createProperty(dto);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to create property: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear form
  void clearForm() {
    propertyAddressController.clear();
    propertyImageController.clear();
    _selectedPropertyType = PropertyType.rent;
    _error = null;
    _createdProperty = null;
    notifyListeners();
  }

  @override
  void dispose() {
    propertyAddressController.dispose();
    propertyImageController.dispose();
    super.dispose();
  }
}
