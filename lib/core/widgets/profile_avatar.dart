import 'dart:io';

import 'package:flutter/material.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';

@immutable
final class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    required this.path,
    required this.size,
    this.showGradientRing = false,
    this.showSeenRing = false,
    this.ringWidth = 3,
    this.ringGap = 2,
    this.ringGapColor = AppColors.white,
    this.ringOpacity = 1,
    super.key,
  });

  /// Dış boyut (ring varsa ring dahil).
  /// `path`: network URL, local file (`/…`), asset, or empty → profile icon.
  final String path;
  final double size;
  final bool showGradientRing;
  final bool showSeenRing;
  final double ringWidth;
  final double ringGap;
  final Color ringGapColor;

  /// Only the story ring is faded; the photo stays full strength.
  final double ringOpacity;

  bool get _isNetwork =>
      path.startsWith('http://') || path.startsWith('https://');

  bool get _isFilePath => path.startsWith('/') || path.startsWith('file:');

  /// Gerçek kullanıcı fotoğrafı (CDN / galeri). Asset placeholder değil.
  bool get _hasPhoto =>
      path.isNotEmpty && (_isNetwork || _isFilePath);

  Widget get _placeholder {
    return ColoredBox(
      color: AppColors.surfaceGray,
      child: Center(
        child: AppIcon(
          AssetPaths.iconProfile6,
          size: size * 0.42,
          color: AppColors.mutedGray,
        ),
      ),
    );
  }

  Widget get _image {
    final Widget child;
    if (!_hasPhoto) {
      child = _placeholder;
    } else if (_isNetwork) {
      child = Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder,
      );
    } else if (_isFilePath) {
      final filePath = path.startsWith('file:')
          ? Uri.parse(path).toFilePath()
          : path;
      child = Image.file(
        File(filePath),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder,
      );
    } else {
      child = _placeholder;
    }
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

    final inset = ringWidth + ringGap;
    final imageSize = size - inset * 2;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: ringOpacity.clamp(0.0, 1.0),
            child: Container(
              width: size,
              height: size,
              decoration: ringDecoration,
              padding: EdgeInsets.all(ringWidth),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ringGapColor,
                ),
              ),
            ),
          ),
          SizedBox(
            width: imageSize,
            height: imageSize,
            child: _image,
          ),
        ],
      ),
    );
  }
}

@immutable
final class OverlappingProfileAvatars extends StatelessWidget {
  const OverlappingProfileAvatars({
    required this.avatars,
    this.size = 34,
    this.overlap = 11,
    super.key,
  });

  final List<String> avatars;
  final double size;
  final double overlap;

  @override
  Widget build(BuildContext context) {
    if (avatars.isEmpty) return const SizedBox.shrink();
    final shown = avatars.take(3).toList();
    final width = size + (shown.length - 1) * (size - overlap);

    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * (size - overlap),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 3),
                ),
                child: ProfileAvatar(path: shown[i], size: size - 6),
              ),
            ),
        ],
      ),
    );
  }
}
