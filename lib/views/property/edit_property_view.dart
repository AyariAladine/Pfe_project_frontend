import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pfe_project/core/localization/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/property_model.dart';
import '../../services/property_service.dart';
import '../../services/api_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/network_image_with_auth.dart';

class _MapPickerSheet extends StatefulWidget {
  final _EditPropertyViewModel viewModel;
  final bool isDark;

  const _MapPickerSheet({required this.viewModel, required this.isDark});

  @override
  State<_MapPickerSheet> createState() => _MapPickerSheetState();
}

class _MapPickerSheetState extends State<_MapPickerSheet> {
  late TextEditingController _latController;
  late TextEditingController _lngController;

  @override
  void initState() {
    super.initState();
    _latController = TextEditingController(
      text: widget.viewModel.latitudeController.text.isNotEmpty
          ? widget.viewModel.latitudeController.text
          : '36.8065',
    );
    _lngController = TextEditingController(
      text: widget.viewModel.longitudeController.text.isNotEmpty
          ? widget.viewModel.longitudeController.text
          : '10.1815',
    );
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.backgroundDark : AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: widget.isDark ? AppColors.borderDark : AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Location',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? AppColors.cardBackgroundDark
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isDark
                      ? AppColors.borderDark
                      : AppColors.border,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_pin,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Map integration coming soon',
                      style: TextStyle(
                        color: widget.isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enter coordinates manually below',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latController,
                    decoration: InputDecoration(
                      labelText: 'Latitude',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _lngController,
                    decoration: InputDecoration(
                      labelText: 'Longitude',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SafeArea(
              child: CustomButton(
                text: 'Confirm Location',
                onPressed: () {
                  widget.viewModel.setLocation(
                    _latController.text,
                    _lngController.text,
                  );
                  Navigator.pop(context);
                },
              ),
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
  final TextEditingController latitudeController;
  final TextEditingController longitudeController;

  // State
  PropertyType _selectedPropertyType;
  PropertyStatus _selectedPropertyStatus;
  XFile? _newImageXFile;
  Uint8List? _newImageBytes;
  String? _imageUrl;
  XFile? _newDocumentXFile;
  Uint8List? _newDocumentBytes;
  String? _documentUrl;
  bool _imageRemoved = false;
  bool _documentRemoved = false;
  bool _isLoading = false;
  String? _error;
  PropertyModel? _updatedProperty;

  _EditPropertyViewModel(this._originalProperty)
    : propertyAddressController = TextEditingController(
        text: _originalProperty.propertyAddress,
      ),
      latitudeController = TextEditingController(
        text: _originalProperty.latitude ?? '',
      ),
      longitudeController = TextEditingController(
        text: _originalProperty.longitude ?? '',
      ),
      _selectedPropertyType = _originalProperty.propertyType,
      _selectedPropertyStatus = _originalProperty.propertyStatus,
      _imageUrl = _originalProperty.imageUrl,
      _documentUrl = _originalProperty.registrationDocument {
    // Listen for changes
    propertyAddressController.addListener(_onChanged);
    latitudeController.addListener(_onChanged);
    longitudeController.addListener(_onChanged);
  }

  // Getters
  PropertyType get selectedPropertyType => _selectedPropertyType;
  PropertyStatus get selectedPropertyStatus => _selectedPropertyStatus;
  Uint8List? get newImageBytes => _newImageBytes;
  XFile? get newImageXFile => _newImageXFile;
  String? get imageUrl => _imageRemoved ? null : _imageUrl;
  Uint8List? get newDocumentBytes => _newDocumentBytes;
  XFile? get newDocumentXFile => _newDocumentXFile;
  String? get documentUrl => _documentRemoved ? null : _documentUrl;
  bool get isLoading => _isLoading;
  String? get error => _error;
  PropertyModel? get updatedProperty => _updatedProperty;

  bool get hasChanges {
    return propertyAddressController.text != _originalProperty.propertyAddress ||
        latitudeController.text != (_originalProperty.latitude ?? '') ||
        longitudeController.text != (_originalProperty.longitude ?? '') ||
        _selectedPropertyType != _originalProperty.propertyType ||
        _selectedPropertyStatus != _originalProperty.propertyStatus ||
        _newImageXFile != null ||
        _imageRemoved ||
        _newDocumentXFile != null ||
        _documentRemoved;
  }

  void _onChanged() {
    notifyListeners();
  }

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

  Future<void> pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        _newImageXFile = image;
        _newImageBytes = await image.readAsBytes();
        _imageRemoved = false;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to pick image: $e';
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
        _newImageXFile = image;
        _newImageBytes = await image.readAsBytes();
        _imageRemoved = false;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to take photo: $e';
      notifyListeners();
    }
  }

  void removeImage() {
    _newImageXFile = null;
    _newImageBytes = null;
    _imageRemoved = true;
    notifyListeners();
  }

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
    notifyListeners();
  }

  void resetChanges() {
    propertyAddressController.text = _originalProperty.propertyAddress;
    latitudeController.text = _originalProperty.latitude ?? '';
    longitudeController.text = _originalProperty.longitude ?? '';
    _selectedPropertyType = _originalProperty.propertyType;
    _selectedPropertyStatus = _originalProperty.propertyStatus;
    _newImageXFile = null;
    _newImageBytes = null;
    _imageUrl = _originalProperty.imageUrl;
    _imageRemoved = false;
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
      // Build updates map
      final updates = <String, dynamic>{};

   
      if (propertyAddressController.text != _originalProperty.propertyAddress) {
        updates['Propertyaddresse'] = propertyAddressController.text.trim();
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

      // Handle image removal
      if (_imageRemoved) {
        updates['propertyimage'] = null;
      }

      // Handle document removal
      if (_documentRemoved) {
        updates['Registrationdocument'] = null;
      }

      // Update basic fields if there are any changes
      PropertyModel? updatedProperty;
      if (updates.isNotEmpty) {
        updatedProperty = await _propertyService.updateProperty(
          _originalProperty.id!,
          updates,
        );
      }

      // Upload new image if provided
      if (_newImageBytes != null && _newImageXFile != null) {
        updatedProperty = await _propertyService.uploadPropertyImage(
          _originalProperty.id!,
          imageBytes: _newImageBytes,
          fileName: _newImageXFile!.name,
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

      // If nothing was updated at all, return success
      if (updatedProperty == null && updates.isEmpty && _newImageXFile == null && _newDocumentXFile == null) {
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
    latitudeController.removeListener(_onChanged);
    longitudeController.removeListener(_onChanged);
    propertyAddressController.dispose();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Column(
        children: [
          // Top bar with back, title, reset
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: Text(AppLocalizations.of(context)!.back),
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
                  ),
                ),
                const Spacer(),
                Consumer<_EditPropertyViewModel>(
                  builder: (context, viewModel, _) {
                    if (viewModel.hasChanges) {
                      return TextButton(
                        onPressed: viewModel.resetChanges,
                        child: Text(
                          'Reset',
                          style: TextStyle(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),

          // Form content
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Consumer<_EditPropertyViewModel>(
                  builder: (context, viewModel, child) {
                    return Form(
                      key: viewModel.formKey,
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          _buildImageSection(context, viewModel, isDark),
                          const SizedBox(height: 24),

                          _buildSectionHeader('Basic Information', isDark),
                          const SizedBox(height: 12),

                          _buildLabel('${AppLocalizations.of(context)!.propertyAddress} *', isDark),
                          const SizedBox(height: 8),
                          CustomTextField(
                            controller: viewModel.propertyAddressController,
                            hintText: AppLocalizations.of(context)!.enterFullAddress,
                            prefixIcon: Icons.location_on_outlined,
                            maxLines: 2,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return AppLocalizations.of(context)!.propertyAddressRequired;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          _buildLabel('${AppLocalizations.of(context)!.propertyType} *', isDark),
                          const SizedBox(height: 12),
                          _buildPropertyTypeSelector(context, viewModel, isDark),
                          const SizedBox(height: 24),

                          _buildLabel(AppLocalizations.of(context)!.propertyStatus, isDark),
                          const SizedBox(height: 12),
                          _buildPropertyStatusSelector(viewModel, isDark),
                          const SizedBox(height: 24),

                          _buildSectionHeader(AppLocalizations.of(context)!.location, isDark),
                          const SizedBox(height: 12),

                          Row(children: [
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start, children: [
                                _buildLabel(AppLocalizations.of(context)!.latitude, isDark),
                                const SizedBox(height: 8),
                                CustomTextField(
                                  controller: viewModel.latitudeController,
                                  hintText: AppLocalizations.of(context)!.latitudeHint,
                                  prefixIcon: Icons.north,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                ),
                              ],
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start, children: [
                                _buildLabel(AppLocalizations.of(context)!.longitude, isDark),
                                const SizedBox(height: 8),
                                CustomTextField(
                                  controller: viewModel.longitudeController,
                                  hintText: AppLocalizations.of(context)!.longitudeHint,
                                  prefixIcon: Icons.east,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                ),
                              ],
                            )),
                          ]),
                          const SizedBox(height: 12),

                          Row(children: [
                            Expanded(child: OutlinedButton.icon(
                              onPressed: () => _showMapPicker(context, viewModel, isDark),
                              icon: const Icon(Icons.map_outlined, size: 18),
                              label: Text(AppLocalizations.of(context)!.selectOnMap),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: OutlinedButton.icon(
                              onPressed: viewModel.clearLocation,
                              icon: const Icon(Icons.clear, size: 18),
                              label: Text(AppLocalizations.of(context)!.clear),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                                side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            )),
                          ]),
                          const SizedBox(height: 24),

                          _buildSectionHeader(AppLocalizations.of(context)!.documents, isDark),
                          const SizedBox(height: 12),
                          _buildDocumentSection(context, viewModel, isDark),
                          const SizedBox(height: 24),

                          if (viewModel.error != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(children: [
                                const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                                const SizedBox(width: 8),
                                Expanded(child: Text(viewModel.error!,
                                  style: const TextStyle(color: AppColors.error, fontSize: 14))),
                                IconButton(icon: const Icon(Icons.close, size: 18),
                                  onPressed: viewModel.clearError,
                                  padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                              ]),
                            ),
                            const SizedBox(height: 16),
                          ],

                          CustomButton(
                            text: 'Save Changes',
                            isLoading: viewModel.isLoading,
                            onPressed: viewModel.hasChanges && !viewModel.isLoading
                                ? () async {
                                    final success = await viewModel.saveChanges();
                                    if (success && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text('Property updated successfully!'),
                                          backgroundColor: AppColors.success,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      );
                                      if (viewModel.updatedProperty != null) {
                                        widget.onPropertyUpdated?.call(viewModel.updatedProperty!);
                                      }
                                    }
                                  }
                                : null,
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helper builder methods ───

  Widget _buildSectionHeader(String title, bool isDark) {
    return Row(children: [
      Container(width: 4, height: 20, decoration: BoxDecoration(
        color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
    ]);
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary));
  }

  Widget _buildImageSection(BuildContext context, _EditPropertyViewModel viewModel, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: SizedBox(height: 180, width: double.infinity, child: _buildImagePreview(viewModel, isDark)),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: viewModel.pickImage,
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: const Text('Gallery'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            )),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(
              onPressed: viewModel.takePhoto,
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: const Text('Camera'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            )),
            if (viewModel.newImageBytes != null || viewModel.imageUrl != null)
              IconButton(onPressed: viewModel.removeImage,
                icon: const Icon(Icons.delete_outline, color: AppColors.error)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildImagePreview(_EditPropertyViewModel viewModel, bool isDark) {
    if (viewModel.newImageBytes != null) return Image.memory(viewModel.newImageBytes!, fit: BoxFit.cover);
    if (viewModel.imageUrl != null && viewModel.imageUrl!.isNotEmpty) {
      return NetworkImageWithAuth(imageUrl: viewModel.imageUrl!, fit: BoxFit.cover,
        errorBuilder: () => _buildImagePlaceholder(isDark));
    }
    return _buildImagePlaceholder(isDark);
  }

  Widget _buildImagePlaceholder(bool isDark) {
    return Container(
      color: isDark ? AppColors.surfaceDark : AppColors.surface,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.add_photo_alternate_outlined, size: 48,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
        const SizedBox(height: 8),
        Text('Add Property Image', style: TextStyle(fontSize: 14,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary)),
      ]),
    );
  }

  Widget _buildPropertyTypeSelector(BuildContext context, _EditPropertyViewModel viewModel, bool isDark) {
    return Row(children: [
      Expanded(child: _buildTypeCard(
        title: AppLocalizations.of(context)!.forRent, icon: Icons.vpn_key_outlined,
        isSelected: viewModel.selectedPropertyType == PropertyType.rent, isDark: isDark,
        onTap: () => viewModel.setPropertyType(PropertyType.rent))),
      const SizedBox(width: 12),
      Expanded(child: _buildTypeCard(
        title: AppLocalizations.of(context)!.forSale, icon: Icons.sell_outlined,
        isSelected: viewModel.selectedPropertyType == PropertyType.sale, isDark: isDark,
        onTap: () => viewModel.setPropertyType(PropertyType.sale))),
    ]);
  }

  Widget _buildTypeCard({required String title, required IconData icon,
    required bool isSelected, required bool isDark, required VoidCallback onTap}) {
    return GestureDetector(onTap: onTap, child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : (isDark ? AppColors.cardBackgroundDark : AppColors.surface),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.border))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 20, color: isSelected ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary)),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary))),
      ]),
    ));
  }

  Widget _buildPropertyStatusSelector(_EditPropertyViewModel viewModel, bool isDark) {
    return Wrap(spacing: 8, runSpacing: 8,
      children: PropertyStatus.values.map((status) {
        final isSelected = viewModel.selectedPropertyStatus == status;
        return GestureDetector(
          onTap: () => viewModel.setPropertyStatus(status),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? _getStatusColor(status) : (isDark ? AppColors.cardBackgroundDark : AppColors.surface),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? _getStatusColor(status) : (isDark ? AppColors.borderDark : AppColors.border))),
            child: Text(status.displayName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary))),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDocumentSection(BuildContext context, _EditPropertyViewModel viewModel, bool isDark) {
    if (viewModel.newDocumentBytes != null) return _buildDocumentPreview(viewModel, isDark, isNew: true);
    if (viewModel.documentUrl != null && viewModel.documentUrl!.isNotEmpty) {
      return _buildDocumentPreview(viewModel, isDark, isNew: false);
    }
    return _buildDocumentUploadButtons(viewModel, isDark);
  }

  Widget _buildDocumentPreview(_EditPropertyViewModel viewModel, bool isDark, {required bool isNew}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3))),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.description_outlined, color: AppColors.success)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Registration Document', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
          Text(isNew ? 'New document selected' : 'Document uploaded',
            style: const TextStyle(fontSize: 12, color: AppColors.success)),
        ])),
        Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(icon: const Icon(Icons.edit_outlined, color: AppColors.primary), onPressed: viewModel.pickDocument),
          IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.error), onPressed: viewModel.removeDocument),
        ]),
      ]),
    );
  }

  Widget _buildDocumentUploadButtons(_EditPropertyViewModel viewModel, bool isDark) {
    return Row(children: [
      Expanded(child: OutlinedButton.icon(
        onPressed: viewModel.pickDocument,
        icon: const Icon(Icons.upload_file_outlined, size: 18), label: const Text('Upload'),
        style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 14)))),
      const SizedBox(width: 12),
      Expanded(child: OutlinedButton.icon(
        onPressed: viewModel.scanDocument,
        icon: const Icon(Icons.document_scanner_outlined, size: 18), label: const Text('Scan'),
        style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 14)))),
    ]);
  }

  void _showMapPicker(BuildContext context, _EditPropertyViewModel viewModel, bool isDark) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => _MapPickerSheet(viewModel: viewModel, isDark: isDark),
    );
  }

  Color _getStatusColor(PropertyStatus status) {
    switch (status) {
      case PropertyStatus.available: return AppColors.success;
      case PropertyStatus.rented: return AppColors.info;
      case PropertyStatus.sold: return AppColors.secondary;
      case PropertyStatus.pending: return AppColors.warning;
      case PropertyStatus.unavailable: return AppColors.error;
    }
  }
}
