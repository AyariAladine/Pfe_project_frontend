import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/token_service.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../auth/login/login_view.dart';
import '../home/main_shell.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  bool _needsBiometric = false;
  bool _biometricFailed = false;

  // Logo entrance
  late final AnimationController _logoCtrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  // Pulse ring
  late final AnimationController _ringCtrl;
  late final Animation<double> _ringScale;
  late final Animation<double> _ringOpacity;

  // Text entrance
  late final AnimationController _textCtrl;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;

  // Bottom content
  late final AnimationController _bottomCtrl;
  late final Animation<double> _bottomOpacity;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.5)),
    );

    _ringCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
    _ringScale = Tween<double>(begin: 1.0, end: 2.0).animate(
      CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut),
    );
    _ringOpacity = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut),
    );

    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic),
    );

    _bottomCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _bottomOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(_bottomCtrl);

    // Staggered sequence
    _logoCtrl.forward();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _textCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) _bottomCtrl.forward();
    });

    _checkAuth();
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _ringCtrl.dispose();
    _textCtrl.dispose();
    _bottomCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final authVM = context.read<AuthViewModel>();
    await authVM.initializeAuth();
    if (!mounted) return;

    if (authVM.isAuthenticated) {
      if (!kIsWeb) {
        final userId = await TokenService.getUserId();
        final prefs = await SharedPreferences.getInstance();
        final biometricsEnabled = userId != null
            ? (prefs.getBool('biometrics_enabled_$userId') ?? false)
            : false;
        if (biometricsEnabled) {
          setState(() => _needsBiometric = true);
          await _authenticateWithBiometrics();
          return;
        }
      }
      _goToMain();
    } else {
      _goToLogin();
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    final localAuth = LocalAuthentication();
    try {
      final canCheck = await localAuth.canCheckBiometrics;
      if (!canCheck) {
        _goToMain();
        return;
      }
      final authenticated = await localAuth.authenticate(
        localizedReason: 'Unlock Aqari',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: false),
      );
      if (!mounted) return;
      if (authenticated) {
        _goToMain();
      } else {
        setState(() => _biometricFailed = true);
      }
    } on PlatformException {
      if (!mounted) return;
      _goToMain();
    }
  }

  void _goToMain() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryDark,
              AppColors.primary,
              Color(0xFF1A3F6F),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Subtle background pattern
              Positioned.fill(child: CustomPaint(painter: _SplashPatternPainter())),

              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Logo + ring ──
                    AnimatedBuilder(
                      animation: Listenable.merge([_ringCtrl, _logoCtrl]),
                      builder: (_, _) {
                        return SizedBox(
                          width: 160,
                          height: 160,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer pulse ring
                              Transform.scale(
                                scale: _ringScale.value,
                                child: Opacity(
                                  opacity: _ringOpacity.value,
                                  child: Container(
                                    width: 110,
                                    height: 110,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.gold,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Logo container
                              Transform.scale(
                                scale: _logoScale.value,
                                child: Opacity(
                                  opacity: _logoOpacity.value,
                                  child: Container(
                                    width: 108,
                                    height: 108,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [AppColors.gold, AppColors.goldDark],
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.gold.withValues(alpha: 0.45),
                                          blurRadius: 32,
                                          offset: const Offset(0, 10),
                                          spreadRadius: -4,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _needsBiometric
                                          ? Icons.fingerprint_rounded
                                          : Icons.balance_rounded,
                                      size: 52,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 36),

                    // ── Brand text ──
                    FadeTransition(
                      opacity: _textOpacity,
                      child: SlideTransition(
                        position: _textSlide,
                        child: Column(
                          children: [
                            const Text(
                              'عقاري',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                                color: AppColors.gold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'A Q A R I',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.55),
                                letterSpacing: 9,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            const SizedBox(height: 14),
                            // Decorative divider
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 28,
                                  height: 1,
                                  color: AppColors.gold.withValues(alpha: 0.35),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.gold,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  width: 28,
                                  height: 1,
                                  color: AppColors.gold.withValues(alpha: 0.35),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Real Estate Solutions',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.45),
                                letterSpacing: 2.5,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 64),

                    // ── Bottom: loading / biometric ──
                    FadeTransition(
                      opacity: _bottomOpacity,
                      child: _biometricFailed
                          ? _buildBiometricRetry(l10n)
                          : _buildLoadingDots(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingDots() {
    return AnimatedBuilder(
      animation: _ringCtrl,
      builder: (_, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_ringCtrl.value - i * 0.2).clamp(0.0, 1.0);
            final opacity = (phase < 0.5 ? phase * 2 : (1.0 - phase) * 2).clamp(0.3, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildBiometricRetry(AppLocalizations? l10n) {
    return Column(
      children: [
        Text(
          l10n?.unlockToAccess ?? 'Please unlock to access the app',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 15,
            fontFamily: 'Cairo',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () {
            setState(() => _biometricFailed = false);
            _authenticateWithBiometrics();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.gold, AppColors.goldDark],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.fingerprint_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  l10n?.unlockApp ?? 'Unlock',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Subtle dot pattern on splash background
class _SplashPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..style = PaintingStyle.fill;
    const spacing = 28.0;
    const radius = 1.8;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
