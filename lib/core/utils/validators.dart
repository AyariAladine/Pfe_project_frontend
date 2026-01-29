import '../localization/app_localizations.dart';
import 'package:flutter/material.dart';

class Validators {
  static String? validateEmail(String? value, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (value == null || value.isEmpty) {
      return l10n.emailRequired;
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return l10n.invalidEmail;
    }
    
    return null;
  }

  static String? validatePassword(String? value, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (value == null || value.isEmpty) {
      return l10n.passwordRequired;
    }
    
    if (value.length < 6) {
      return l10n.passwordTooShort;
    }
    
    return null;
  }

  static String? validateName(String? value, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (value == null || value.isEmpty) {
      return l10n.nameRequired;
    }
    
    return null;
  }

  static String? validatePhone(String? value, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (value == null || value.isEmpty) {
      return l10n.phoneRequired;
    }
    
    return null;
  }

  static String? validateConfirmPassword(
      String? value, String password, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (value == null || value.isEmpty) {
      return l10n.passwordRequired;
    }
    
    if (value != password) {
      return l10n.passwordsDoNotMatch;
    }
    
    return null;
  }
}
