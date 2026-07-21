import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:zovi/core/widgets/app_loading.dart';

extension FutureLoadingX<T> on Future<T> {
  Future<T> withLoading(BuildContext context) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (_) => PopScope(
        canPop: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(color: Colors.white.withValues(alpha: 0.2)),
              ),
            ),
            const Center(child: AppLoading()),
          ],
        ),
      ),
    );
    try {
      return await this;
    } finally {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
