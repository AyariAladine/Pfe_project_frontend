import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:pfe_project/core/localization/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/property_model.dart';
import '../../services/property_service.dart';
import '../../services/api_service.dart';
import '../widgets/network_image_with_auth.dart';

class _PropertyMapPickerSheet extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final void Function(double lat, double lng) onLocationSelected;

  const _PropertyMapPickerSheet({
    this.initialLat,
    this.initialLng,
    required this.onLocationSelected,
  });

  @override
  State<_PropertyMapPickerSheet> createState() =>
      _PropertyMapPickerSheetState();
}

class _PropertyMapPickerSheetState extends State<_PropertyMapPickerSheet> {
  late MapController _mapController;
  late LatLng _selectedLocation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    final lat = widget.initialLat ?? 36.8065;
    final lng = widget.initialLng ?? 10.1815;
    _selectedLocation = LatLng(lat, lng);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.selectPropertyLocation,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.tapOnMapOrDragPin,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Map
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _selectedLocation,
                      initialZoom: 13.0,
                      onTap: (tapPosition, point) {
                        setState(() {
                          _selectedLocation = point;
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.aqari.pfe_project',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLocation,
                            width: 50,
                            height: 50,
                            child: const Icon(
                              Icons.location_pin,
                              size: 50,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Zoom controls
                  Positioned(
                    right: 10,
                    bottom: 80,
                    child: Column(
                      children: [
                        FloatingActionButton.small(
                          heroTag: 'prop_zoom_in',
                          backgroundColor: Colors.white,
                          onPressed: () {
                            _mapController.move(
                              _mapController.camera.center,
                              _mapController.camera.zoom + 1,
                            );
                          },
                          child: const Icon(Icons.add,
                              color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'prop_zoom_out',
                          backgroundColor: Colors.white,
                          onPressed: () {
                            _mapController.move(
                              _mapController.camera.center,
                              _mapController.camera.zoom - 1,
                            );
                          },
                          child: const Icon(Icons.remove,
                              color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Coordinates + Confirm
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedLocation.latitude.toStringAsFixed(5)}, ${_selectedLocation.longitude.toStringAsFixed(5)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      widget.onLocationSelected(
                        _selectedLocation.latitude,
                        _selectedLocation.longitude,
                      );
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: Text(l10n.confirmLocation),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ViewModel for editing a property
class _EditPropertyViewModel extends ChangeNotifier {
  final PropertyService _propertyService = PropertyService();
  final ImagePicker _imagePicker = ImagePicker();
  final PropertyModel _originalProperty;

  // Form
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController propertyAddressController;
  final TextEditingController descriptionController;
  final TextEditingController latitudeController;
  final TextEditingController longitudeController;

  // State
  PropertyType _selectedPropertyType;
  PropertyStatus _selectedPropertyStatus;

  // ── Multi-image state ──
  /// URLs of existing server images still kept
  List<String> _existingImageUrls = [];
  /// Newly-picked images (bytes + file ref for upload)
  final List<Uint8List> _newImageBytesList = [];
  final List<XFile> _newImageXFiles = [];
  /// Indexes of original images that were removed
  final Set<int> _removedOriginalIndexes = {};

  XFile? _newDocumentXFile;
  Uint8List? _newDocumentBytes;
  String? _documentUrl;
  bool _documentRemoved = false;
  bool _isLoading = false;
  String? _error;
  PropertyModel? _updatedProperty;

  _EditPropertyViewModel(this._originalProperty)
    : propertyAddressController = TextEditingController(
        text: _originalProperty.propertyAddress,
      ),
      descriptionController = TextEditingController(
        text: _originalProperty.description ?? '',
      ),
      latitudeController = TextEditingController(
        text: _originalProperty.latitude ?? '',
      ),
      longitudeController = TextEditingController(
        text: _originalProperty.longitude ?? '',
      ),
      _selectedPropertyType = _originalProperty.propertyType,
      _selectedPropertyStatus = _originalProperty.propertyStatus,
      _existingImageUrls = List<String>.from(_originalProperty.imageUrls),
      _documentUrl = _originalProperty.registrationDocument {
    propertyAddressController.addListener(_onChanged);
    descriptionController.addListener(_onChanged);
    latitudeController.addListener(_onChanged);
    longitudeController.addListener(_onChanged);
  }

  // ── Getters ──
  PropertyType get selectedPropertyType => _selectedPropertyType;
  PropertyStatus get selectedPropertyStatus => _selectedPropertyStatus;

  /// All displayable images: existing URLs (minus removed) + new bytes
  List<String> get existingImageUrls {
    return _existingImageUrls
        .asMap()
        .entries
        .where((e) => !_removedOriginalIndexes.contains(e.key))
        .map((e) => e.value)
        .toList();
  }

  List<Uint8List> get newImageBytesList => _newImageBytesList;
  int get totalImageCount =>
      existingImageUrls.length + _newImageBytesList.length;

  Uint8List? get newDocumentBytes => _newDocumentBytes;
  XFile? get newDocumentXFile => _newDocumentXFile;
  String? get documentUrl => _documentRemoved ? null : _documentUrl;
  bool get isLoading => _isLoading;
  String? get error => _error;
  PropertyModel? get updatedProperty => _updatedProperty;

  bool get hasChanges {
    return propertyAddressController.text != _originalProperty.propertyAddress ||
        descriptionController.text != (_originalProperty.description ?? '') ||
        latitudeController.text != (_originalProperty.latitude ?? '') ||
        longitudeController.text != (_originalProperty.longitude ?? '') ||
        _selectedPropertyType != _originalProperty.propertyType ||
        _selectedPropertyStatus != _originalProperty.propertyStatus ||
        _newImageBytesList.isNotEmpty ||
        _removedOriginalIndexes.isNotEmpty ||
        _newDocumentXFile != null ||
        _documentRemoved;
  }

  void _onChanged() => notifyListeners();

  void setPropertyType(PropertyType type) {
    _selectedPropertyType = type;
    notifyListeners();
  }

  void setPropertyStatus(PropertyStatus status) {
    _selectedPropertyStatus = status;
    notifyListeners();
  }

  void setLocation(String lat, String lng) {
    latitudeController.text = lat;
    longitudeController.text = lng;
    notifyListeners();
  }

  void clearLocation() {
    latitudeController.clear();
    longitudeController.clear();
    notifyListeners();
  }

  // ── Image picking (adds to list) ──

  Future<void> pickImage() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 80,
      );
      for (final image in images) {
        _newImageXFiles.add(image);
        _newImageBytesList.add(await image.readAsBytes());
      }
      if (images.isNotEmpty) notifyListeners();
    } catch (e) {
      _error = 'Failed to pick images: $e';
      notifyListeners();
    }
  }

  Future<void> takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image != null) {
        _newImageXFiles.add(image);
        _newImageBytesList.add(await image.readAsBytes());
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to take photo: $e';
      notifyListeners();
    }
  }

  /// Remove an existing (server) image by its display index
  void removeExistingImage(int displayIndex) {
    // Map display index back to original index
    int count = -1;
    for (int i = 0; i < _existingImageUrls.length; i++) {
      if (!_removedOriginalIndexes.contains(i)) count++;
      if (count == displayIndex) {
        _removedOriginalIndexes.add(i);
        break;
      }
    }
    notifyListeners();
  }

  /// Remove a newly-picked image by its index in newImageBytesList
  void removeNewImage(int index) {
    if (index >= 0 && index < _newImageBytesList.length) {
      _newImageBytesList.removeAt(index);
      _newImageXFiles.removeAt(index);
      notifyListeners();
    }
  }

  // ── Document ──

  Future<void> pickDocument() async {
    try {
      final XFile? doc = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (doc != null) {
        _newDocumentXFile = doc;
        _newDocumentBytes = await doc.readAsBytes();
        _documentRemoved = false;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to pick document: $e';
      notifyListeners();
    }
  }

  Future<void> scanDocument() async {
    try {
      final XFile? doc = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      if (doc != null) {
        _newDocumentXFile = doc;
        _newDocumentBytes = await doc.readAsBytes();
        _documentRemoved = false;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to scan document: $e';
      notifyListeners();
    }
  }

  void removeDocument() {
    _newDocumentXFile = null;
    _newDocumentBytes = null;
    _documentRemoved = true;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    _updatedProperty = null;
    notifyListeners();
  }

  void resetChanges() {
    propertyAddressController.text = _originalProperty.propertyAddress;
    descriptionController.text = _originalProperty.description ?? '';
    latitudeController.text = _originalProperty.latitude ?? '';
    longitudeController.text = _originalProperty.longitude ?? '';
    _selectedPropertyType = _originalProperty.propertyType;
    _selectedPropertyStatus = _originalProperty.propertyStatus;
    _existingImageUrls = List<String>.from(_originalProperty.imageUrls);
    _newImageBytesList.clear();
    _newImageXFiles.clear();
    _removedOriginalIndexes.clear();
    _newDocumentXFile = null;
    _newDocumentBytes = null;
    _documentUrl = _originalProperty.registrationDocument;
    _documentRemoved = false;
    _error = null;
    notifyListeners();
  }

  Future<bool> saveChanges() async {
    if (!formKey.currentState!.validate()) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updates = <String, dynamic>{};

      if (propertyAddressController.text != _originalProperty.propertyAddress) {
        updates['Propertyaddresse'] = propertyAddressController.text.trim();
      }
      if (descriptionController.text != (_originalProperty.description ?? '')) {
        updates['description'] = descriptionController.text.trim().isNotEmpty
            ? descriptionController.text.trim()
            : null;
      }
      if (_selectedPropertyType != _originalProperty.propertyType) {
        updates['PropertyType'] = _selectedPropertyType.toJson();
      }
      if (_selectedPropertyStatus != _originalProperty.propertyStatus) {
        updates['propertyStatus'] = _selectedPropertyStatus.toJson();
      }
      if (latitudeController.text != (_originalProperty.latitude ?? '')) {
        updates['latitude'] = latitudeController.text.isNotEmpty
            ? latitudeController.text
            : null;
      }
      if (longitudeController.text != (_originalProperty.longitude ?? '')) {
        updates['longitude'] = longitudeController.text.isNotEmpty
            ? longitudeController.text
            : null;
      }

      // Handle removed images — send remaining original paths
      if (_removedOriginalIndexes.isNotEmpty) {
        final remaining = <String>[];
        for (int i = 0; i < _originalProperty.propertyImages.length; i++) {
          if (!_removedOriginalIndexes.contains(i)) {
            remaining.add(_originalProperty.propertyImages[i]);
          }
        }
        updates['propertyimages'] = remaining;
      }

      if (_documentRemoved) {
        updates['Registrationdocument'] = null;
      }

      PropertyModel? updatedProperty;
      if (updates.isNotEmpty) {
        updatedProperty = await _propertyService.updateProperty(
          _originalProperty.id!,
          updates,
        );
      }

      // Upload new images if any
      if (_newImageBytesList.isNotEmpty) {
        final allBytes = _newImageBytesList;
        final allNames = _newImageXFiles.map((f) => f.name).toList();
        updatedProperty = await _propertyService.uploadPropertyImages(
          _originalProperty.id!,
          allImageBytes: allBytes,
          allFileNames: allNames,
        );
      }

      // Upload new document if provided
      if (_newDocumentBytes != null && _newDocumentXFile != null) {
        updatedProperty = await _propertyService.uploadDocument(
          _originalProperty.id!,
          documentBytes: _newDocumentBytes,
          fileName: _newDocumentXFile!.name,
        );
      }

      if (updatedProperty == null &&
          updates.isEmpty &&
          _newImageBytesList.isEmpty &&
          _newDocumentXFile == null) {
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _updatedProperty = updatedProperty ?? _originalProperty;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to update property: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    propertyAddressController.removeListener(_onChanged);
    descriptionController.removeListener(_onChanged);
    latitudeController.removeListener(_onChanged);
    longitudeController.removeListener(_onChanged);
    propertyAddressController.dispose();
    descriptionController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    super.dispose();
  }
}

/// Embeddable edit property content (no Scaffold) for use inside MainShell
class EditPropertyContent extends StatefulWidget {
  final PropertyModel property;
  final VoidCallback onBack;
  final void Function(PropertyModel updatedProperty)? onPropertyUpdated;

  const EditPropertyContent({
    super.key,
    required this.property,
    required this.onBack,
    this.onPropertyUpdated,
  });

  @override
  State<EditPropertyContent> createState() => _EditPropertyContentState();
}

class _EditPropertyContentState extends State<EditPropertyContent> {
  late _EditPropertyViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = _EditPropertyViewModel(widget.property);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<_EditPropertyViewModel>(
        builder: (context, vm, _) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Form(
                      key: vm.formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Back button row
                          Row(
                            children: [
                              TextButton.icon(
                                onPressed: widget.onBack,
                                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                                label: Text(l10n.back),
                              ),
                              const Spacer(),
                              if (vm.hasChanges)
                                TextButton.icon(
                                  onPressed: vm.resetChanges,
                                  icon: const Icon(Icons.refresh_rounded, size: 18),
                                  label: Text(l10n.resetChanges),
                                  style: TextButton.styleFrom(
                                    foregroundColor: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // ── Property Photos Section ──
                          _buildSectionCard(
                            context: context,
                            isDark: isDark,
                            icon: Icons.photo_library_rounded,
                            title: l10n.propertyPhotos,
                            child: _buildPhotoSection(context, vm, l10n, isDark),
                          ),
                          const SizedBox(height: 20),

                          // ── Basic Information Section ──
                          _buildSectionCard(
                            context: context,
                            isDark: isDark,
                            icon: Icons.edit_note_rounded,
                            title: l10n.basicInformation,
                            child: _buildBasicInfoSection(context, vm, l10n, isDark),
                          ),
                          const SizedBox(height: 20),

                          // ── Location Section ──
                          _buildSectionCard(
                            context: context,
                            isDark: isDark,
                            icon: Icons.location_on_rounded,
                            title: l10n.propertyLocation,
                            child: _buildLocationSection(context, vm, l10n, isDark),
                          ),
                          const SizedBox(height: 20),

                          // ── Documents Section ──
                          _buildSectionCard(
                            context: context,
                            isDark: isDark,
                            icon: Icons.folder_rounded,
                            title: l10n.documents,
                            child: _buildDocumentSection(context, vm, l10n, isDark),
                          ),
                          const SizedBox(height: 24),

                          // ── Save Button ──
                          SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: vm.hasChanges && !vm.isLoading
                                  ? () => _saveChanges(context, vm, l10n)
                                  : null,
                              icon: vm.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save_rounded),
                              label: Text(
                                vm.isLoading ? l10n.saving : l10n.saveChanges,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                disabledBackgroundColor: AppColors.border,
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Success / Error snack overlay
              if (vm.error != null || vm.updatedProperty != null)
                _buildSnackOverlay(context, vm, l10n),
            ],
          );
        },
      ),
    );
  }

  // ─── Section Card Wrapper (matches lawyer_profile_view) ────────────

  Widget _buildSectionCard({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  // ─── Property Photos Section (multi-image grid) ─────────────────────

  Widget _buildPhotoSection(
    BuildContext context,
    _EditPropertyViewModel vm,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final existingUrls = vm.existingImageUrls;
    final newBytes = vm.newImageBytesList;
    final isEmpty = existingUrls.isEmpty && newBytes.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Image grid
        if (!isEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 10.0;
              final crossAxisCount = constraints.maxWidth > 500 ? 3 : 2;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  // Existing server images
                  ...existingUrls.asMap().entries.map((entry) {
                    return _buildImageTile(
                      constraints.maxWidth,
                      crossAxisCount,
                      spacing,
                      isDark,
                      onRemove: () => vm.removeExistingImage(entry.key),
                      child: NetworkImageWithAuth(
                        imageUrl: entry.value,
                        fit: BoxFit.cover,
                        errorBuilder: () => const Center(
                          child: Icon(Icons.broken_image_outlined,
                              color: Colors.white54, size: 32),
                        ),
                      ),
                    );
                  }),
                  // Newly picked images
                  ...newBytes.asMap().entries.map((entry) {
                    return _buildImageTile(
                      constraints.maxWidth,
                      crossAxisCount,
                      spacing,
                      isDark,
                      isNew: true,
                      onRemove: () => vm.removeNewImage(entry.key),
                      child: Image.memory(entry.value, fit: BoxFit.cover),
                    );
                  }),
                ],
              );
            },
          ),

        if (isEmpty)
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined,
                    size: 48,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary),
                const SizedBox(height: 8),
                Text(
                  l10n.addPropertyImage,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // Upload buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: vm.pickImage,
                icon: const Icon(Icons.photo_library_rounded, size: 18),
                label: Text(l10n.gallery),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: vm.takePhoto,
                icon: const Icon(Icons.camera_alt_rounded, size: 18),
                label: Text(l10n.camera),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  side: const BorderSide(color: AppColors.secondary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),

        if (!isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${vm.totalImageCount} ${vm.totalImageCount == 1 ? 'image' : 'images'}',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  /// A single image tile with a remove button overlay
  Widget _buildImageTile(
    double totalWidth,
    int crossAxisCount,
    double spacing,
    bool isDark, {
    required Widget child,
    required VoidCallback onRemove,
    bool isNew = false,
  }) {
    final tileSize =
        (totalWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;
    return SizedBox(
      width: tileSize,
      height: tileSize,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            // Dark gradient overlay at top for remove button
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 40,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // "NEW" badge
            if (isNew)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.info,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('NEW',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            // Remove button
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Basic Information Section ─────────────────────────────────────

  Widget _buildBasicInfoSection(
    BuildContext context,
    _EditPropertyViewModel vm,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Address
        _buildStyledTextField(
          controller: vm.propertyAddressController,
          label: '${l10n.propertyAddress} *',
          icon: Icons.location_on_outlined,
          isDark: isDark,
          maxLines: 2,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return l10n.propertyAddressRequired;
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        // Description
        _buildStyledTextField(
          controller: vm.descriptionController,
          label: l10n.descriptionOptional,
          icon: Icons.description_outlined,
          isDark: isDark,
          maxLines: 4,
        ),
        const SizedBox(height: 20),

        // Property Type
        Text(
          '${l10n.propertyType} *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        _buildPropertyTypeSelector(context, vm, l10n, isDark),
        const SizedBox(height: 20),

        // Property Status
        Text(
          l10n.propertyStatus,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        _buildPropertyStatusSelector(vm, l10n, isDark),
      ],
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildPropertyTypeSelector(
    BuildContext context,
    _EditPropertyViewModel vm,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildTypeCard(
            title: l10n.forRent,
            icon: Icons.vpn_key_outlined,
            isSelected: vm.selectedPropertyType == PropertyType.rent,
            isDark: isDark,
            onTap: () => vm.setPropertyType(PropertyType.rent),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTypeCard(
            title: l10n.forSale,
            icon: Icons.sell_outlined,
            isSelected: vm.selectedPropertyType == PropertyType.sale,
            isDark: isDark,
            onTap: () => vm.setPropertyType(PropertyType.sale),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeCard({
    required String title,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.cardBackgroundDark : AppColors.surface),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.border),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 20,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary)),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyStatusSelector(
    _EditPropertyViewModel vm,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PropertyStatus.values.map((status) {
        final isSelected = vm.selectedPropertyStatus == status;
        return GestureDetector(
          onTap: () => vm.setPropertyStatus(status),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? _getStatusColor(status)
                  : (isDark
                      ? AppColors.cardBackgroundDark
                      : AppColors.surface),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? _getStatusColor(status)
                    : (isDark ? AppColors.borderDark : AppColors.border),
              ),
            ),
            child: Text(
              status.displayName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Location Section (matches lawyer_profile_view) ───────────────

  Widget _buildLocationSection(
    BuildContext context,
    _EditPropertyViewModel vm,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final hasLocation =
        vm.latitudeController.text.isNotEmpty && vm.longitudeController.text.isNotEmpty;
    final lat = double.tryParse(vm.latitudeController.text);
    final lng = double.tryParse(vm.longitudeController.text);
    final hasValidCoords = lat != null && lng != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Current location display
        if (hasLocation && hasValidCoords) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${l10n.locationSet}: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      color: AppColors.textSecondary, size: 20),
                  onPressed: vm.clearLocation,
                  tooltip: l10n.clear,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Mini map preview
          Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: IgnorePointer(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(lat, lng),
                  initialZoom: 14.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.aqari.pfe_project',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(lat, lng),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_pin,
                          size: 40,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Map picker button
        OutlinedButton.icon(
          onPressed: () => _openMapPicker(context, vm, l10n),
          icon: const Icon(Icons.map_rounded, size: 20),
          label: Text(
            hasLocation ? l10n.changeLocation : l10n.selectPropertyLocation,
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Documents Section ─────────────────────────────────────────────

  Widget _buildDocumentSection(
    BuildContext context,
    _EditPropertyViewModel vm,
    AppLocalizations l10n,
    bool isDark,
  ) {
    if (vm.newDocumentBytes != null) {
      return _buildDocumentPreview(vm, l10n, isDark, isNew: true);
    }
    if (vm.documentUrl != null && vm.documentUrl!.isNotEmpty) {
      return _buildDocumentPreview(vm, l10n, isDark, isNew: false);
    }
    return _buildDocumentUploadButtons(vm, l10n, isDark);
  }

  Widget _buildDocumentPreview(
    _EditPropertyViewModel vm,
    AppLocalizations l10n,
    bool isDark, {
    required bool isNew,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.description_outlined,
                color: AppColors.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.registrationDocument,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
                Text(
                  isNew ? l10n.newDocumentSelected : l10n.documentUploaded,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.success),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                onPressed: vm.pickDocument,
              ),
              IconButton(
                icon:
                    const Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: vm.removeDocument,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentUploadButtons(
    _EditPropertyViewModel vm,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: vm.pickDocument,
            icon: const Icon(Icons.upload_file_outlined, size: 18),
            label: Text(l10n.upload),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: vm.scanDocument,
            icon: const Icon(Icons.document_scanner_outlined, size: 18),
            label: Text(l10n.scan),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Map Picker ────────────────────────────────────────────────────

  void _openMapPicker(
    BuildContext context,
    _EditPropertyViewModel vm,
    AppLocalizations l10n,
  ) {
    final lat = double.tryParse(vm.latitudeController.text);
    final lng = double.tryParse(vm.longitudeController.text);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PropertyMapPickerSheet(
        initialLat: lat,
        initialLng: lng,
        onLocationSelected: (newLat, newLng) {
          vm.setLocation(newLat.toString(), newLng.toString());
        },
      ),
    );
  }

  // ─── Save ──────────────────────────────────────────────────────────

  Future<void> _saveChanges(
    BuildContext context,
    _EditPropertyViewModel vm,
    AppLocalizations l10n,
  ) async {
    final success = await vm.saveChanges();
    if (success && context.mounted && vm.updatedProperty != null) {
      widget.onPropertyUpdated?.call(vm.updatedProperty!);
    }
  }

  // ─── Success / Error overlay ───────────────────────────────────────

  Widget _buildSnackOverlay(
    BuildContext context,
    _EditPropertyViewModel vm,
    AppLocalizations l10n,
  ) {
    final isSuccess = vm.error == null && vm.updatedProperty != null;
    final isError = vm.error != null;

    if (!isSuccess && !isError) return const SizedBox.shrink();

    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSuccess
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSuccess
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.error.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSuccess
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                color: isSuccess ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isSuccess
                      ? l10n.propertyUpdatedSuccess
                      : l10n.propertyUpdateFailed,
                  style: TextStyle(
                    color: isSuccess ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => vm.clearError(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helper ────────────────────────────────────────────────────────

  Color _getStatusColor(PropertyStatus status) {
    switch (status) {
      case PropertyStatus.available:
        return AppColors.success;
      case PropertyStatus.rented:
        return AppColors.info;
      case PropertyStatus.sold:
        return AppColors.secondary;
      case PropertyStatus.pending:
        return AppColors.warning;
      case PropertyStatus.unavailable:
        return AppColors.error;
    }
  }
}
