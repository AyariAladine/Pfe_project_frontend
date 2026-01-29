import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/validators.dart';
import '../../../viewmodels/auth/auth_viewmodel.dart';
import '../../../viewmodels/auth/forgot_password_viewmodel.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/language_selector.dart';

class ForgotPasswordView extends StatelessWidget {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ForgotPasswordViewModel(),
      child: const _ForgotPasswordViewContent(),
    );
  }
}

class _ForgotPasswordViewContent extends StatelessWidget {
  const _ForgotPasswordViewContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<ForgotPasswordViewModel>(
      builder: (context, forgotPasswordVM, _) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: AppColors.textPrimary,
              ),
              onPressed: () {
                if (forgotPasswordVM.currentStep !=
                    ForgotPasswordStep.enterEmail) {
                  forgotPasswordVM.previousStep();
                } else {
                  Navigator.pop(context);
                }
              },
            ),
            actions: const [
              Padding(
                padding: EdgeInsets.only(left: 16, right: 16),
                child: LanguageSelector(),
              ),
            ],
          ),
          body: Stack(
            children: [
              // Background decorative elements
              _buildBackgroundDecorations(context, isDark),
              
              // Main content
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWideScreen = constraints.maxWidth > 600;
                    final maxContentWidth = isWideScreen ? 450.0 : constraints.maxWidth;

                    return Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxContentWidth),
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 20),

                                // Progress Indicator
                                _buildProgressIndicator(context, forgotPasswordVM),

                                const SizedBox(height: 40),

                                // Icon
                                _buildIcon(context, forgotPasswordVM),

                                const SizedBox(height: 30),

                                // Title & Subtitle
                                _buildHeader(context, l10n, forgotPasswordVM),

                                const SizedBox(height: 40),

                                // Content based on step
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: _buildStepContent(context, l10n, forgotPasswordVM),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackgroundDecorations(BuildContext context, bool isDark) {
    return Positioned.fill(
      child: Container(
        color: AppColors.background,
        child: Stack(
          children: [
            // Subtle top accent bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 4,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primaryAccent,
                    ],
                  ),
                ),
              ),
            ),
            // Decorative ring top-right
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    width: 20,
                  ),
                ),
              ),
            ),
            // Decorative ring bottom-left
            Positioned(
              bottom: -70,
              left: -70,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryAccent.withValues(alpha: 0.06),
                    width: 30,
                  ),
                ),
              ),
            ),
            // Small accent dot
            Positioned(
              top: 150,
              left: 40,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
      
  }

  Widget _buildProgressIndicator(
    BuildContext context,
    ForgotPasswordViewModel vm,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.primaryAccent : AppColors.primary;
    final inactiveColor = isDark ? AppColors.borderDark : AppColors.border;
    final step = vm.currentStep;
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: activeColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color:
                  step == ForgotPasswordStep.enterCode ||
                      step == ForgotPasswordStep.enterNewPassword
                  ? activeColor
                  : inactiveColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: step == ForgotPasswordStep.enterNewPassword
                  ? activeColor
                  : inactiveColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIcon(BuildContext context, ForgotPasswordViewModel vm) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    IconData icon;
    Color color;

    switch (vm.currentStep) {
      case ForgotPasswordStep.enterEmail:
        icon = Icons.email_outlined;
        color = isDark ? AppColors.primaryAccent : AppColors.primary;
        break;
      case ForgotPasswordStep.enterCode:
        icon = Icons.pin_outlined;
        color = isDark ? AppColors.primaryAccent : AppColors.primary;
        break;
      case ForgotPasswordStep.enterNewPassword:
        icon = Icons.lock_reset_outlined;
        color = AppColors.success;
        break;
    }

    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 100),
      decoration: BoxDecoration(
        color: color == AppColors.success ? color.withValues(alpha: 0.1) : color,
        shape: BoxShape.circle,
        boxShadow: color != AppColors.success
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Icon(icon, size: 50, color: color == AppColors.success ? color : Colors.white),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations l10n,
    ForgotPasswordViewModel vm,
  ) {
    String title;
    String subtitle;

    switch (vm.currentStep) {
      case ForgotPasswordStep.enterEmail:
        title = l10n.resetPassword;
        subtitle = l10n.enterEmailToReset;
        break;
      case ForgotPasswordStep.enterCode:
        title = l10n.enterVerificationCode;
        subtitle = l10n.verificationCodeSent;
        break;
      case ForgotPasswordStep.enterNewPassword:
        title = l10n.newPassword;
        subtitle = l10n.enterNewPassword;
        break;
    }

    return Column(
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStepContent(
    BuildContext context,
    AppLocalizations l10n,
    ForgotPasswordViewModel vm,
  ) {
    switch (vm.currentStep) {
      case ForgotPasswordStep.enterEmail:
        return _buildEmailStep(context, l10n, vm);
      case ForgotPasswordStep.enterCode:
        return _buildCodeStep(context, l10n, vm);
      case ForgotPasswordStep.enterNewPassword:
        return _buildNewPasswordStep(context, l10n, vm);
    }
  }

  Widget _buildEmailStep(
    BuildContext context,
    AppLocalizations l10n,
    ForgotPasswordViewModel vm,
  ) {
    return Consumer<AuthViewModel>(
      builder: (context, authVM, _) {
        return Form(
          key: vm.formKey,
          child: Column(
            key: const ValueKey('email_step'),
            children: [
              CustomTextField(
                controller: vm.emailController,
                hintText: l10n.email,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) => Validators.validateEmail(value, context),
              ),

              const SizedBox(height: 24),

              if (authVM.errorMessage != null) ...[
                _buildErrorMessage(context, authVM.errorMessage!),
                const SizedBox(height: 16),
              ],

              CustomButton(
                text: l10n.sendVerificationCode,
                isLoading: authVM.isLoading,
                onPressed: () async {
                  if (vm.validateForm()) {
                    final success = await authVM.forgotPassword(vm.email);
                    if (success) {
                      vm.nextStep();
                    }
                  }
                },
              ),

              const SizedBox(height: 24),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.arrow_back, size: 18),
                    const SizedBox(width: 8),
                    Text(l10n.backToLogin),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCodeStep(
    BuildContext context,
    AppLocalizations l10n,
    ForgotPasswordViewModel vm,
  ) {
    return Consumer<AuthViewModel>(
      builder: (context, authVM, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final accentColor = isDark ? AppColors.primaryAccent : AppColors.primary;
        
        return Column(
          key: const ValueKey('code_step'),
          children: [
            // Show email
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.email, color: accentColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    vm.email,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Code input
            CustomTextField(
              controller: vm.codeController,
              hintText: l10n.verificationCode,
              prefixIcon: Icons.pin_outlined,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.enterCode;
                }
                if (value.length != 6) {
                  return l10n.codeLength;
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            if (authVM.errorMessage != null) ...[
              _buildErrorMessage(context, authVM.errorMessage!),
              const SizedBox(height: 16),
            ],

            CustomButton(
              text: l10n.next,
              onPressed: () {
                if (vm.code.length == 6) {
                  authVM.clearError();
                  vm.nextStep();
                }
              },
            ),

            const SizedBox(height: 16),

            // Resend code
            TextButton(
              onPressed: authVM.isLoading
                  ? null
                  : () async {
                      await authVM.forgotPassword(vm.email);
                    },
              child: Text(
                l10n.resendCode,
                style: TextStyle(
                  color: authVM.isLoading
                      ? AppColors.textSecondary
                      : accentColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNewPasswordStep(
    BuildContext context,
    AppLocalizations l10n,
    ForgotPasswordViewModel vm,
  ) {
    return Consumer<AuthViewModel>(
      builder: (context, authVM, _) {
        return Form(
          key: vm.formKey,
          child: Column(
            key: const ValueKey('password_step'),
            children: [
              CustomTextField(
                controller: vm.newPasswordController,
                hintText: l10n.password,
                prefixIcon: Icons.lock_outline,
                obscureText: vm.obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    vm.obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: vm.togglePasswordVisibility,
                ),
                validator: (value) =>
                    Validators.validatePassword(value, context),
              ),

              const SizedBox(height: 16),

              CustomTextField(
                controller: vm.confirmPasswordController,
                hintText: l10n.confirmPassword,
                prefixIcon: Icons.lock_outline,
                obscureText: vm.obscureConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    vm.obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: vm.toggleConfirmPasswordVisibility,
                ),
                validator: (value) => Validators.validateConfirmPassword(
                  value,
                  vm.newPassword,
                  context,
                ),
              ),

              const SizedBox(height: 24),

              if (authVM.errorMessage != null) ...[
                _buildErrorMessage(context, authVM.errorMessage!),
                const SizedBox(height: 16),
              ],

              CustomButton(
                text: l10n.changePassword,
                isLoading: authVM.isLoading,
                onPressed: () async {
                  if (vm.validateForm()) {
                    final success = await authVM.resetPassword(
                      code: vm.code,
                      newPassword: vm.newPassword,
                    );
                    if (success && context.mounted) {
                      // Show success and navigate back to login
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.passwordChanged),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      Navigator.pop(context);
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorMessage(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

