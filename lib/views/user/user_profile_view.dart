import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../viewmodels/user/user_profile_viewmodel.dart';

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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
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

  // ─── Avatar (initials circle) ───────────────────────────────────────

  Widget _buildAvatarSection(
    UserProfileViewModel vm,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final user = vm.user;
    final initials = _getInitials(user?.name, user?.lastName);
    return Center(
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user?.fullName ?? '',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
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

  // ─── Save ─────────────────────────────────────────────────────────

  Future<void> _saveProfile(
    BuildContext context,
    UserProfileViewModel vm,
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
