import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/widgets/app_loading.dart';

@immutable
final class AppVideoPlayer extends StatefulWidget {
  const AppVideoPlayer({
    required this.path,
    this.autoPlay = true,
    this.looping = true,
    this.muted = false,
    this.fit = BoxFit.cover,
    super.key,
  });

  final String path;
  final bool autoPlay;
  final bool looping;
  final bool muted;
  final BoxFit fit;

  @override
  State<AppVideoPlayer> createState() => _AppVideoPlayerState();
}

final class _AppVideoPlayerState extends State<AppVideoPlayer> {
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
  void didUpdateWidget(covariant AppVideoPlayer oldWidget) {
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
    final controller = _isNetwork
        ? VideoPlayerController.networkUrl(Uri.parse(path))
        : VideoPlayerController.file(
            File(path.replaceFirst('file://', '')),
          );
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(widget.looping);
      await controller.setVolume(widget.muted ? 0 : 1);
      if (widget.autoPlay) await controller.play();
      if (!mounted || _controller != controller) {
        await controller.dispose();
        return;
      }
      setState(() => _ready = true);
    } catch (_) {
      await controller.dispose();
      if (identical(_controller, controller)) _controller = null;
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
    if (!_ready || controller == null || !controller.value.isInitialized) {
      return const ColoredBox(
        color: AppColors.black,
        child: AppLoading(),
      );
    }

    return FittedBox(
      fit: widget.fit,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  }
}
