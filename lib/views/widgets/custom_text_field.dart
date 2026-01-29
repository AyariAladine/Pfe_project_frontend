import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;
  final int maxLines;
  final int? maxLength;
  final TextDirection? textDirection;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.textDirection,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
      maxLines: maxLines,
      maxLength: maxLength,
      textDirection: textDirection,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
      ),
      cursorColor: isDark ? AppColors.primaryLight : AppColors.primary,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        counterText: '', // Hide character counter
        filled: true,
        fillColor: isDark ? AppColors.cardBackgroundDark : AppColors.surface,
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
                size: 22,
              )
            : null,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? AppColors.primaryLight : AppColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        hintStyle: TextStyle(
          color: isDark ? AppColors.textHintDark : AppColors.textHint,
          fontSize: 14,
        ),
      ),
    );
  }
}
