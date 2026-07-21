import 'package:flutter/material.dart';
import 'package:zovi/core/theme/app_colors.dart';

class AppLoading extends StatelessWidget {
  const AppLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator.adaptive(
        backgroundColor: AppColors.zoviOrange.withValues(alpha: 0.15),
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.zoviOrange),
      ),
    );
  }
}
