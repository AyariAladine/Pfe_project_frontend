import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pfe_project/views/home/main_shell.dart';
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

                // All steps already completed — go straight to home
                if (vm.allComplete && vm.currentStep != OnboardingStep.complete) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const MainShell()),
                      (route) => false,
                    );
                  });
                  return const Center(child: CircularProgressIndicator());
                }
                
                return Column(
                  children: [
                    // Progress indicator + skip button
                    Row(
                      children: [
                        Expanded(child: _buildProgressIndicator(context, vm)),
                        if (vm.currentStep != OnboardingStep.complete)
                          Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: TextButton(
                              onPressed: () => _skipOnboarding(context),
                              child: Text(
                                l10n.skip,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    
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

  void _skipOnboarding(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
      (route) => false,
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
      case OnboardingStep.cinFrontScan:
        return _CinFrontScanStep(key: const ValueKey('cin_front'));
      case OnboardingStep.cinBackScan:
        return _CinBackScanStep(key: const ValueKey('cin_back'));
      case OnboardingStep.phoneVerification:
        return _PhoneVerificationStep(key: const ValueKey('phone'));
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

// Phone Verification Step
class _PhoneVerificationStep extends StatefulWidget {
  const _PhoneVerificationStep({super.key});

  @override
  State<_PhoneVerificationStep> createState() => _PhoneVerificationStepState();
}

class _PhoneVerificationStepState extends State<_PhoneVerificationStep> {
  final _codeController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

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
              color: vm.phoneVerified
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              vm.phoneVerified ? Icons.check_circle : Icons.sms_rounded,
              size: 50,
              color: vm.phoneVerified ? AppColors.success : AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.verifyPhone,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.verifyPhoneDesc,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Show user's phone number
          if (vm.phoneNumber != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                vm.phoneNumber!,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Error
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

          // Already verified
          if (vm.phoneVerified) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.success),
              ),
              child: Column(
                children: [
                  Icon(Icons.verified, color: AppColors.success, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    l10n.phoneVerified,
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: l10n.continueText,
              onPressed: () => vm.nextStep(),
            ),
          ]
          // OTP sent — show code input
          else if (vm.otpSent) ...[
            Text(
              l10n.enterOtpCode,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
              decoration: InputDecoration(
                hintText: '------',
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: l10n.verifyCode,
              isLoading: vm.isLoading,
              onPressed: vm.isLoading
                  ? null
                  : () async {
                      final code = _codeController.text.trim();
                      if (code.length != 6) return;
                      final ok = await vm.verifyOtp(code);
                      if (ok) {
                        vm.nextStep();
                      }
                    },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: vm.isLoading
                  ? null
                  : () {
                      vm.resetOtp();
                      _codeController.clear();
                    },
              child: Text(l10n.resendCode),
            ),
          ]
          // Initial state — send code button
          else ...[
            CustomButton(
              text: l10n.sendVerificationCode,
              isLoading: vm.isLoading,
              onPressed: vm.isLoading ? null : () => vm.sendOtp(),
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

// CIN Front Side Scan Step
class _CinFrontScanStep extends StatelessWidget {
  const _CinFrontScanStep({super.key});

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
            child: Icon(Icons.badge_rounded, size: 50, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.cinFrontSide,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.cinFrontDesc,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

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
                    child: Text(vm.error!, style: TextStyle(color: AppColors.error, fontSize: 14)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          _IdCardSideCaptureCard(
            title: l10n.cinFrontSide,
            description: l10n.cinFrontDesc,
            isCaptured: vm.hasFrontIdCard,
            isConfirmed: vm.frontInfoConfirmed,
            isEnabled: true,
            fieldCount: vm.frontExtractedFields.length,
            primaryLabel: kIsWeb ? l10n.uploadImage : l10n.scanWithCamera,
            secondaryLabel: l10n.chooseFromGallery,
            onPrimaryTap: vm.isLoading ? null : () => vm.scanFrontIdCardFromCamera(),
            onSecondaryTap: vm.isLoading ? null : () => vm.scanFrontIdCardFromGallery(),
            onClear: vm.hasFrontIdCard ? () => vm.clearFrontIdCard() : null,
            isLoading: vm.isLoading,
          ),
          if (vm.hasFrontIdCard) ...[
            const SizedBox(height: 16),
            _ExtractedDataCard(
              title: l10n.cinFrontReview,
              subtitle: vm.frontInfoConfirmed
                  ? l10n.cinFrontConfirmedSubtitle
                  : l10n.cinReviewSubtitle,
              fields: vm.frontDisplayFields,
              primaryLabel: vm.frontInfoConfirmed
                  ? l10n.cinFrontConfirmedBtn
                  : l10n.cinConfirmFront,
              primaryEnabled: !vm.frontInfoConfirmed,
              onPrimaryTap: vm.frontInfoConfirmed ? null : vm.confirmFrontIdCardInfo,
              statusColor: vm.frontInfoConfirmed ? AppColors.success : AppColors.primary,
              fieldConfidences: vm.frontFieldConfidences,
              onFieldChanged: vm.frontInfoConfirmed
                  ? null
                  : (key, value) => vm.updateFrontExtractedField(key, value),
            ),
          ],

          if (vm.frontInfoConfirmed) ...[
            const SizedBox(height: 24),
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

// CIN Back Side Scan Step
class _CinBackScanStep extends StatelessWidget {
  const _CinBackScanStep({super.key});

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
            child: Icon(Icons.badge_rounded, size: 50, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.cinBackSide,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.cinBackDesc,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

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
                    child: Text(vm.error!, style: TextStyle(color: AppColors.error, fontSize: 14)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          _IdCardSideCaptureCard(
            title: l10n.cinBackSide,
            description: l10n.cinBackDesc,
            isCaptured: vm.hasBackIdCard,
            isConfirmed: vm.backInfoConfirmed,
            isEnabled: vm.canCaptureBackSide,
            fieldCount: vm.backExtractedFields.length,
            primaryLabel: kIsWeb ? l10n.uploadImage : l10n.scanWithCamera,
            secondaryLabel: l10n.chooseFromGallery,
            onPrimaryTap: vm.isLoading || !vm.canCaptureBackSide
                ? null
                : () => vm.scanBackIdCardFromCamera(),
            onSecondaryTap: vm.isLoading || !vm.canCaptureBackSide
                ? null
                : () => vm.scanBackIdCardFromGallery(),
            onClear: vm.hasBackIdCard ? () => vm.clearBackIdCard() : null,
            isLoading: vm.isLoading,
          ),
          if (vm.hasBackIdCard) ...[
            const SizedBox(height: 16),
            _ExtractedDataCard(
              title: l10n.cinBackReview,
              subtitle: vm.backInfoConfirmed
                  ? l10n.cinBackConfirmedSubtitle
                  : l10n.cinReviewSubtitle,
              fields: vm.backDisplayFields,
              primaryLabel: vm.backInfoConfirmed
                  ? l10n.cinBackConfirmedBtn
                  : l10n.cinConfirmBack,
              primaryEnabled: !vm.backInfoConfirmed,
              onPrimaryTap: vm.backInfoConfirmed ? null : vm.confirmBackIdCardInfo,
              statusColor: vm.backInfoConfirmed ? AppColors.success : AppColors.primary,
              fieldConfidences: vm.backFieldConfidences,
              onFieldChanged: vm.backInfoConfirmed
                  ? null
                  : (key, value) => vm.updateBackExtractedField(key, value),
            ),
          ],

          if (vm.canReviewCombinedIdData) ...[
            const SizedBox(height: 24),
            _ExtractedDataCard(
              title: l10n.cinFinalReview,
              subtitle: vm.finalIdVerificationConfirmed
                  ? l10n.cinAllConfirmedSubtitle
                  : l10n.cinVerifySubtitle,
              fields: vm.extractedIdCardFields,
              highlightedValue: vm.cinNumber,
              primaryLabel: vm.finalIdVerificationConfirmed
                  ? l10n.cinAllVerifiedBtn
                  : l10n.cinVerifyAllBtn,
              primaryEnabled: !vm.finalIdVerificationConfirmed,
              onPrimaryTap: vm.finalIdVerificationConfirmed
                  ? null
                  : vm.verifyCollectedIdCardInfo,
              statusColor: vm.finalIdVerificationConfirmed
                  ? AppColors.success
                  : AppColors.primary,
            ),
          ],

          if (vm.cinVerified) ...[
            const SizedBox(height: 24),
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

// ignore: unused_element
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
    final vm = context.watch<OnboardingViewModel>();

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
                  icon: Icons.phone_android,
                  label: l10n.phoneNumber,
                  value: vm.phoneVerified ? (vm.phoneNumber ?? '-') : '-',
                  isVerified: vm.phoneVerified,
                ),
                const Divider(height: 24),
                _SummaryRow(
                  icon: Icons.badge,
                  label: l10n.cinNumber,
                  value: vm.cinNumber ?? '-',
                  isVerified: vm.cinVerified,
                ),
                const Divider(height: 24),
                _SummaryRow(
                  icon: Icons.credit_card,
                  label: l10n.scanIdCard,
                  value: vm.idCardCaptureSummary,
                  isVerified: vm.hasCompleteIdCardData,
                ),
                const Divider(height: 24),
                _SummaryRow(
                  icon: Icons.fingerprint,
                  label: l10n.biometrics,
                  value: vm.biometricsEnabled ? l10n.enabled : l10n.disabled,
                  isVerified: vm.biometricsEnabled,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 48),
          CustomButton(
            text: l10n.goToHome,
            isLoading: vm.isLoading,
            onPressed: vm.isLoading
                ? null
                : () async {
                    try {
                      final data = await vm.submitOnboardingData();
                      debugPrint('Onboarding data submitted: $data');
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const MainShell()),
                        (route) => false,
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  },
          ),
        ],
      ),
    );
  }
}

class _IdCardSideCaptureCard extends StatelessWidget {
  final String title;
  final String description;
  final bool isCaptured;
  final bool isConfirmed;
  final bool isEnabled;
  final int fieldCount;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback? onPrimaryTap;
  final VoidCallback? onSecondaryTap;
  final VoidCallback? onClear;
  final bool isLoading;

  const _IdCardSideCaptureCard({
    required this.title,
    required this.description,
    required this.isCaptured,
    required this.isConfirmed,
    required this.isEnabled,
    required this.fieldCount,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimaryTap,
    required this.onSecondaryTap,
    required this.onClear,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConfirmed
              ? AppColors.success
              : isCaptured
                  ? AppColors.primary
                  : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (isCaptured ? AppColors.success : AppColors.textHint)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isConfirmed
                      ? AppLocalizations.of(context)!.confirmed
                      : isCaptured
                          ? AppLocalizations.of(context)!.cinFieldsExtracted(fieldCount)
                          : isEnabled
                              ? AppLocalizations.of(context)!.cinNotScanned
                              : AppLocalizations.of(context)!.cinLocked,
                  style: TextStyle(
                    color: isConfirmed
                        ? AppColors.success
                        : isCaptured
                            ? AppColors.primary
                            : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ScanOptionCard(
                  icon: Icons.camera_alt_rounded,
                  title: primaryLabel,
                  subtitle: description,
                  onTap: isEnabled ? onPrimaryTap : null,
                  isLoading: isLoading,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ScanOptionCard(
                  icon: Icons.photo_library_rounded,
                  title: secondaryLabel,
                  subtitle: AppLocalizations.of(context)!.selectExistingPhoto,
                  onTap: isEnabled ? onSecondaryTap : null,
                  isLoading: isLoading,
                ),
              ),
            ],
          ),
          if (onClear != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context)!.cinRescan),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExtractedDataCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final Map<String, dynamic> fields;
  final String primaryLabel;
  final bool primaryEnabled;
  final VoidCallback? onPrimaryTap;
  final Color statusColor;
  final String? highlightedValue;
  /// Called when the user edits a field value inline.
  final void Function(String key, String value)? onFieldChanged;
  /// Per-field OCR confidence scores (0.0–1.0). Fields below 0.55 show a warning icon.
  final Map<String, double> fieldConfidences;

  const _ExtractedDataCard({
    required this.title,
    required this.subtitle,
    required this.fields,
    required this.primaryLabel,
    required this.primaryEnabled,
    required this.onPrimaryTap,
    required this.statusColor,
    this.highlightedValue,
    this.onFieldChanged,
    this.fieldConfidences = const {},
  });

  @override
  State<_ExtractedDataCard> createState() => _ExtractedDataCardState();
}

class _ExtractedDataCardState extends State<_ExtractedDataCard> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void didUpdateWidget(_ExtractedDataCard old) {
    super.didUpdateWidget(old);
    // Sync controllers with new field values when the map changes externally
    for (final entry in widget.fields.entries) {
      final ctrl = _controllers[entry.key];
      if (ctrl == null) {
        _controllers[entry.key] =
            TextEditingController(text: entry.value.toString());
      } else if (ctrl.text != entry.value.toString()) {
        ctrl.text = entry.value.toString();
      }
    }
    // Remove controllers for keys no longer present
    _controllers.removeWhere((k, _) => !widget.fields.containsKey(k));
  }

  @override
  void dispose() {
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  bool _isLowConf(String key) =>
      (widget.fieldConfidences[key] ?? 1.0) < 0.55;

  TextEditingController _controllerFor(String key, String value) {
    return _controllers.putIfAbsent(
      key,
      () => TextEditingController(text: value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = widget.onFieldChanged != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: widget.statusColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: widget.statusColor,
                      ),
                ),
              ),
              if (canEdit)
                Tooltip(
                  message: AppLocalizations.of(context)!.cinTapToCorrect,
                  child: Icon(Icons.edit_note_rounded,
                      size: 18, color: widget.statusColor),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            canEdit
                ? '${widget.subtitle} ${AppLocalizations.of(context)!.cinTapToCorrect}'
                : widget.subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          if (widget.highlightedValue != null &&
              widget.highlightedValue!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.cinDetectedLabel,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              widget.highlightedValue!,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
            ),
          ],
          if (widget.fields.isNotEmpty) ...[
            const SizedBox(height: 16),
            // In read-only mode skip fields that have no value yet.
            ...widget.fields.entries
                .where((e) => canEdit || e.value.toString().trim().isNotEmpty)
                .map((entry) {
              final label = _localizedFieldLabel(entry.key, AppLocalizations.of(context)!);
              final value = entry.value.toString();

              if (canEdit) {
                final ctrl = _controllerFor(entry.key, value);
                final lowConf = _isLowConf(entry.key);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextFormField(
                    controller: ctrl,
                    decoration: InputDecoration(
                      labelText: label,
                      labelStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      suffixIcon: lowConf
                          ? Tooltip(
                              message: 'Low OCR confidence — verify before confirming',
                              child: const Icon(Icons.warning_amber_rounded,
                                  color: Colors.orange, size: 18),
                            )
                          : null,
                    ),
                    style: const TextStyle(fontSize: 14),
                    onChanged: (v) =>
                        widget.onFieldChanged!(entry.key, v),
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(label,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Text(value),
                    ),
                    if (_isLowConf(entry.key))
                      const Tooltip(
                        message: 'Low OCR confidence — verify before confirming',
                        child: Icon(Icons.warning_amber_rounded,
                            color: Colors.orange, size: 16),
                      ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 16),
          CustomButton(
            text: widget.primaryLabel,
            onPressed: widget.primaryEnabled ? widget.onPrimaryTap : null,
            backgroundColor: widget.statusColor,
          ),
        ],
      ),
    );
  }
}

String _localizedFieldLabel(String key, AppLocalizations l10n) {
  switch (key) {
    case 'identityNumber': return l10n.fieldIdentityNumber;
    case 'lastName':       return l10n.fieldLastName;
    case 'firstName':      return l10n.fieldFirstName;
    case 'fullName':       return l10n.fieldFullName;
    case 'dateOfBirth':    return l10n.fieldDateOfBirth;
    case 'placeOfBirth':   return l10n.fieldPlaceOfBirth;
    case 'lineage':        return l10n.fieldLineage;
    case 'gender':         return l10n.fieldGender;
    case 'expiryDate':     return l10n.fieldExpiryDate;
    case 'nationality':    return l10n.fieldNationality;
    case 'address':        return l10n.fieldAddress;
    case 'issueDate':      return l10n.fieldIssueDate;
    case 'issuePlace':     return l10n.fieldIssuePlace;
    default:
      // Fallback: camelCase → Title Case
      final spaced = key.replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (m) => '${m.group(1)} ${m.group(2)}',
      );
      return spaced.isEmpty ? key : spaced[0].toUpperCase() + spaced.substring(1);
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
