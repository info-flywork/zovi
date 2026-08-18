import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:zovi/core/router/app_router.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';

final class AppSnackbar {
  AppSnackbar._();
  static final AppSnackbar instance = AppSnackbar._();

  void show(
    BuildContext context,
    String message, {
    bool isError = false,
    EdgeInsetsGeometry? margin,
  }) {
    final messengerContext = AppRouter.rootKey.currentContext ?? context;

    ScaffoldMessenger.of(messengerContext)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.28,
              color: AppColors.white,
            ),
          ),
          backgroundColor: isError ? Colors.red.shade700 : AppColors.deepRoast,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: margin ?? const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
  }

  void showLinkAdded(BuildContext context, String message) {
    final messengerContext = AppRouter.rootKey.currentContext ?? context;

    ScaffoldMessenger.of(messengerContext)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          behavior: SnackBarBehavior.floating,
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          content: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(10),
                color: const Color(0x80262626),
                child: Row(
                  children: [
                    const AppIcon(AssetPaths.iconLinkBottomsheet, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1,
                          letterSpacing: -0.28,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
  }
}
