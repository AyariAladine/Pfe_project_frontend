import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:pfe_project/l10n/app_localizations.dart';

void main() {
  testWidgets('English localization renders app branding', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: _LocalizationProbe(),
      ),
    );

    await tester.pump();

    expect(find.text('Aqari'), findsOneWidget);
  });
}

class _LocalizationProbe extends StatelessWidget {
  const _LocalizationProbe();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: Text(l10n.appName),
      ),
    );
  }
}
