import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/theme_provider.dart';

class ThemeToggle extends StatelessWidget {
  final bool showLabel;

  const ThemeToggle({super.key, this.showLabel = false});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return GestureDetector(
          onTap: () => themeProvider.toggleTheme(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark 
                  ? AppColors.cardBackgroundDark
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark 
                    ? AppColors.borderDark
                    : AppColors.border,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return RotationTransition(
                    turns: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  );
                },
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  key: ValueKey(isDark),
                  size: 22,
                  color: isDark ? AppColors.accent : AppColors.accent,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return PopupMenuButton<ThemeMode>(
          icon: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
              ),
            ),
            child: Icon(
              _getThemeIcon(themeProvider.themeMode, isDark),
              size: 20,
              color: isDark ? AppColors.accentLight : AppColors.accent,
            ),
          ),
          onSelected: (ThemeMode mode) {
            themeProvider.setThemeMode(mode);
          },
          itemBuilder: (BuildContext context) {
            final accentColor = isDark ? AppColors.primaryAccent : AppColors.primary;
            return [
              PopupMenuItem<ThemeMode>(
                value: ThemeMode.light,
                child: Row(
                  children: [
                    Icon(
                      Icons.light_mode_rounded,
                      color: themeProvider.isLightMode
                          ? accentColor
                          : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.light,
                      style: TextStyle(
                        fontWeight: themeProvider.isLightMode
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (themeProvider.isLightMode) ...[
                      const Spacer(),
                      Icon(
                        Icons.check,
                        color: accentColor,
                        size: 18,
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuItem<ThemeMode>(
                value: ThemeMode.dark,
                child: Row(
                  children: [
                    Icon(
                      Icons.dark_mode_rounded,
                      color: themeProvider.isDarkMode
                          ? accentColor
                          : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.dark,
                      style: TextStyle(
                        fontWeight: themeProvider.isDarkMode
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (themeProvider.isDarkMode) ...[
                      const Spacer(),
                      Icon(
                        Icons.check,
                        color: accentColor,
                        size: 18,
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuItem<ThemeMode>(
                value: ThemeMode.system,
                child: Row(
                  children: [
                    Icon(
                      Icons.settings_brightness_rounded,
                      color: themeProvider.isSystemMode
                          ? accentColor
                          : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.auto,
                      style: TextStyle(
                        fontWeight: themeProvider.isSystemMode
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (themeProvider.isSystemMode) ...[
                      const Spacer(),
                      Icon(
                        Icons.check,
                        color: accentColor,
                        size: 18,
                      ),
                    ],
                  ],
                ),
              ),
            ];
          },
        );
      },
    );
  }

  IconData _getThemeIcon(ThemeMode mode, bool isDark) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode_rounded;
      case ThemeMode.dark:
        return Icons.dark_mode_rounded;
      case ThemeMode.system:
        return Icons.settings_brightness_rounded;
    }
  }
}
