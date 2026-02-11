import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/validators.dart';
import '../../../models/user_model.dart';
import '../../../viewmodels/auth/auth_viewmodel.dart';
import '../../../viewmodels/auth/login_viewmodel.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/language_selector.dart';
import '../signup/signup_view.dart';
import '../forgot_password/forgot_password_view.dart';
import '../../home/main_shell.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late LoginViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = LoginViewModel();
    // Load saved email for auto-fill
    _viewModel.init();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: const _LoginViewContent(),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }
}

class _LoginViewContent extends StatelessWidget {
  const _LoginViewContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          // Background decorative elements
          _buildBackgroundDecorations(context),
          
          // Main content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWideScreen = constraints.maxWidth > 600;
                final maxContentWidth = isWideScreen ? 450.0 : constraints.maxWidth;

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),

                          // Language Selector
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [LanguageSelector()],
                          ),

                          // Expanded content area
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Logo and Welcome Text
                                _buildHeader(context, l10n),

                                const SizedBox(height: 32),

                                // Login Form
                                _buildLoginForm(context, l10n),
                              ],
                            ),
                          ),

                          // Sign Up Link at bottom
                          _buildSignUpLink(context, l10n),

                          const SizedBox(height: 16),
                        ],
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
  }

  Widget _buildBackgroundDecorations(BuildContext context) {
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
            // Decorative pattern top-right
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    width: 30,
                  ),
                ),
              ),
            ),
            // Decorative pattern bottom-left
            Positioned(
              bottom: -60,
              left: -60,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryAccent.withValues(alpha: 0.06),
                    width: 40,
                  ),
                ),
              ),
            ),
            // Small accent dot
            Positioned(
              top: 120,
              left: 30,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
            ),
            // Another small accent dot
            Positioned(
              bottom: 200,
              right: 40,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryAccent.withValues(alpha: 0.2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        // Logo Container with gradient shadow
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primaryAccent,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.home_work_rounded,
            size: 44,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          l10n.welcomeBack,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.loginToAccount,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(BuildContext context, AppLocalizations l10n) {
    return Consumer2<LoginViewModel, AuthViewModel>(
      builder: (context, loginVM, authVM, _) {
        return Form(
          key: loginVM.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Email Field
              CustomTextField(
                controller: loginVM.emailController,
                hintText: l10n.email,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) => Validators.validateEmail(value, context),
              ),

              const SizedBox(height: 16),

              // Password Field
              CustomTextField(
                controller: loginVM.passwordController,
                hintText: l10n.password,
                prefixIcon: Icons.lock_outline,
                obscureText: loginVM.obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    loginVM.obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: loginVM.togglePasswordVisibility,
                ),
                validator: (value) =>
                    Validators.validatePassword(value, context),
              ),

              const SizedBox(height: 12),

              // Forgot Password
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordView(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    l10n.forgotPassword,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Error Message
              if (authVM.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
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

              // Login Button
              CustomButton(
                text: l10n.login,
                isLoading: authVM.isLoading,
                onPressed: () async {
                  if (loginVM.validateForm()) {
                    final success = await authVM.signIn(
                      email: loginVM.email,
                      password: loginVM.password,
                    );
                    if (success && context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const MainShell()),
                        (route) => false,
                      );
                    }
                  }
                },
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

              // Google Sign-In Button
              _GoogleSignInButton(
                isLoading: loginVM.isGoogleLoading,
                onPressed: () async {
                  try {
                    final result = await loginVM.signInWithGoogle();
                    
                    if (!context.mounted) return;
                    
                    if (result.success) {
                      // User logged in successfully
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const MainShell()),
                        (route) => false,
                      );
                    } else if (result.needsRole) {
                      // New user - show role selection dialog
                      final selectedRole = await _showRoleSelectionDialog(context, l10n);
                      if (selectedRole != null && context.mounted) {
                        try {
                          final completeResult = await loginVM.completeGoogleSignUp(selectedRole);
                          if (completeResult.success && context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const MainShell()),
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
                        loginVM.clearPendingGoogleSignUp();
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildSignUpLink(BuildContext context, AppLocalizations l10n) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          l10n.dontHaveAccount,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SignupView()),
            );
          },
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
          ),
          child: Text(
            l10n.signUp,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

/// Google Sign-In Button Widget
class _GoogleSignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _GoogleSignInButton({
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
