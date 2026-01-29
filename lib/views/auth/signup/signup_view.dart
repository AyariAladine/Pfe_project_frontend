import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/validators.dart';
import '../../../models/user_model.dart';
import '../../../viewmodels/auth/auth_viewmodel.dart';
import '../../../viewmodels/auth/signup_viewmodel.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/language_selector.dart';
import '../../widgets/user_type_card.dart';
import '../../onboarding/onboarding_view.dart';
import '../../home/home_view.dart';

class SignupView extends StatelessWidget {
  const SignupView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SignupViewModel(),
      child: const _SignupViewContent(),
    );
  }
}

class _SignupViewContent extends StatelessWidget {
  const _SignupViewContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<SignupViewModel>(
      builder: (context, signupVM, _) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: AppColors.textPrimary,
              ),
              onPressed: () {
                if (signupVM.currentStep > 0) {
                  signupVM.previousStep();
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
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              // Background decorative elements
              _buildBackgroundDecorations(context, isDark),
              
              // Main content
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWideScreen = constraints.maxWidth > 600;
                    final maxContentWidth = isWideScreen
                        ? 500.0
                        : constraints.maxWidth;

                    return SingleChildScrollView(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxContentWidth),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 10),

                                // Progress Indicator
                                _buildProgressIndicator(context, signupVM),

                                const SizedBox(height: 30),

                                // Header
                                _buildHeader(context, l10n, signupVM),

                                const SizedBox(height: 30),

                                // Step Content
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: signupVM.currentStep == 0
                                      ? _buildStep1Content(context, l10n, signupVM)
                                      : _buildStep2Content(context, l10n, signupVM),
                                ),

                                const SizedBox(height: 20),
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
                      AppColors.primaryAccent,
                      AppColors.primary,
                    ],
                  ),
                ),
              ),
            ),
            // Decorative ring top-left
            Positioned(
              top: -50,
              left: -50,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.07),
                    width: 25,
                  ),
                ),
              ),
            ),
            // Decorative ring bottom-right
            Positioned(
              bottom: -80,
              right: -80,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryAccent.withValues(alpha: 0.05),
                    width: 35,
                  ),
                ),
              ),
            ),
            // Small accent dots
            Positioned(
              top: 100,
              right: 25,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(
    BuildContext context,
    SignupViewModel signupVM,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark
        ? AppColors.borderDark.withValues(alpha: 0.5)
        : AppColors.border;
    final activeGradient = isDark 
        ? [AppColors.gradientStart, AppColors.gradientEnd]
        : [AppColors.primary, AppColors.primaryLight];
    final shadowColor = isDark 
        ? AppColors.gradientStart.withValues(alpha: 0.4)
        : AppColors.primary.withValues(alpha: 0.3);

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: activeGradient,
              ),
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 5,
            decoration: BoxDecoration(
              gradient: signupVM.currentStep >= 1
                  ? LinearGradient(
                      colors: activeGradient,
                    )
                  : null,
              color: signupVM.currentStep >= 1 ? null : inactiveColor,
              borderRadius: BorderRadius.circular(3),
              boxShadow: signupVM.currentStep >= 1
                  ? [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations l10n,
    SignupViewModel signupVM,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Logo container
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            signupVM.currentStep == 0
                ? Icons.person_add_rounded
                : Icons.app_registration_rounded,
            size: 45,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          signupVM.currentStep == 0
              ? l10n.selectAccountType
              : l10n.createAccount,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          signupVM.currentStep == 0
              ? l10n.selectAccountTypeSubtitle
              : l10n.fillYourDetails,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStep1Content(
    BuildContext context,
    AppLocalizations l10n,
    SignupViewModel signupVM,
  ) {
    return Column(
      key: const ValueKey('step1'),
      children: [
        // User Type Selection
        UserTypeCard(
          userType: UserRole.landlord,
          title: l10n.landlord,
          subtitle: l10n.landlordDesc,
          icon: Icons.apartment_rounded,
          isSelected: signupVM.selectedUserRole == UserRole.landlord,
          onTap: () => signupVM.setUserRole(UserRole.landlord),
        ),
        const SizedBox(height: 16),
        UserTypeCard(
          userType: UserRole.tenant,
          title: l10n.tenant,
          subtitle: l10n.tenantDesc,
          icon: Icons.person_rounded,
          isSelected: signupVM.selectedUserRole == UserRole.tenant,
          onTap: () => signupVM.setUserRole(UserRole.tenant),
        ),
        const SizedBox(height: 16),
        UserTypeCard(
          userType: UserRole.lawyer,
          title: l10n.lawyer,
          subtitle: l10n.lawyerDesc,
          icon: Icons.gavel_rounded,
          isSelected: signupVM.selectedUserRole == UserRole.lawyer,
          onTap: () => signupVM.setUserRole(UserRole.lawyer),
        ),

        const SizedBox(height: 40),

        // Continue Button
        CustomButton(
          text: l10n.continueText,
          onPressed: signupVM.canProceedFromStep1()
              ? () {
                  signupVM.nextStep();
                  // Also set user role in auth viewmodel
                  context.read<AuthViewModel>().setUserRole(
                    signupVM.selectedUserRole!,
                  );
                }
              : null,
        ),

        const SizedBox(height: 20),

        // OR Divider
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: AppColors.border,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.translate('or'),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: AppColors.border,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Google Sign-Up Button
        _GoogleSignUpButton(
          isLoading: signupVM.isGoogleLoading,
          onPressed: () async {
            try {
              final result = await signupVM.signUpWithGoogle();
              
              if (!context.mounted) return;
              
              if (result.success) {
                // User logged in successfully (existing user or new user with role already selected)
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeView()),
                  (route) => false,
                );
              } else if (result.needsRole) {
                // New user - show role selection dialog
                final selectedRole = await _showRoleSelectionDialog(context, l10n);
                if (selectedRole != null && context.mounted) {
                  try {
                    final completeResult = await signupVM.completeGoogleSignUp(selectedRole);
                    if (completeResult.success && context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeView()),
                        (route) => false,
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ErrorHandler.getLocalizedError(context, e.toString())),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                } else {
                  // User cancelled role selection
                  signupVM.clearPendingGoogleSignUp();
                }
              }
              // If cancelled, do nothing
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.translate('googleSignInFailed')),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          },
        ),

        const SizedBox(height: 30),

        // Login Link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.alreadyHaveAccount,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.primaryAccent
                    : AppColors.primary,
              ),
              child: Text(
                l10n.login,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2Content(
    BuildContext context,
    AppLocalizations l10n,
    SignupViewModel signupVM,
  ) {
    return Consumer<AuthViewModel>(
      builder: (context, authVM, _) {
        return Form(
          key: signupVM.formKey,
          child: Column(
            key: const ValueKey('step2'),
            children: [
              // First Name
              CustomTextField(
                controller: signupVM.nameController,
                hintText: l10n.firstName,
                prefixIcon: Icons.person_outline,
                validator: (value) => Validators.validateName(value, context),
              ),

              const SizedBox(height: 16),

              // Last Name
              CustomTextField(
                controller: signupVM.lastNameController,
                hintText: l10n.lastName,
                prefixIcon: Icons.person_outline,
                validator: (value) => Validators.validateName(value, context),
              ),

              const SizedBox(height: 16),

              // Email
              CustomTextField(
                controller: signupVM.emailController,
                hintText: l10n.email,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) => Validators.validateEmail(value, context),
              ),

              const SizedBox(height: 16),

              // Phone
              CustomTextField(
                controller: signupVM.phoneController,
                hintText: l10n.phoneNumber,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) => Validators.validatePhone(value, context),
              ),

              const SizedBox(height: 16),

              // Password
              CustomTextField(
                controller: signupVM.passwordController,
                hintText: l10n.password,
                prefixIcon: Icons.lock_outline,
                obscureText: signupVM.obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    signupVM.obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                  onPressed: signupVM.togglePasswordVisibility,
                ),
                validator: (value) =>
                    Validators.validatePassword(value, context),
              ),

              const SizedBox(height: 16),

              // Confirm Password
              CustomTextField(
                controller: signupVM.confirmPasswordController,
                hintText: l10n.confirmPassword,
                prefixIcon: Icons.lock_outline,
                obscureText: signupVM.obscureConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    signupVM.obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                  onPressed: signupVM.toggleConfirmPasswordVisibility,
                ),
                validator: (value) => Validators.validateConfirmPassword(
                  value,
                  signupVM.password,
                  context,
                ),
              ),

              const SizedBox(height: 20),

              // Terms and Conditions
              Builder(
                builder: (context) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  final linkColor = isDark ? AppColors.primaryAccent : AppColors.primary;
                  
                  return Row(
                    children: [
                      Checkbox(
                        value: signupVM.agreeToTerms,
                        onChanged: (_) => signupVM.toggleAgreeToTerms(),
                        activeColor: linkColor,
                      ),
                      Expanded(
                        child: Wrap(
                          children: [
                            Text(
                              l10n.agreeToTerms,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                // TODO: Show terms of service
                              },
                              child: Text(
                                l10n.termsOfService,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: linkColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            Text(
                              ' ${l10n.and} ',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            GestureDetector(
                              onTap: () {
                                // TODO: Show privacy policy
                              },
                              child: Text(
                                l10n.privacyPolicy,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: linkColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Error Message
              if (authVM.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ErrorHandler.getLocalizedError(
                            context,
                            authVM.errorMessage!,
                          ),
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Sign Up Button
              CustomButton(
                text: l10n.signUp,
                isLoading: authVM.isLoading,
                onPressed: signupVM.agreeToTerms
                    ? () async {
                        if (signupVM.validateForm()) {
                          final success = await authVM.signUp(
                            name: signupVM.name,
                            lastName: signupVM.lastName,
                            email: signupVM.email,
                            password: signupVM.password,
                            phoneNumber: signupVM.phone,
                          );
                          if (success && context.mounted) {
                            // Redirect to onboarding for identity verification
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const OnboardingView(),
                              ),
                              (route) => false,
                            );
                          }
                        }
                      }
                    : null,
              ),

              const SizedBox(height: 24),

              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.alreadyHaveAccount,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.primaryAccent
                          : AppColors.primary,
                    ),
                    child: Text(
                      l10n.login,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Google Sign-Up Button Widget
class _GoogleSignUpButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _GoogleSignUpButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Colors.white,
      ),
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Google Logo
                Image.asset(
                  'assets/icons/google_logo.png',
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    l10n.translate('continueWithGoogle'),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );
  }
}

/// Show role selection dialog for new Google users
Future<UserRole?> _showRoleSelectionDialog(BuildContext context, AppLocalizations l10n) async {
  return showDialog<UserRole>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          l10n.translate('selectYourRole'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.translate('selectRoleDescription'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            _RoleSelectionTile(
              role: UserRole.landlord,
              icon: Icons.home_work_outlined,
              title: l10n.translate('landlord'),
              description: l10n.translate('landlordDescription'),
              onTap: () => Navigator.of(context).pop(UserRole.landlord),
            ),
            const SizedBox(height: 12),
            _RoleSelectionTile(
              role: UserRole.tenant,
              icon: Icons.person_outline,
              title: l10n.translate('tenant'),
              description: l10n.translate('tenantDescription'),
              onTap: () => Navigator.of(context).pop(UserRole.tenant),
            ),
            const SizedBox(height: 12),
            _RoleSelectionTile(
              role: UserRole.lawyer,
              icon: Icons.gavel_outlined,
              title: l10n.translate('lawyer'),
              description: l10n.translate('lawyerDescription'),
              onTap: () => Navigator.of(context).pop(UserRole.lawyer),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text(
              l10n.translate('cancel'),
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      );
    },
  );
}

/// Role selection tile widget
class _RoleSelectionTile extends StatelessWidget {
  final UserRole role;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _RoleSelectionTile({
    required this.role,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
