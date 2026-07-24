import 'dart:io';

import 'package:flutter/material.dart';
import 'package:zovi/core/theme/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    required this.path,
    required this.size,
    this.showGradientRing = false,
    this.showSeenRing = false,
    this.ringWidth = 3,
    this.ringGap = 2,
    this.ringGapColor = AppColors.white,
    super.key,
  });

  /// Dış boyut (ring varsa ring dahil).
  final String path;
  final double size;
  final bool showGradientRing;
  final bool showSeenRing;
  final double ringWidth;
  final double ringGap;
  final Color ringGapColor;

  bool get _isFilePath => path.startsWith('/');

  Widget get _image {
    final child = _isFilePath
        ? Image.file(File(path), fit: BoxFit.cover)
        : Image.asset(path, fit: BoxFit.cover);
    return ClipOval(child: child);
  }

  @override
  Widget build(BuildContext context) {
    if (!showGradientRing && !showSeenRing) {
      return SizedBox(width: size, height: size, child: _image);
    }

    final ringDecoration = showGradientRing
        ? const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.storyRingGradient,
          )
        : const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFD1D1D6),
          );

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(ringWidth),
      decoration: ringDecoration,
      child: Container(
        decoration: BoxDecoration(shape: BoxShape.circle, color: ringGapColor),
        child: _image,
      ),
    );
  }
}
