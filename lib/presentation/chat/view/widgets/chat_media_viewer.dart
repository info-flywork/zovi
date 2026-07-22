import 'dart:io';

import 'package:flutter/material.dart';
import 'package:zovi/core/theme/app_colors.dart';

Future<void> showChatMediaViewer(
  BuildContext context, {
  required String heroTag,
  String? assetPath,
  String? filePath,
}) {
  assert(
    (assetPath != null) ^ (filePath != null),
    'Provide either assetPath or filePath',
  );

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'chat-media-viewer',
    barrierColor: Colors.black.withValues(alpha: 0.92),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      return ChatMediaViewer(
        heroTag: heroTag,
        assetPath: assetPath,
        filePath: filePath,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

class ChatMediaViewer extends StatelessWidget {
  const ChatMediaViewer({
    required this.heroTag,
    this.assetPath,
    this.filePath,
    super.key,
  });

  final String heroTag;
  final String? assetPath;
  final String? filePath;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
            ),
            Center(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Hero(
                  tag: heroTag,
                  child: assetPath != null
                      ? Image.asset(assetPath!, fit: BoxFit.contain)
                      : Image.file(File(filePath!), fit: BoxFit.contain),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 12,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.close,
                    size: 24,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
