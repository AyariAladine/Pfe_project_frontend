import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/language_provider.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return PopupMenuButton<String>(
          icon: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.language_rounded,
                  size: 20,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  _getLanguageCode(languageProvider.currentLocale.languageCode),
                  style: TextStyle(
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          onSelected: (String languageCode) {
            languageProvider.setLanguage(languageCode);
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: isDark ? AppColors.cardBackgroundDark : AppColors.surface,
          itemBuilder: (BuildContext context) {
            final l10n = AppLocalizations.of(context)!;
            final primaryColor = isDark ? AppColors.primaryAccent : AppColors.primary;
            
            return [
              PopupMenuItem<String>(
                value: 'ar',
                child: Row(
                  children: [
                    if (languageProvider.isArabic)
                      Icon(Icons.check, color: primaryColor, size: 20)
                    else
                      const SizedBox(width: 20),
                    const SizedBox(width: 12),
                    Text(l10n.arabic),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'en',
                child: Row(
                  children: [
                    if (languageProvider.isEnglish)
                      Icon(Icons.check, color: primaryColor, size: 20)
                    else
                      const SizedBox(width: 20),
                    const SizedBox(width: 12),
                    Text(l10n.english),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'fr',
                child: Row(
                  children: [
                    if (languageProvider.isFrench)
                      Icon(Icons.check, color: primaryColor, size: 20)
                    else
                      const SizedBox(width: 20),
                    const SizedBox(width: 12),
                    Text(l10n.french),
                  ],
                ),
              ),
            ];
          },
        );
      },
    );
  }

  String _getLanguageCode(String code) {
    switch (code) {
      case 'ar':
        return 'AR';
      case 'en':
        return 'EN';
      case 'fr':
        return 'FR';
      default:
        return code.toUpperCase();
    }
  }
}
