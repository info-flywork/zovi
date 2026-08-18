import 'package:flutter/material.dart';
import 'package:zovi/core/theme/app_colors.dart';

@immutable
final class AppLoading extends StatelessWidget {
  const AppLoading({
    super.key,
    this.size,
    this.strokeWidth,
    this.color,
    this.centered = true,
  });

  /// When set, constrains the indicator to a square of this size.
  final double? size;
  final double? strokeWidth;
  final Color? color;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? AppColors.zoviOrange;
    Widget indicator = CircularProgressIndicator.adaptive(
      strokeWidth: strokeWidth ?? 4,
      backgroundColor: resolved.withValues(alpha: 0.15),
      valueColor: AlwaysStoppedAnimation<Color>(resolved),
    );
    if (size != null) {
      indicator = SizedBox(width: size, height: size, child: indicator);
    }
    if (!centered) return indicator;
    return Center(child: indicator);
  }
}
