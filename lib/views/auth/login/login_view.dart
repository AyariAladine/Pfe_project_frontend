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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 900;

          if (isWideScreen) {
            return _buildWideLayout(context, l10n);
          }
          return _buildNarrowLayout(context, l10n);
        },
      ),
    );
  }

  // Two-column web layout
  Widget _buildWideLayout(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        // Left brand panel
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryDark, AppColors.primary, Color(0xFF264D7A)],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _LoginPatternPainter())),
                SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.gold, AppColors.goldDark],
                              ),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.gold.withValues(alpha: 0.4),
                                  blurRadius: 32,
                                  offset: const Offset(0, 12),
                                  spreadRadius: -4,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.balance_rounded, size: 48, color: Colors.white),
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'عقاري',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 52,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'A Q A R I',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.5),
                              letterSpacing: 10,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 32, height: 1, color: AppColors.gold.withValues(alpha: 0.4)),
                              const SizedBox(width: 10),
                              Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.gold)),
                              const SizedBox(width: 10),
                              Container(width: 32, height: 1, color: AppColors.gold.withValues(alpha: 0.4)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Real Estate & Legal Solutions',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.5),
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 48),
                          // Feature points
                          ...[
                            ('balance_rounded', 'Legal document management'),
                            ('home_work_rounded', 'Property listings & search'),
                            ('verified_user_rounded', 'Identity verification'),
                          ].map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.gold.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                                    ),
                                    child: Icon(_iconFromString(item.$1), size: 18, color: AppColors.gold),
                                  ),
                                  const SizedBox(width: 14),
                                  Text(
                                    item.$2,
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      color: Colors.white.withValues(alpha: 0.75),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Right form panel
        Expanded(
          flex: 4,
          child: Container(
            color: AppColors.background,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [LanguageSelector()],
                    ),
                    const SizedBox(height: 32),
                    _buildHeader(context, l10n),
                    const SizedBox(height: 32),
                    _buildLoginForm(context, l10n),
                    const SizedBox(height: 24),
                    _buildSignUpLink(context, l10n),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _iconFromString(String name) {
    switch (name) {
      case 'balance_rounded': return Icons.balance_rounded;
      case 'home_work_rounded': return Icons.home_work_rounded;
      case 'verified_user_rounded': return Icons.verified_user_rounded;
      default: return Icons.check_circle_outline_rounded;
    }
  }

  // Single-column mobile layout
  Widget _buildNarrowLayout(BuildContext context, AppLocalizations l10n) {
    return Stack(
      children: [
        _buildBackgroundDecorations(context),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [LanguageSelector()],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        _buildHeader(context, l10n),
                        const SizedBox(height: 32),
                        _buildLoginForm(context, l10n),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                _buildSignUpLink(context, l10n),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundDecorations(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: AppColors.background,
        child: Stack(
          children: [
            // Top gradient accent bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 3,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.gold],
                  ),
                ),
              ),
            ),
            // Decorative ring top-right
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    width: 32,
                  ),
                ),
              ),
            ),
            // Decorative ring bottom-left
            Positioned(
              bottom: -70,
              left: -70,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.07),
                    width: 44,
                  ),
                ),
              ),
            ),
            // Gold accent dot
            Positioned(
              top: 130,
              left: 24,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold,
                ),
              ),
            ),
            Positioned(
              bottom: 210,
              right: 32,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryAccent.withValues(alpha: 0.3),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo + brand row
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.gold, AppColors.goldDark],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: const Icon(Icons.balance_rounded, size: 26, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'عقاري',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'AQARI',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    color: AppColors.textHint,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          l10n.welcomeBack,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.loginToAccount,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 15,
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
                      l10n.or,
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
                          content: Text(l10n.googleSignInFailed),
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
                    l10n.continueWithGoogle,
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
          l10n.selectYourRole,
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
              l10n.selectRoleDescription,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            _RoleSelectionTile(
              role: UserRole.user,
              icon: Icons.person_outline,
              title: l10n.user,
              description: l10n.userDescription,
              onTap: () => Navigator.of(context).pop(UserRole.user),
            ),
            const SizedBox(height: 12),
            _RoleSelectionTile(
              role: UserRole.lawyer,
              icon: Icons.gavel_outlined,
              title: l10n.lawyer,
              description: l10n.lawyerDescription,
              onTap: () => Navigator.of(context).pop(UserRole.lawyer),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text(
              l10n.cancel,
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

// Diagonal line pattern for the web branding panel
class _LoginPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const spacing = 32.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
