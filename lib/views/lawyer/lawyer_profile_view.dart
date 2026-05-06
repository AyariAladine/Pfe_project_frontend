import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../viewmodels/lawyer/lawyer_profile_viewmodel.dart';
import '../widgets/camera_capture.dart';
import '../widgets/network_image_with_auth.dart';
import '../widgets/generated_signature.dart';

/// Lawyer profile editing content (no Scaffold – used inside MainShell)
class LawyerProfileContent extends StatefulWidget {
  const LawyerProfileContent({super.key});

  @override
  State<LawyerProfileContent> createState() => _LawyerProfileContentState();
}

class _LawyerProfileContentState extends State<LawyerProfileContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  void _loadProfile() {
    final authVM = context.read<AuthViewModel>();
    final profileVM = context.read<LawyerProfileViewModel>();
    final userId = authVM.currentUser?.id;
    if (userId != null) {
      profileVM.loadProfile(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<LawyerProfileViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (vm.errorMessage != null && vm.lawyer == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text(vm.errorMessage!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadProfile,
                  child: Text(l10n.tryAgain),
                ),
              ],
            ),
          );
        }

        return _buildProfileForm(context, vm, l10n, isDark);
      },
    );
  }

  Widget _buildProfileForm(
    BuildContext context,
    LawyerProfileViewModel vm,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Profile Picture Section ──
                  _buildSectionCard(
                    context: context,
                    isDark: isDark,
                    icon: Icons.person_rounded,
                    title: l10n.profilePicture,
                    child: _buildPictureSection(context, vm, l10n, isDark),
                  ),

                  const SizedBox(height: 20),

                  // ── Personal Information Section ──
                  _buildSectionCard(
                    context: context,
                    isDark: isDark,
                    icon: Icons.edit_note_rounded,
                    title: l10n.personalInformation,
                    child: _buildPersonalInfoSection(context, vm, l10n, isDark),
                  ),

                  const SizedBox(height: 20),

                  // ── Verification Section ──
                  _buildSectionCard(
                    context: context,
                    isDark: isDark,
                    icon: Icons.verified_user_rounded,
                    title: l10n.lawyerVerification,
                    child: _buildVerificationSection(context, vm, l10n, isDark),
                  ),

                  const SizedBox(height: 20),

                  // ── Face Recognition Section ──
                  _buildSectionCard(
                    context: context,
                    isDark: isDark,
                    icon: Icons.face_retouching_natural_rounded,
                    title: l10n.faceRecognition,
                    child: _buildFaceRecognitionSection(
                        context, vm, l10n, isDark),
                  ),

                  const SizedBox(height: 20),

                  // ── Electronic Signature Section ──
                  _buildSectionCard(
                    context: context,
                    isDark: isDark,
                    icon: Icons.draw_rounded,
                    title: l10n.electronicSignature,
                    child: _buildSignatureSection(
                        context, vm, l10n, isDark),
                  ),

                  const SizedBox(height: 20),

                  // ── Office Location Section ──
                  _buildSectionCard(
                    context: context,
                    isDark: isDark,
                    icon: Icons.location_on_rounded,
                    title: l10n.officeLocation,
                    child: _buildLocationSection(context, vm, l10n, isDark),
                  ),

                  const SizedBox(height: 24),

                  // ── Save Button ──
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: vm.hasChanges && !vm.isSaving
                          ? () => _saveProfile(context, vm, l10n)
                          : null,
                      icon: vm.isSaving
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
                        vm.isSaving ? l10n.saving : l10n.saveProfile,
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

        // Success / Error snack overlay
        if (vm.successMessage != null || vm.errorMessage != null)
          _buildSnackOverlay(context, vm, l10n),
      ],
    );
  }

  // ─── Section Card Wrapper ─────────────────────────────────────────

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

  // ─── Profile Picture ──────────────────────────────────────────────

  Widget _buildPictureSection(
    BuildContext context,
    LawyerProfileViewModel vm,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final hasExisting = vm.lawyer?.profileImageUrl != null &&
        vm.lawyer!.profileImageUrl!.isNotEmpty;
    final hasPicked = vm.pictureBytes != null;

    return Column(
      children: [
        // Picture preview
        Center(
          child: Stack(
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 3,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasPicked
                    ? ClipOval(
                        child: Image.memory(
                          vm.pictureBytes!,
                          fit: BoxFit.cover,
                          width: 140,
                          height: 140,
                        ),
                      )
                    : hasExisting
                        ? ClipOval(
                            child: NetworkImageWithAuth(
                              imageUrl: ApiConstants.getLawyerPictureUrl(
                                  vm.lawyer!.profileImageUrl),
                              fit: BoxFit.cover,
                              width: 140,
                              height: 140,
                              placeholder: () => _buildAvatarPlaceholder(vm),
                              errorBuilder: () => _buildAvatarPlaceholder(vm),
                            ),
                          )
                        : _buildAvatarPlaceholder(vm),
              ),
              // Edit badge
              Positioned(
                bottom: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _showPictureOptions(context, vm, l10n),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Upload buttons row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: OutlinedButton.icon(
                onPressed: () => vm.pickPicture(),
                icon: const Icon(Icons.photo_library_rounded, size: 18),
                label: Text(l10n.uploadPicture),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: OutlinedButton.icon(
                onPressed: () => vm.takePicture(),
                icon: const Icon(Icons.camera_alt_rounded, size: 18),
                label: Text(l10n.takePhoto),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  side: const BorderSide(color: AppColors.secondary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatarPlaceholder(LawyerProfileViewModel vm) {
    final initials = vm.lawyer != null
        ? '${vm.lawyer!.name.isNotEmpty ? vm.lawyer!.name[0] : ''}${vm.lawyer!.lastName.isNotEmpty ? vm.lawyer!.lastName[0] : ''}'
            .toUpperCase()
        : '?';
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  void _showPictureOptions(
    BuildContext context,
    LawyerProfileViewModel vm,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading:
                    const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                title: Text(l10n.uploadPicture),
                onTap: () {
                  Navigator.pop(context);
                  vm.pickPicture();
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.camera_alt_rounded, color: AppColors.secondary),
                title: Text(l10n.takePhoto),
                onTap: () {
                  Navigator.pop(context);
                  vm.takePicture();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Personal Information (editable text fields) ───────────────────

  Widget _buildPersonalInfoSection(
    BuildContext context,
    LawyerProfileViewModel vm,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return Column(
      children: [
        // First Name
        _buildTextField(
          controller: vm.nameController,
          label: l10n.firstName,
          icon: Icons.person_outline_rounded,
          isDark: isDark,
          onChanged: (_) => vm.markChanged(),
        ),
        const SizedBox(height: 14),
        // Last Name
        _buildTextField(
          controller: vm.lastNameController,
          label: l10n.lastName,
          icon: Icons.person_outline_rounded,
          isDark: isDark,
          onChanged: (_) => vm.markChanged(),
        ),
        const SizedBox(height: 14),
        // Email
        _buildTextField(
          controller: vm.emailController,
          label: l10n.email,
          icon: Icons.email_outlined,
          isDark: isDark,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => vm.markChanged(),
        ),
        const SizedBox(height: 14),
        // Phone
        _buildTextField(
          controller: vm.phoneController,
          label: l10n.phoneNumber,
          icon: Icons.phone_outlined,
          isDark: isDark,
          keyboardType: TextInputType.phone,
          onChanged: (_) => vm.markChanged(),
        ),
        const SizedBox(height: 14),
        // Identity Number
        _buildTextField(
          controller: vm.identityNumberController,
          label: l10n.identityNumber,
          icon: Icons.badge_outlined,
          isDark: isDark,
          keyboardType: TextInputType.number,
          onChanged: (_) => vm.markChanged(),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
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
        fillColor: isDark
            ? AppColors.surfaceDark
            : AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // ─── Lawyer Verification ────────────────────────────────────────────

  Widget _buildVerificationSection(
    BuildContext context,
    LawyerProfileViewModel vm,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final isVerified = vm.isVerified;
    final isVerifying = vm.isVerifying;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Status indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isVerified == true
                ? AppColors.success.withValues(alpha: 0.1)
                : isVerified == false
                    ? Colors.red.withValues(alpha: 0.1)
                    : (isDark ? Colors.white10 : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isVerified == true
                  ? AppColors.success.withValues(alpha: 0.3)
                  : isVerified == false
                      ? Colors.red.withValues(alpha: 0.3)
                      : (isDark ? Colors.white24 : Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: [
              if (isVerifying)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  isVerified == true
                      ? Icons.verified_rounded
                      : isVerified == false
                          ? Icons.cancel_rounded
                          : Icons.help_outline_rounded,
                  color: isVerified == true
                      ? AppColors.success
                      : isVerified == false
                          ? Colors.red
                          : AppColors.textSecondary,
                  size: 22,
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isVerifying
                          ? l10n.verifying
                          : isVerified == true
                              ? l10n.lawyerVerified
                              : isVerified == false
                                  ? l10n.lawyerNotVerified
                                  : l10n.notVerified,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isVerified == true
                            ? AppColors.success
                            : isVerified == false
                                ? Colors.red
                                : (isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary),
                      ),
                    ),
                    if (isVerified == true && vm.verifiedName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        l10n.registeredInBarAssociation,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (isVerified == false) ...[
                      const SizedBox(height: 2),
                      Text(
                        l10n.notRegisteredInBarAssociation,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade300,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Verify button
        ElevatedButton.icon(
          onPressed: isVerifying ? null : () => vm.verifyLawyer(),
          icon: isVerifying
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.search_rounded, size: 20),
          label: Text(
            isVerifying ? l10n.verifying : l10n.verifyLawyer,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Office Location (Map Picker) ──────────────────────────────────

  Widget _buildLocationSection(
    BuildContext context,
    LawyerProfileViewModel vm,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Current location display
        if (vm.hasLocation) ...[
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
                    '${l10n.locationSet}: ${vm.latitude!.toStringAsFixed(5)}, ${vm.longitude!.toStringAsFixed(5)}',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      color: AppColors.textSecondary, size: 20),
                  onPressed: () => vm.clearLocation(),
                  tooltip: l10n.cancel,
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
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: IgnorePointer(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(vm.latitude!, vm.longitude!),
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
                        point: LatLng(vm.latitude!, vm.longitude!),
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

        // Open map picker button
        OutlinedButton.icon(
          onPressed: () => _openMapPicker(context, vm, l10n),
          icon: const Icon(Icons.map_rounded, size: 20),
          label: Text(
            vm.hasLocation ? l10n.changeLocation : l10n.setOfficeLocation,
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

  void _openMapPicker(
    BuildContext context,
    LawyerProfileViewModel vm,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LawyerMapPickerSheet(
        initialLat: vm.latitude,
        initialLng: vm.longitude,
        onLocationSelected: (lat, lng) {
          vm.setLocation(lat, lng);
        },
      ),
    );
  }

  // ─── Face Recognition Section ────────────────────────────────────

  Widget _buildFaceRecognitionSection(
    BuildContext context,
    LawyerProfileViewModel vm,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return Column(
      children: [
        // Status indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: vm.faceRegistered
                ? AppColors.success.withValues(alpha: 0.08)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.grey.withValues(alpha: 0.06)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                vm.faceRegistered
                    ? Icons.verified_user_rounded
                    : Icons.face_outlined,
                color: vm.faceRegistered
                    ? AppColors.success
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  vm.faceRegistered
                      ? l10n.faceRegistered
                      : l10n.faceNotRegistered,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: vm.faceRegistered
                        ? AppColors.success
                        : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Face message feedback
        if (vm.faceMessage != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _isFaceSuccess(vm.faceMessage!)
                  ? AppColors.success.withValues(alpha: 0.08)
                  : AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isFaceSuccess(vm.faceMessage!)
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.error.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isFaceSuccess(vm.faceMessage!)
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  color: _isFaceSuccess(vm.faceMessage!)
                      ? AppColors.success
                      : AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _localizedFaceMessage(l10n, vm),
                    style: TextStyle(
                      fontSize: 13,
                      color: _isFaceSuccess(vm.faceMessage!)
                          ? AppColors.success
                          : AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Action buttons
        if (vm.isFaceProcessing)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            ),
          )
        else ...[
          Row(
            children: [
              if (!vm.faceRegistered)
                Expanded(
                  child: _buildFaceButton(
                    label: l10n.registerFace,
                    icon: Icons.add_a_photo_rounded,
                    color: AppColors.primary,
                    isDark: isDark,
                    onTap: () => _pickFaceAndProcess(
                      context,
                      (bytes) => vm.registerFace(bytes),
                    ),
                  ),
                ),
              if (vm.faceRegistered) ...[
                Expanded(
                  child: _buildFaceButton(
                    label: l10n.verifyFace,
                    icon: Icons.camera_alt_rounded,
                    color: AppColors.primary,
                    isDark: isDark,
                    onTap: () => _pickFaceAndProcess(
                      context,
                      (bytes) => vm.verifyFace(bytes),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFaceButton(
                    label: l10n.removeFace,
                    icon: Icons.delete_outline_rounded,
                    color: AppColors.error,
                    isDark: isDark,
                    onTap: () => _showPasswordDialogAndRemove(context, vm, l10n, isDark),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFaceButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: isDark ? 0.15 : 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFaceAndProcess(
    BuildContext context,
    Future<void> Function(dynamic bytes) action,
  ) async {
    final bytes = await captureFromCamera(context);
    if (bytes == null) return;
    await action(bytes);
  }

  bool _isFaceSuccess(String msg) =>
      msg == 'FACE_REGISTERED' ||
      msg == 'FACE_VERIFIED' ||
      msg == 'FACE_REMOVED';

  String _localizedFaceMessage(
      AppLocalizations l10n, LawyerProfileViewModel vm) {
    switch (vm.faceMessage) {
      case 'FACE_REGISTERED':
        return l10n.faceRegistrationSuccess;
      case 'FACE_VERIFIED':
        final name = vm.lawyer?.fullName ?? '';
        final conf = vm.faceConfidence != null
            ? '\n${l10n.faceConfidence((vm.faceConfidence! * 100).toStringAsFixed(1))}'
            : '';
        return '${l10n.faceVerificationSuccess(name)}$conf';
      case 'FACE_LOW_CONFIDENCE':
        final lowConf = vm.faceConfidence != null
            ? ' ${l10n.faceConfidence((vm.faceConfidence! * 100).toStringAsFixed(1))}'
            : '';
        return '${l10n.faceLowConfidence}$lowConf';
      case 'FACE_NOT_RECOGNIZED':
        return l10n.faceVerificationFailed;
      case 'FACE_DELETE_WRONG_PASSWORD':
        return l10n.wrongPassword;
      case 'FACE_REMOVED':
        return l10n.faceRemoved;
      default:
        return vm.faceMessage ?? '';
    }
  }

  // ─── Electronic Signature Section ──────────────────────────────

  final GlobalKey<GeneratedSignatureWidgetState> _signatureKey = GlobalKey();

  Widget _buildSignatureSection(
    BuildContext context,
    LawyerProfileViewModel vm,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final firstName = vm.lawyer?.name ?? '';
    final lastName = vm.lawyer?.lastName ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.signatureHint,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),

        // Saved badge
        if (vm.hasSignature) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, color: AppColors.success, size: 22),
                const SizedBox(width: 10),
                Text(
                  l10n.signatureSavedLabel,
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Auto-generated signature preview
        Text(
          'Your electronic signature:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: GeneratedSignatureWidget(
              key: _signatureKey,
              firstName: firstName,
              lastName: lastName,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Action buttons
        Row(
          children: [
            if (vm.hasSignature) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: vm.isSignatureProcessing
                      ? null
                      : () async {
                          await vm.deleteSignature();
                          if (mounted) setState(() {});
                        },
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text(l10n.deleteSignature),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    vm.isSignatureProcessing ? null : () => _saveSignature(vm),
                icon: vm.isSignatureProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(
                  vm.hasSignature ? 'Re-save Signature' : l10n.saveSignature,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),

        // Feedback message
        if (vm.signatureMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _isSignatureSuccess(vm.signatureMessage!)
                  ? AppColors.success.withValues(alpha: 0.08)
                  : AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _localizedSignatureMessage(l10n, vm.signatureMessage!),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _isSignatureSuccess(vm.signatureMessage!)
                    ? AppColors.success
                    : AppColors.error,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _saveSignature(LawyerProfileViewModel vm) async {
    final bytes = await _signatureKey.currentState?.toPngBytes();
    if (bytes == null) return;
    await vm.saveSignature(bytes);
    if (mounted) setState(() {});
  }

  bool _isSignatureSuccess(String msg) =>
      msg == 'SIGNATURE_SAVED' || msg == 'SIGNATURE_DELETED';

  String _localizedSignatureMessage(AppLocalizations l10n, String msg) {
    switch (msg) {
      case 'SIGNATURE_SAVED':
        return l10n.signatureSaved;
      case 'SIGNATURE_DELETED':
        return l10n.signatureDeleted;
      default:
        return msg;
    }
  }

  // ─── Save ────────────────────────────────────────────────────────

  Future<void> _showPasswordDialogAndRemove(
    BuildContext context,
    LawyerProfileViewModel vm,
    AppLocalizations l10n,
    bool isDark,
  ) async {
    final passwordController = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeFace),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.enterPasswordToDelete),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.password,
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, passwordController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.removeFace),
          ),
        ],
      ),
    );
    passwordController.dispose();
    if (password != null && password.isNotEmpty) {
      await vm.removeFace(password);
    }
  }

  Future<void> _saveProfile(
    BuildContext context,
    LawyerProfileViewModel vm,
    AppLocalizations l10n,
  ) async {
    final success = await vm.saveProfile();
    if (success && mounted) {
      // Also refresh auth user data
      final authVM = context.read<AuthViewModel>();
      authVM.refreshProfile();
    }
  }

  // ─── Success / Error overlay ──────────────────────────────────────

  Widget _buildSnackOverlay(
    BuildContext context,
    LawyerProfileViewModel vm,
    AppLocalizations l10n,
  ) {
    final isSuccess = vm.successMessage != null;
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
                  isSuccess ? l10n.profileUpdated : l10n.profileUpdateFailed,
                  style: TextStyle(
                    color: isSuccess ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => vm.clearMessages(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Map Picker Bottom Sheet (reuses pattern from create_property_wizard_view)
// ═══════════════════════════════════════════════════════════════════════

class _LawyerMapPickerSheet extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final void Function(double lat, double lng) onLocationSelected;

  const _LawyerMapPickerSheet({
    this.initialLat,
    this.initialLng,
    required this.onLocationSelected,
  });

  @override
  State<_LawyerMapPickerSheet> createState() => _LawyerMapPickerSheetState();
}

class _LawyerMapPickerSheetState extends State<_LawyerMapPickerSheet> {
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
                      l10n.setOfficeLocation,
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
                          heroTag: 'profile_zoom_in',
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
                          heroTag: 'profile_zoom_out',
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
