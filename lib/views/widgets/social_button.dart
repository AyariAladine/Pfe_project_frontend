import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SocialButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final bool isLoading;

  const SocialButton({
    super.key,
    required this.text,
    this.onPressed,
    required this.icon,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.isLoading = false,
  });

  factory SocialButton.google({
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return SocialButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      backgroundColor: Colors.white,
      textColor: AppColors.textPrimary,
      borderColor: AppColors.border,
      icon: const Icon(
        Icons.g_mobiledata,
        size: 24,
        color: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.white,
          foregroundColor: textColor ?? AppColors.textPrimary,
          side: BorderSide(
            color: borderColor ?? AppColors.border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 12),
                  Text(
                    text,
                    style: TextStyle(
                      color: textColor ?? AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
