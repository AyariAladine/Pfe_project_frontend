import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/property_model.dart';
import '../../services/property_service.dart';
import '../../services/api_service.dart';
import '../../services/geocoding_service.dart';

/// Steps in the property creation wizard
enum PropertyWizardStep { basicInfo, photos, location, additionalInfo }

/// ViewModel for the property creation wizard
class PropertyWizardViewModel extends ChangeNotifier {
  final PropertyService _propertyService = PropertyService();
  final GeocodingService _geocodingService = GeocodingService();
  final ImagePicker _imagePicker = ImagePicker();

  // Controllers
  final TextEditingController propertyAddressController =
      TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final GlobalKey<FormState> basicInfoFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> locationFormKey = GlobalKey<FormState>();

  // Current step
  PropertyWizardStep _currentStep = PropertyWizardStep.basicInfo;
  int _currentStepIndex = 0;

  // Property data
  PropertyType _selectedPropertyType = PropertyType.rent;
  // Default to unavailable - user needs to prove legal documents before property can be available
  PropertyStatus _selectedPropertyStatus = PropertyStatus.unavailable;

  // Photos - store as bytes for web compatibility
  final List<Uint8List> _propertyImages = [];
  String? _mainImageUrl;

  // Location
  double? _latitude;
  double? _longitude;
  bool _useMapSelection = true;
  bool _isGeocodingLoading = false;

  // State
  bool _isLoading = false;
  String? _error;
  PropertyModel? _createdProperty;

  // Getters
  PropertyWizardStep get currentStep => _currentStep;
  int get currentStepIndex => _currentStepIndex;
  PropertyType get selectedPropertyType => _selectedPropertyType;
  PropertyStatus get selectedPropertyStatus => _selectedPropertyStatus;
  List<Uint8List> get propertyImages => _propertyImages;
  String? get mainImageUrl => _mainImageUrl;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  bool get useMapSelection => _useMapSelection;
  bool get isGeocodingLoading => _isGeocodingLoading;
  bool get isLoading => _isLoading;
  String? get error => _error;
  PropertyModel? get createdProperty => _createdProperty;

  // Step management
  int get totalSteps => PropertyWizardStep.values.length;

  bool get canGoBack => _currentStepIndex > 0;

  bool get canGoNext {
    switch (_currentStep) {
      case PropertyWizardStep.basicInfo:
        return propertyAddressController.text.trim().isNotEmpty;
      case PropertyWizardStep.photos:
        return true; // Photos are optional
      case PropertyWizardStep.location:
        return true; // Location is optional
      case PropertyWizardStep.additionalInfo:
        return true; // Additional info is optional
    }
  }

  bool get isLastStep => _currentStepIndex == totalSteps - 1;

  String get stepTitle {
    switch (_currentStep) {
      case PropertyWizardStep.basicInfo:
        return 'Basic Information';
      case PropertyWizardStep.photos:
        return 'Property Photos';
      case PropertyWizardStep.location:
        return 'Location';
      case PropertyWizardStep.additionalInfo:
        return 'Additional Details';
    }
  }

  String get stepSubtitle {
    switch (_currentStep) {
      case PropertyWizardStep.basicInfo:
        return 'Enter the basic details of your property';
      case PropertyWizardStep.photos:
        return 'Add photos to showcase your property';
      case PropertyWizardStep.location:
        return 'Set the exact location of your property';
      case PropertyWizardStep.additionalInfo:
        return 'Add more details about your property';
    }
  }

  /// Go to next step
  void nextStep() {
    if (_currentStepIndex < totalSteps - 1) {
      _currentStepIndex++;
      _currentStep = PropertyWizardStep.values[_currentStepIndex];
      notifyListeners();
    }
  }

  /// Go to previous step
  void previousStep() {
    if (_currentStepIndex > 0) {
      _currentStepIndex--;
      _currentStep = PropertyWizardStep.values[_currentStepIndex];
      notifyListeners();
    }
  }

  /// Go to specific step
  void goToStep(int index) {
    if (index >= 0 && index < totalSteps) {
      _currentStepIndex = index;
      _currentStep = PropertyWizardStep.values[_currentStepIndex];
      notifyListeners();
    }
  }

  /// Set property type
  void setPropertyType(PropertyType type) {
    _selectedPropertyType = type;
    notifyListeners();
  }

  /// Set property status
  void setPropertyStatus(PropertyStatus status) {
    _selectedPropertyStatus = status;
    notifyListeners();
  }

  /// Pick image from gallery
  Future<void> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        _propertyImages.add(bytes);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to pick image: $e';
      notifyListeners();
    }
  }

  /// Pick multiple images from gallery
  Future<void> pickMultipleImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 80,
      );
      for (var image in images) {
        final bytes = await image.readAsBytes();
        _propertyImages.add(bytes);
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to pick images: $e';
      notifyListeners();
    }
  }

  /// Take photo with camera
  Future<void> takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        _propertyImages.add(bytes);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to take photo: $e';
      notifyListeners();
    }
  }

  /// Remove image at index
  void removeImage(int index) {
    if (index >= 0 && index < _propertyImages.length) {
      _propertyImages.removeAt(index);
      notifyListeners();
    }
  }

  /// Set main image URL (for when uploaded to server)
  void setMainImageUrl(String url) {
    _mainImageUrl = url;
    notifyListeners();
  }

  /// Toggle map selection mode
  void toggleMapSelection(bool value) {
    _useMapSelection = value;
    notifyListeners();
  }

  /// Set location from map selection
  void setLocation(double lat, double lng) {
    _latitude = lat;
    _longitude = lng;
    latitudeController.text = lat.toStringAsFixed(6);
    longitudeController.text = lng.toStringAsFixed(6);
    notifyListeners();
  }

  /// Clear location
  void clearLocation() {
    _latitude = null;
    _longitude = null;
    latitudeController.clear();
    longitudeController.clear();
    notifyListeners();
  }

  /// Geocode address using OpenStreetMap Nominatim (Free)
  Future<void> geocodeAddress() async {
    if (propertyAddressController.text.trim().isEmpty) {
      _error = 'Please enter an address first';
      notifyListeners();
      return;
    }

    _isGeocodingLoading = true;
    _error = null;
    notifyListeners();

    try {
      final coordinates = await _geocodingService.getCoordinatesFromAddress(
        propertyAddressController.text.trim(),
      );

      if (coordinates != null) {
        _latitude = coordinates['lat'];
        _longitude = coordinates['lng'];
        latitudeController.text = _latitude!.toStringAsFixed(6);
        longitudeController.text = _longitude!.toStringAsFixed(6);
      } else {
        _error = 'Could not find location for this address';
      }

      _isGeocodingLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to geocode address: $e';
      _isGeocodingLoading = false;
      notifyListeners();
    }
  }

  /// Get current device location
  Future<void> getCurrentLocation() async {
    _isGeocodingLoading = true;
    _error = null;
    notifyListeners();

    try {
      final position = await _geocodingService.getCurrentLocation();

      if (position != null) {
        _latitude = position.latitude;
        _longitude = position.longitude;
        latitudeController.text = _latitude!.toStringAsFixed(6);
        longitudeController.text = _longitude!.toStringAsFixed(6);
        
        // Optionally update address field with reverse geocoding
        final address = await _geocodingService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (address != null && propertyAddressController.text.trim().isEmpty) {
          propertyAddressController.text = address;
        }
      } else {
        _error = 'Could not get current location. Please enable location services.';
      }

      _isGeocodingLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to get current location: $e';
      _isGeocodingLoading = false;
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Validate current step
  bool validateCurrentStep() {
    switch (_currentStep) {
      case PropertyWizardStep.basicInfo:
        return basicInfoFormKey.currentState?.validate() ?? false;
      case PropertyWizardStep.photos:
        return true;
      case PropertyWizardStep.location:
        return true;
      case PropertyWizardStep.additionalInfo:
        return true;
    }
  }

  /// Create property
  Future<bool> createProperty() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Build DTO
      final dto = CreatePropertyDto(
        propertyAddress: propertyAddressController.text.trim(),
        propertyType: _selectedPropertyType,
        propertyStatus: _selectedPropertyStatus,
        latitude: _latitude?.toString(),
        longitude: _longitude?.toString(),
      );

      // Generate timestamp-based filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Create property with optional first image in single request
      _createdProperty = await _propertyService.createProperty(
        dto,
        imageBytes: _propertyImages.isNotEmpty ? _propertyImages.first : null,
        imageFileName: _propertyImages.isNotEmpty
            ? 'property_${timestamp}_0.jpg'
            : null,
      );

      // Upload additional images if any
      if (_propertyImages.length > 1 && _createdProperty != null && _createdProperty!.id != null) {
        try {
          for (int i = 1; i < _propertyImages.length; i++) {
            await _propertyService.uploadPropertyImage(
              _createdProperty!.id!,
              imageBytes: _propertyImages[i],
              fileName: 'property_${timestamp}_$i.jpg',
            );
          }
        } catch (uploadError) {
          // Property created but additional image upload failed
          _error = 'Property created but some image uploads failed: $uploadError';
          _isLoading = false;
          notifyListeners();
          return true; // Still return true since property was created
        }
      }

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

  /// Reset the wizard
  void reset() {
    propertyAddressController.clear();
    latitudeController.clear();
    longitudeController.clear();
    descriptionController.clear();
    _currentStepIndex = 0;
    _currentStep = PropertyWizardStep.basicInfo;
    _selectedPropertyType = PropertyType.rent;
    _selectedPropertyStatus = PropertyStatus.available;
    _propertyImages.clear();
    _mainImageUrl = null;
    _latitude = null;
    _longitude = null;
    _useMapSelection = true;
    _error = null;
    _createdProperty = null;
    _currentStepIndex = 0;
    _currentStep = PropertyWizardStep.basicInfo;
    notifyListeners();
  }

  @override
  void dispose() {
    propertyAddressController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
