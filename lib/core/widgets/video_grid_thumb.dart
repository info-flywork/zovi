import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';

/// Grid tile for video media: first frame + reels badge.
@immutable
final class VideoGridThumb extends StatefulWidget {
  const VideoGridThumb({
    required this.path,
    this.iconSize = 22,
    this.placeholderColor = AppColors.black,
    super.key,
  });

  final String path;
  final double iconSize;
  final Color placeholderColor;

  @override
  State<VideoGridThumb> createState() => _VideoGridThumbState();
}

final class _VideoGridThumbState extends State<VideoGridThumb> {
  VideoPlayerController? _controller;
  var _ready = false;

  bool get _isNetwork =>
      widget.path.startsWith('http://') || widget.path.startsWith('https://');

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant VideoGridThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _disposeController();
      _ready = false;
      _init();
    }
  }

  Future<void> _init() async {
    final path = widget.path.trim();
    if (path.isEmpty) return;

    final options = VideoPlayerOptions(mixWithOthers: true);
    final controller = _isNetwork
        ? VideoPlayerController.networkUrl(
            Uri.parse(path),
            videoPlayerOptions: options,
          )
        : VideoPlayerController.file(
            File(path.replaceFirst('file://', '')),
            videoPlayerOptions: options,
          );
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setVolume(0);
      await controller.pause();
      await controller.seekTo(Duration.zero);
      if (!mounted || _controller != controller) {
        await controller.dispose();
        return;
      }
      setState(() => _ready = true);
    } catch (_) {
      await controller.dispose();
      if (identical(_controller, controller)) _controller = null;
      if (mounted) setState(() => _ready = false);
    }
  }

  void _disposeController() {
    final controller = _controller;
    _controller = null;
    controller?.dispose();
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready =
        _ready && controller != null && controller.value.isInitialized;

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: widget.placeholderColor),
        if (ready)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
          ),
        Positioned(
          top: 8,
          right: 8,
          child: AppIcon(AssetPaths.iconReelsSquare, size: widget.iconSize),
        ),
      ],
    );
  }
}
