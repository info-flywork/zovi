import 'dart:io';

import 'package:flutter/material.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/widgets/stamp_image.dart';

Future<void> showChatMediaViewer(
  BuildContext context, {
  required String heroTag,
  String? assetPath,
  String? filePath,
  String? networkUrl,
}) {
  final sources = [
    if (assetPath != null) 'asset',
    if (filePath != null) 'file',
    if (networkUrl != null && networkUrl.trim().isNotEmpty) 'network',
  ];
  assert(sources.length == 1, 'Provide exactly one of assetPath, filePath, networkUrl');

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
        networkUrl: networkUrl?.trim(),
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

/// Opens a pulse / shared photo fullscreen (network, file, or asset).
Future<void> showPulseMediaViewer(
  BuildContext context, {
  required String imagePath,
  String? heroTag,
}) {
  final path = imagePath.trim();
  if (path.isEmpty) return Future.value();

  final tag = heroTag ?? 'pulse_$path';
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return showChatMediaViewer(context, heroTag: tag, networkUrl: path);
  }
  if (path.startsWith('/') || path.startsWith('file:')) {
    return showChatMediaViewer(
      context,
      heroTag: tag,
      filePath: path.replaceFirst('file://', ''),
    );
  }
  return showChatMediaViewer(context, heroTag: tag, assetPath: path);
}

class ChatMediaViewer extends StatelessWidget {
  const ChatMediaViewer({
    required this.heroTag,
    this.assetPath,
    this.filePath,
    this.networkUrl,
    super.key,
  });

  final String heroTag;
  final String? assetPath;
  final String? filePath;
  final String? networkUrl;

  Widget get _image {
    if (networkUrl != null && networkUrl!.isNotEmpty) {
      return Image.network(
        networkUrl!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }
    if (assetPath != null) {
      return StampImage(path: assetPath!, fit: BoxFit.contain);
    }
    return Image.file(File(filePath!), fit: BoxFit.contain);
  }

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
                child: Hero(tag: heroTag, child: _image),
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
