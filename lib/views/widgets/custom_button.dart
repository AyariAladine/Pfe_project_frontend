import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final IconData? icon;
  final Widget? iconWidget;
  final Gradient? gradient;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 54,
    this.icon,
    this.iconWidget,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = backgroundColor ?? (isDark ? AppColors.primaryLight : AppColors.primary);

    final effectiveGradient = gradient ??
        LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: isOutlined
              ? [Colors.transparent, Colors.transparent]
              : [baseColor, Color.lerp(baseColor, Colors.black, 0.18)!],
        );

    if (isOutlined) {
      return Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: baseColor, width: 1.5),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(13),
            splashColor: baseColor.withValues(alpha: 0.1),
            child: Center(child: _buildChild(context, baseColor)),
          ),
        ),
      );
    }

    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: effectiveGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: onPressed != null && !isLoading
            ? [
                BoxShadow(
                  color: baseColor.withValues(alpha: 0.38),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                  spreadRadius: -3,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.white.withValues(alpha: 0.12),
          child: Center(child: _buildChild(context, Colors.white)),
        ),
      ),
    );
  }

  Widget _buildChild(BuildContext context, Color color) {
    if (isLoading) {
      return SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    final textStyle = TextStyle(
      fontFamily: 'Cairo',
      color: textColor ?? color,
      fontWeight: FontWeight.w700,
      fontSize: 15,
      letterSpacing: 0.3,
    );

    if (icon != null || iconWidget != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ?iconWidget,
          if (icon != null) Icon(icon, size: 20, color: textColor ?? color),
          const SizedBox(width: 10),
          Text(text, style: textStyle),
        ],
      );
    }

    return Text(text, style: textStyle);
  }
}
