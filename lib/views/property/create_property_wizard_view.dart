import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../models/property_model.dart';
import '../../viewmodels/property/property_wizard_viewmodel.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

/// Standalone wizard view (with Scaffold) - for modal navigation
class CreatePropertyWizardView extends StatefulWidget {
  const CreatePropertyWizardView({super.key});

  @override
  State<CreatePropertyWizardView> createState() =>
      _CreatePropertyWizardViewState();
}

class _CreatePropertyWizardViewState extends State<CreatePropertyWizardView> {
  late PropertyWizardViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PropertyWizardViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: const _CreatePropertyWizardScaffold(),
    );
  }
}

class CreatePropertyWizardContent extends StatefulWidget {
  final Function(PropertyModel)? onPropertyCreated;

  const CreatePropertyWizardContent({super.key, this.onPropertyCreated});

  @override
  State<CreatePropertyWizardContent> createState() =>
      _CreatePropertyWizardContentState();
}

class _CreatePropertyWizardContentState
    extends State<CreatePropertyWizardContent> {
  late PropertyWizardViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PropertyWizardViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: _CreatePropertyWizardBody(
        onPropertyCreated: widget.onPropertyCreated,
      ),
    );
  }
}

/// Scaffold wrapper for standalone navigation
class _CreatePropertyWizardScaffold extends StatelessWidget {
  const _CreatePropertyWizardScaffold();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Consumer<PropertyWizardViewModel>(
          builder: (context, viewModel, _) => Text(
            AppLocalizations.of(context)!.addProperty,
            style: TextStyle(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
          onPressed: () => _showExitConfirmation(context),
        ),
      ),
      body: _CreatePropertyWizardBody(
        onPropertyCreated: (property) {
          Navigator.pop(context, property);
        },
      ),
    );
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.discardChanges),
        content: Text(
          AppLocalizations.of(context)!.deletePropertyConfirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppLocalizations.of(context)!.discard),
          ),
        ],
      ),
    );
  }
}

/// Main body of the wizard (shared between Scaffold and Content versions)
class _CreatePropertyWizardBody extends StatelessWidget {
  final Function(PropertyModel)? onPropertyCreated;

  const _CreatePropertyWizardBody({this.onPropertyCreated});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Consumer<PropertyWizardViewModel>(
            builder: (context, viewModel, child) {
              return Column(
                children: [
                  // Progress indicator (like onboarding)
                  _buildProgressIndicator(viewModel),

                  // Content with AnimatedSwitcher
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildStepContent(
                        context,
                        viewModel,
                        onPropertyCreated,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(PropertyWizardViewModel viewModel) {
    final steps = PropertyWizardStep.values;
    final currentIndex = viewModel.currentStepIndex;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isCompleted = index < currentIndex;
          final isCurrent = index == currentIndex;

          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < steps.length - 1 ? 8 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: isCompleted || isCurrent
                    ? AppColors.primary
                    : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(
    BuildContext context,
    PropertyWizardViewModel viewModel,
    Function(PropertyModel)? onPropertyCreated,
  ) {
    switch (viewModel.currentStep) {
      case PropertyWizardStep.basicInfo:
        return _BasicInfoStep(key: ValueKey(AppLocalizations.of(context)!.basicInformation));
      case PropertyWizardStep.photos:
        return _PhotosStep(key: ValueKey(AppLocalizations.of(context)!.photos));
      case PropertyWizardStep.location:
        return _LocationStep(key: ValueKey(AppLocalizations.of(context)!.location));
      case PropertyWizardStep.additionalInfo:
        return _AdditionalInfoStep(
          key: const ValueKey('additionalInfo'),
          onPropertyCreated: onPropertyCreated,
        );
    }
  }
}

/// Step 1: Basic Information
class _BasicInfoStep extends StatelessWidget {
  const _BasicInfoStep({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PropertyWizardViewModel>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Form(
        key: viewModel.basicInfoFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.home_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              AppLocalizations.of(context)!.basicInformation,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              AppLocalizations.of(context)!.enterBasicDetails,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Error message
            if (viewModel.error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        viewModel.error!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            _InputCard(
              icon: Icons.location_on_outlined,
              title: AppLocalizations.of(context)!.propertyAddress,
              child: CustomTextField(
                controller: viewModel.propertyAddressController,
                hintText: AppLocalizations.of(context)!.enterFullAddress,
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context)!.propertyAddressRequired;
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 12),

            // Property Type Card
            _InputCard(
              icon: Icons.category_outlined,
              title: AppLocalizations.of(context)!.type,
              child: Row(
                children: [
                  Expanded(
                    child: _SelectableChip(
                      label: AppLocalizations.of(context)!.forRent,
                      icon: Icons.vpn_key_outlined,
                      isSelected:
                          viewModel.selectedPropertyType == PropertyType.rent,
                      onTap: () => viewModel.setPropertyType(PropertyType.rent),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SelectableChip(
                      label: AppLocalizations.of(context)!.forSale,
                      icon: Icons.sell_outlined,
                      isSelected:
                          viewModel.selectedPropertyType == PropertyType.sale,
                      onTap: () => viewModel.setPropertyType(PropertyType.sale),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Continue button
            CustomButton(
              text: AppLocalizations.of(context)!.continueText,
              onPressed: () {
                if (viewModel.validateCurrentStep()) {
                  viewModel.nextStep();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable Input Card (like onboarding _ScanOptionCard)
class _InputCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _InputCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// Selectable chip for property type
class _SelectableChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectableChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Option card like onboarding (for gallery/camera buttons)
class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isLoading;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

/// Step 2: Photos
class _PhotosStep extends StatelessWidget {
  const _PhotosStep({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PropertyWizardViewModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.photo_library_rounded,
              size: 50,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            AppLocalizations.of(context)!.propertyPhotos,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Subtitle
          Text(
            AppLocalizations.of(context)!.addPhotosToShowcase,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Photo options
          _OptionCard(
            icon: Icons.photo_library_rounded,
            title: AppLocalizations.of(context)!.chooseFromGalleryTitle,
            subtitle: AppLocalizations.of(context)!.selectMultiplePhotos,
            onTap: viewModel.pickMultipleImages,
          ),
          const SizedBox(height: 16),
          _OptionCard(
            icon: Icons.camera_alt_rounded,
            title: AppLocalizations.of(context)!.takePhoto,
            subtitle: AppLocalizations.of(context)!.useCameraToCapture,
            onTap: viewModel.takePhoto,
          ),
          const SizedBox(height: 24),

          // Photo grid
          if (viewModel.propertyImages.isNotEmpty) ...[
            _buildPhotoGrid(context, viewModel),
            const SizedBox(height: 16),
          ],

          // Info hint
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.info, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.photosOptionalHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Navigation buttons
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: AppLocalizations.of(context)!.back,
                  isOutlined: true,
                  onPressed: viewModel.previousStep,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: AppLocalizations.of(context)!.continueText,
                  onPressed: () => viewModel.nextStep(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(
    BuildContext context,
    PropertyWizardViewModel viewModel,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: viewModel.propertyImages.length,
      itemBuilder: (context, index) {
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                viewModel.propertyImages[index],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            if (index == 0)
              Positioned(
                left: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.mainPhoto,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 4,
              top: 4,
              child: GestureDetector(
                onTap: () => viewModel.removeImage(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Step 3: Location
class _LocationStep extends StatelessWidget {
  const _LocationStep({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PropertyWizardViewModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: viewModel.locationFormKey,
        child: Column(
          children: [
            // Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: viewModel.latitude != null
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                viewModel.latitude != null
                    ? Icons.check_circle
                    : Icons.location_on_rounded,
                size: 50,
                color: viewModel.latitude != null
                    ? AppColors.success
                    : AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              AppLocalizations.of(context)!.propertyLocation,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              AppLocalizations.of(context)!.setExactLocation,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Location set confirmation
            if (viewModel.latitude != null && viewModel.longitude != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.success),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.locationSet,
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${viewModel.latitude!.toStringAsFixed(6)}, ${viewModel.longitude!.toStringAsFixed(6)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: viewModel.clearLocation,
                      icon: const Icon(Icons.refresh),
                      label: Text(AppLocalizations.of(context)!.changeLocation),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ] else ...[
              // Map option
              _OptionCard(
                icon: Icons.map_rounded,
                title:AppLocalizations.of(context)!.selectOnMapTitle,
                subtitle: AppLocalizations.of(context)!.selectOnMapSubtitle,
                onTap: () => _showMapPicker(context, viewModel),
              ),
              const SizedBox(height: 16),

              // Manual entry option
              _OptionCard(
                icon: Icons.edit_location_outlined,
                title: AppLocalizations.of(context)!.enterCoordinates,
                subtitle: AppLocalizations.of(context)!.inputLatLngManually,
                onTap: () => _showManualEntry(context, viewModel),
              ),
              const SizedBox(height: 16),

              // Get current location option
              _OptionCard(
                icon: Icons.my_location,
                title: AppLocalizations.of(context)!.useCurrentLocation,
                subtitle: AppLocalizations.of(context)!.autoDetectCurrentPosition,
                isLoading: viewModel.isGeocodingLoading,
                onTap: viewModel.isGeocodingLoading
                    ? null
                    : () => viewModel.getCurrentLocation(),
              ),
              const SizedBox(height: 16),

              // Auto-detect from address option
              _OptionCard(
                icon: Icons.location_searching,
                title: AppLocalizations.of(context)!.estimateFromAddress,
                subtitle: AppLocalizations.of(context)!.findLocationUsingAddress,
                isLoading: viewModel.isGeocodingLoading,
                onTap: viewModel.isGeocodingLoading
                    ? null
                    : () => viewModel.geocodeAddress(),
              ),
              const SizedBox(height: 24),
            ],

            // Info hint
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.info,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.locationOptionalHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Navigation buttons
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: AppLocalizations.of(context)!.back,
                    isOutlined: true,
                    onPressed: viewModel.previousStep,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: AppLocalizations.of(context)!.continueText,
                    onPressed: () => viewModel.nextStep(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMapPicker(BuildContext context, PropertyWizardViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MapPickerSheet(viewModel: viewModel),
    );
  }

  void _showManualEntry(
    BuildContext context,
    PropertyWizardViewModel viewModel,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ManualLocationSheet(viewModel: viewModel),
    );
  }
}

class _MapPickerSheet extends StatefulWidget {
  final PropertyWizardViewModel viewModel;

  const _MapPickerSheet({required this.viewModel});

  @override
  State<_MapPickerSheet> createState() => _MapPickerSheetState();
}

class _MapPickerSheetState extends State<_MapPickerSheet> {
  late MapController _mapController;
  late LatLng _selectedLocation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    
    // Use existing location or default to Tunis
    final lat = widget.viewModel.latitude ?? 36.8065;
    final lng = widget.viewModel.longitude ?? 10.1815;
    _selectedLocation = LatLng(lat, lng);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
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
                      AppLocalizations.of(context)!.selectLocation,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.tapOnMapOrDragPin,
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
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                          heroTag: 'zoom_in',
                          backgroundColor: Colors.white,
                          onPressed: () {
                            _mapController.move(
                              _mapController.camera.center,
                              _mapController.camera.zoom + 1,
                            );
                          },
                          child: const Icon(Icons.add, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'zoom_out',
                          backgroundColor: Colors.white,
                          onPressed: () {
                            _mapController.move(
                              _mapController.camera.center,
                              _mapController.camera.zoom - 1,
                            );
                          },
                          child: const Icon(Icons.remove, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Coordinates display
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.selectedCoordinates,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.open_in_new),
                    tooltip: AppLocalizations.of(context)!.openInGoogleMapsShort,
                    onPressed: () async {
                      final url = ApiConstants.getGoogleMapsUrl(
                        _selectedLocation.latitude,
                        _selectedLocation.longitude,
                      );
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url));
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          // Confirm button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SafeArea(
              child: CustomButton(
                text: AppLocalizations.of(context)!.confirmLocation,
                onPressed: () {
                  widget.viewModel.setLocation(
                    _selectedLocation.latitude,
                    _selectedLocation.longitude,
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

class _ManualLocationSheet extends StatefulWidget {
  final PropertyWizardViewModel viewModel;

  const _ManualLocationSheet({required this.viewModel});

  @override
  State<_ManualLocationSheet> createState() => _ManualLocationSheetState();
}

class _ManualLocationSheetState extends State<_ManualLocationSheet> {
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.viewModel.latitude != null) {
      _latController.text = widget.viewModel.latitude!.toString();
    }
    if (widget.viewModel.longitude != null) {
      _lngController.text = widget.viewModel.longitude!.toString();
    }
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
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.enterCoordinatesTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                controller: _latController,
                hintText: AppLocalizations.of(context)!.latitudeHint,
                prefixIcon: Icons.north,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _lngController,
                hintText: AppLocalizations.of(context)!.longitudeHint,
                prefixIcon: Icons.east,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: AppLocalizations.of(context)!.saveLocation,
                onPressed: () {
                  final lat = double.tryParse(_latController.text);
                  final lng = double.tryParse(_lngController.text);
                  if (lat != null && lng != null) {
                    widget.viewModel.setLocation(lat, lng);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Step 4: Additional Information (Review & Create)
class _AdditionalInfoStep extends StatelessWidget {
  final Function(PropertyModel)? onPropertyCreated;

  const _AdditionalInfoStep({super.key, this.onPropertyCreated});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PropertyWizardViewModel>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.rate_review_rounded,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            AppLocalizations.of(context)!.reviewAndCreate,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            AppLocalizations.of(context)!.reviewPropertyDetails,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Error message
          if (viewModel.error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      viewModel.error!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Summary card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.summarize,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      AppLocalizations.of(context)!.propertySummary,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 8),
             
                _SummaryItem(
                  label: AppLocalizations.of(context)!.address,
                  value: viewModel.propertyAddressController.text,
                ),
                _SummaryItem(
                  label: AppLocalizations.of(context)!.type,
                  value: viewModel.selectedPropertyType == PropertyType.rent
                      ? AppLocalizations.of(context)!.forRent
                      : AppLocalizations.of(context)!.forSale,
                ),
                _SummaryItem(
                  label: AppLocalizations.of(context)!.status,
                  value: viewModel.selectedPropertyStatus.displayName,
                ),
                _SummaryItem(
                  label: AppLocalizations.of(context)!.photos,
                  value: '${viewModel.propertyImages.length} ${AppLocalizations.of(context)!.photosAdded}',
                ),
                _SummaryItem(
                  label: AppLocalizations.of(context)!.location,
                  value: viewModel.latitude != null
                      ? '${viewModel.latitude!.toStringAsFixed(4)}, ${viewModel.longitude!.toStringAsFixed(4)}'
                      : AppLocalizations.of(context)!.notSet,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Navigation buttons
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: AppLocalizations.of(context)!.back,
                  isOutlined: true,
                  onPressed: viewModel.previousStep,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: AppLocalizations.of(context)!.createProperty,
                  isLoading: viewModel.isLoading,
                  onPressed: () async {
                    final success = await viewModel.createProperty();
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context)!.propertyCreatedSuccessfully),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                      if (onPropertyCreated != null &&
                          viewModel.createdProperty != null) {
                        onPropertyCreated!(viewModel.createdProperty!);
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
