import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'core/localization/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'services/language_provider.dart';
import 'services/theme_provider.dart';
import 'viewmodels/auth/auth_viewmodel.dart';
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
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
      ],
      child: Consumer2<LanguageProvider, ThemeProvider>(
        builder: (context, languageProvider, themeProvider, _) {
          return MaterialApp(
            title: 'عقاري - Aqari',
            debugShowCheckedModeBanner: false,
            
            // Theme - Light mode only
            theme: AppTheme.lightTheme,
            themeMode: ThemeMode.light,
            
            // Localization
            locale: languageProvider.currentLocale,
            supportedLocales: const [
              Locale('ar'), // Arabic
              Locale('en'), // English
              Locale('fr'), // French
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            
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
