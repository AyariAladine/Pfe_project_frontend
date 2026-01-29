import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

/// Handles API error codes and returns localized error messages
class ErrorHandler {
  /// Get localized error message based on error code or raw message
  static String getLocalizedError(
    BuildContext context,
    String errorMessage, {
    int? statusCode,
  }) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return errorMessage;

    // Check for error codes first (from API service)
    switch (errorMessage) {
      case 'NO_INTERNET':
        return l10n.noInternetConnection;
      case 'UNEXPECTED_ERROR':
        return l10n.unexpectedError;
      case 'LOGIN_REQUIRED':
        return l10n.loginRequired;
      case 'INVALID_CREDENTIALS':
        return l10n.invalidCredentials;
      case 'UNAUTHORIZED':
        return l10n.unauthorized;
      case 'NOT_FOUND':
        return l10n.notFound;
      case 'SERVER_ERROR':
        return l10n.serverError;
      case 'EMAIL_EXISTS':
        return l10n.emailAlreadyExists;
      case 'ACCOUNT_TYPE_REQUIRED':
        return l10n.accountTypeRequired;
      case 'INVALID_CODE':
        return l10n.invalidCode;
      case 'CODE_EXPIRED':
        return l10n.codeExpired;
    }

    // Check for known error patterns and return localized messages
    final lowerMessage = errorMessage.toLowerCase();

    // Network errors
    if (lowerMessage.contains('socketexception') ||
        lowerMessage.contains('no internet') ||
        lowerMessage.contains('network')) {
      return l10n.noInternetConnection;
    }

    // Handle by status code
    if (statusCode != null) {
      switch (statusCode) {
        case 401:
          return l10n.invalidCredentials;
        case 403:
          return l10n.unauthorized;
        case 404:
          return l10n.notFound;
        case 409:
          // Conflict - usually email already exists
          if (lowerMessage.contains('email') ||
              lowerMessage.contains('exist')) {
            return l10n.emailAlreadyExists;
          }
          break;
        case 500:
          return l10n.serverError;
      }
    }

    // Check for specific error patterns in message
    if (lowerMessage.contains('email') &&
        (lowerMessage.contains('exist') || lowerMessage.contains('already'))) {
      return l10n.emailAlreadyExists;
    }

    if (lowerMessage.contains('invalid') && lowerMessage.contains('code')) {
      return l10n.invalidCode;
    }

    if (lowerMessage.contains('expired') && lowerMessage.contains('code')) {
      return l10n.codeExpired;
    }

    if (lowerMessage.contains('login') ||
        lowerMessage.contains('authenticate')) {
      return l10n.loginRequired;
    }

    if (lowerMessage.contains('credential') ||
        lowerMessage.contains('password')) {
      return l10n.invalidCredentials;
    }

    // Return the original message if no pattern matches
    // But if it contains Arabic, return a generic error
    if (_containsArabic(errorMessage)) {
      return l10n.unexpectedError;
    }

    return errorMessage;
  }

  /// Check if string contains Arabic characters
  static bool _containsArabic(String text) {
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    return arabicRegex.hasMatch(text);
  }
}
