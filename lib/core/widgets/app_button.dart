import 'package:flutter/material.dart';
import 'package:zovi/core/theme/app_colors.dart';

@immutable
final class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.backgroundColor = AppColors.deepRoast,
    this.foregroundColor = AppColors.white,
    this.borderColor,
    this.leading,
    this.height = 54,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final Widget? leading;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final effectiveBackground =
        enabled ? backgroundColor : AppColors.progressInactive;
    final effectiveForeground = enabled
        ? foregroundColor
        : AppColors.white.withValues(alpha: 0.65);
    final effectiveBorder = enabled ? borderColor : AppColors.progressInactive;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: Material(
        color: effectiveBackground,
        shape: StadiumBorder(
          side: effectiveBorder == null
              ? BorderSide.none
              : BorderSide(color: effectiveBorder),
        ),
        child: InkWell(
          onTap: onPressed,
          customBorder: const StadiumBorder(),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 10),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: effectiveForeground,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
