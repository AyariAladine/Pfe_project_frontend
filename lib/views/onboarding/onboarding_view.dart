import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pfe_project/views/home/home_view.dart';
import 'package:pfe_project/views/widgets/custom_button.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../viewmodels/onboarding/onboarding_viewmodel.dart';

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingViewModel(),
      child: const _OnboardingContent(),
    );
  }
}

class _OnboardingContent extends StatelessWidget {
  const _OnboardingContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Consumer<OnboardingViewModel>(
              builder: (context, vm, _) {
                // Show loading while checking existing progress
                if (vm.initialLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                return Column(
                  children: [
                    // Progress indicator
                    _buildProgressIndicator(context, vm),
                    
                    // Content
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildStepContent(context, l10n, vm),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, OnboardingViewModel vm) {
    final steps = OnboardingStep.values;
    final currentIndex = steps.indexOf(vm.currentStep);

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
    AppLocalizations l10n,
    OnboardingViewModel vm,
  ) {
    switch (vm.currentStep) {
      case OnboardingStep.welcome:
        return _WelcomeStep(key: const ValueKey('welcome'));
      case OnboardingStep.cinScan:
        return _CinScanStep(key: const ValueKey('cin'));
      case OnboardingStep.biometrics:
        return _BiometricsStep(key: const ValueKey('biometrics'));
      case OnboardingStep.complete:
        return _CompleteStep(key: const ValueKey('complete'));
    }
  }
}

// Welcome Step
class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vm = context.read<OnboardingViewModel>();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(32),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.verifyIdentity,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.verifyIdentityDesc,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          CustomButton(
            text: l10n.getStarted,
            onPressed: () => vm.nextStep(),
          ),
        ],
      ),
    );
  }
}

// CIN Scan Step
class _CinScanStep extends StatelessWidget {
  const _CinScanStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vm = context.watch<OnboardingViewModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.badge_rounded,
              size: 50,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.scanCin,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.scanCinDesc,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Error message
          if (vm.error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      vm.error!,
                      style: TextStyle(color: AppColors.error, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // CIN verified display
          if (vm.cinVerified && vm.cinNumber != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.success),
              ),
              child: Column(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    l10n.cinDetected,
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    vm.cinNumber!,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => vm.clearCin(),
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.scanAgain),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: l10n.continueText,
              onPressed: () => vm.nextStep(),
            ),
          ] else ...[
            // Scan buttons - work on both mobile and web
            // On web: camera uses file picker, backend does OCR
            // On mobile: camera uses device camera, ML Kit does local OCR
            _ScanOptionCard(
              icon: kIsWeb ? Icons.upload_file_rounded : Icons.camera_alt_rounded,
              title: kIsWeb ? l10n.translate('uploadImage') : l10n.scanWithCamera,
              subtitle: kIsWeb ? l10n.translate('uploadCinImage') : l10n.takePhotoOfCin,
              onTap: vm.isLoading ? null : () => vm.scanCinFromCamera(),
              isLoading: vm.isLoading,
            ),
            const SizedBox(height: 16),
            
            // Gallery button
            _ScanOptionCard(
              icon: Icons.photo_library_rounded,
              title: l10n.chooseFromGallery,
              subtitle: l10n.selectExistingPhoto,
              onTap: vm.isLoading ? null : () => vm.scanCinFromGallery(),
              isLoading: vm.isLoading,
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Back button
          TextButton.icon(
            onPressed: () => vm.previousStep(),
            icon: const Icon(Icons.arrow_back),
            label: Text(l10n.back),
          ),
        ],
      ),
    );
  }
}

class _ScanOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isLoading;

  const _ScanOptionCard({
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
            Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

// Biometrics Step
class _BiometricsStep extends StatelessWidget {
  const _BiometricsStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vm = context.watch<OnboardingViewModel>();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: vm.biometricsEnabled
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              vm.biometricsEnabled
                  ? Icons.check_circle
                  : Icons.fingerprint_rounded,
              size: 50,
              color: vm.biometricsEnabled ? AppColors.success : AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.setupBiometrics,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            kIsWeb ? l10n.biometricsNotAvailableWeb : l10n.setupBiometricsDesc,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Device info display
          if (vm.deviceId != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.smartphone,
                    label: l10n.device,
                    value: vm.deviceModel ?? 'Unknown',
                  ),
                  const Divider(height: 16),
                  _InfoRow(
                    icon: Icons.computer,
                    label: l10n.platform,
                    value: vm.devicePlatform?.toUpperCase() ?? 'Unknown',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          if (vm.error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                vm.error!,
                style: TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (!vm.biometricsEnabled) ...[
            if (!kIsWeb && vm.biometricsAvailable) ...[
              CustomButton(
                text: l10n.enableBiometrics,
                isLoading: vm.isLoading,
                onPressed: () => vm.authenticateWithBiometrics(l10n.biometricReason),
              ),
              const SizedBox(height: 16),
            ],
            TextButton(
              onPressed: () {
                vm.skipBiometrics();
                vm.nextStep();
              },
              child: Text(kIsWeb ? l10n.continueText : l10n.skipForNow),
            ),
          ] else ...[
            CustomButton(
              text: l10n.continueText,
              onPressed: () => vm.nextStep(),
            ),
          ],

          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () => vm.previousStep(),
            icon: const Icon(Icons.arrow_back),
            label: Text(l10n.back),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// Complete Step
class _CompleteStep extends StatelessWidget {
  const _CompleteStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vm = context.read<OnboardingViewModel>();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(32),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.setupComplete,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.setupCompleteDesc,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _SummaryRow(
                  icon: Icons.badge,
                  label: l10n.cinNumber,
                  value: vm.cinNumber ?? '-',
                  isVerified: vm.cinVerified,
                ),
                const Divider(height: 24),
                _SummaryRow(
                  icon: Icons.fingerprint,
                  label: l10n.biometrics,
                  value: vm.biometricsEnabled ? l10n.enabled : l10n.disabled,
                  isVerified: vm.biometricsEnabled,
                ),
                const Divider(height: 24),
                _SummaryRow(
                  icon: Icons.smartphone,
                  label: l10n.deviceRegistered,
                  value: vm.deviceModel ?? '-',
                  isVerified: vm.deviceId != null,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 48),
          CustomButton(
            text: l10n.goToHome,
            onPressed: () {
              // TODO: Submit onboarding data to backend
              final data = vm.getOnboardingData();
              debugPrint('Onboarding data: $data');
              
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeView()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isVerified;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isVerified,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isVerified
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.textHint.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isVerified ? AppColors.success : AppColors.textHint,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Icon(
          isVerified ? Icons.check_circle : Icons.remove_circle_outline,
          color: isVerified ? AppColors.success : AppColors.textHint,
          size: 20,
        ),
      ],
    );
  }
}
