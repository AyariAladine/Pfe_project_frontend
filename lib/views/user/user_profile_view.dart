import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../viewmodels/user/user_profile_viewmodel.dart';
import '../widgets/camera_capture.dart';
import '../widgets/generated_signature.dart';

/// User profile editing content (no Scaffold – used inside MainShell)
class UserProfileContent extends StatefulWidget {
  const UserProfileContent({super.key});

  @override
  State<UserProfileContent> createState() => _UserProfileContentState();
}

class _UserProfileContentState extends State<UserProfileContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  void _loadProfile() {
    final authVM = context.read<AuthViewModel>();
    final profileVM = context.read<UserProfileViewModel>();
    final user = authVM.currentUser;
    if (user != null) {
      profileVM.loadFromUser(user);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<UserProfileViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (vm.errorMessage != null && vm.user == null) {
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
    UserProfileViewModel vm,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                  // ── User avatar placeholder ──
                  _buildAvatarSection(vm, l10n, isDark),

                  const SizedBox(height: 20),

                  // ── Personal Information Section ──
                  _buildSectionCard(
                    context: context,
                    isDark: isDark,
                    icon: Icons.edit_note_rounded,
                    title: l10n.personalInformation,
                    child:
                        _buildPersonalInfoSection(context, vm, l10n, isDark),
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

        // Success / Error snack overlay
        if (vm.successMessage != null || vm.errorMessage != null)
          _buildSnackOverlay(context, vm, l10n),
      ],
    );
  }

  // ─── Avatar (initials circle) ───────────────────────────────────────

  Widget _buildAvatarSection(
    UserProfileViewModel vm,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final user = vm.user;
    final initials = _getInitials(user?.name, user?.lastName);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            Color.lerp(AppColors.primary, AppColors.primaryDark, 0.55)!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.45),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 12.5,
                  ),
                ),
                if ((user?.isVerified == true) || (user?.faceRegistered == true)) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (user!.isVerified == true)
                        _WhiteBadge(
                          icon: Icons.badge_rounded,
                          label: l10n.identityVerified,
                        ),
                      if (user.faceRegistered)
                        _WhiteBadge(
                          icon: Icons.face_retouching_natural_rounded,
                          label: 'Face ID',
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String? name, String? lastName) {
    final first = (name != null && name.isNotEmpty) ? name[0] : '';
    final last = (lastName != null && lastName.isNotEmpty) ? lastName[0] : '';
    return '$first$last'.toUpperCase();
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AppColors.primary.withValues(alpha: 0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }

  // ─── Personal Information Fields ──────────────────────────────────

  Widget _buildPersonalInfoSection(
    BuildContext context,
    UserProfileViewModel vm,
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

  // ─── Face Recognition Section ────────────────────────────────────

  Widget _buildFaceRecognitionSection(
    BuildContext context,
    UserProfileViewModel vm,
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
          // Register / Verify row
          Row(
            children: [
              if (!vm.faceRegistered)
                Expanded(
                  child: _buildFaceButton(
                    label: l10n.registerFace,
                    icon: Icons.add_a_photo_rounded,
                    color: AppColors.primary,
                    isDark: isDark,
                    onTap: () => _pickAndProcess(
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
                    onTap: () => _pickAndProcess(
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

  Future<void> _pickAndProcess(
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

  String _localizedFaceMessage(AppLocalizations l10n, UserProfileViewModel vm) {
    switch (vm.faceMessage) {
      case 'FACE_REGISTERED':
        return l10n.faceRegistrationSuccess;
      case 'FACE_VERIFIED':
        final name = vm.user?.fullName ?? '';
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
        fillColor: isDark ? AppColors.surfaceDark : AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // ─── Electronic Signature Section ──────────────────────────────

  final GlobalKey<GeneratedSignatureWidgetState> _signatureKey = GlobalKey();

  Widget _buildSignatureSection(
    BuildContext context,
    UserProfileViewModel vm,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final firstName = vm.user?.name ?? '';
    final lastName = vm.user?.lastName ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hint
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

        // Auto-generated signature preview (always shown)
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

  Future<void> _saveSignature(UserProfileViewModel vm) async {
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

  // ─── Save ─────────────────────────────────────────────────────────
  Future<void> _showPasswordDialogAndRemove(
    BuildContext context,
    UserProfileViewModel vm,
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
    UserProfileViewModel vm,
    AppLocalizations l10n,
  ) async {
    final authVM = context.read<AuthViewModel>();
    final success = await vm.saveProfile();
    if (success && mounted) {
      authVM.refreshProfile();
    }
  }

  // ─── Success / Error overlay ──────────────────────────────────────

  Widget _buildSnackOverlay(
    BuildContext context,
    UserProfileViewModel vm,
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

class _WhiteBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _WhiteBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

