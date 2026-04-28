import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'services/favorites_service.dart';
import 'services/language_provider.dart';
import 'viewmodels/auth/auth_viewmodel.dart';
import 'viewmodels/lawyer/lawyer_list_viewmodel.dart';
import 'viewmodels/lawyer/lawyer_profile_viewmodel.dart';
import 'viewmodels/user/user_profile_viewmodel.dart';
import 'views/splash/splash_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Disable Google Fonts runtime fetching on web to prevent CanvasKit assertion errors
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) {
          final service = FavoritesService();
          service.loadFavorites().catchError((_) {});
          return service;
        }),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => LawyerListViewModel()),
        ChangeNotifierProvider(create: (_) => LawyerProfileViewModel()),
        ChangeNotifierProvider(create: (_) => UserProfileViewModel()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, _) {
          return MaterialApp(
            title: 'عقاري - Aqari',
            debugShowCheckedModeBanner: false,

            // Theme — light only
            theme: AppTheme.lightTheme,
            themeMode: ThemeMode.light,

            // Localization
            locale: languageProvider.currentLocale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,

            // RTL Support
            builder: (context, child) {
              return Directionality(
                textDirection: languageProvider.currentLocale.languageCode == 'ar'
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: child!,
              );
            },

            // Home - Start with splash screen to check auth status
            home: const SplashView(),
          );
        },
      ),
    );
  }
}

