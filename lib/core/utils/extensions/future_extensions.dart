import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:zovi/core/widgets/app_loading.dart';

extension FutureLoadingX<T> on Future<T> {
  Future<T> withLoading(BuildContext context) async {
    final navigator = Navigator.of(context, rootNavigator: true);

    showDialog<void>(
      context: context,
      useRootNavigator: true,
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
    // Dialog route'unun stack'e oturmasını bekle; aksi halde finally pop
    // alttaki sheet'i kapatıp submit'i "takılı" gibi gösterebiliyor.
    await Future<void>.delayed(Duration.zero);

    try {
      return await this;
    } finally {
      if (navigator.mounted && navigator.canPop()) {
        navigator.pop();
      }
    }
  }
}
