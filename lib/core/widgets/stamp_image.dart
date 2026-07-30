import 'dart:io';

import 'package:flutter/material.dart';
import 'package:zovi/core/cache/stamp_image_cache.dart';
import 'package:zovi/core/di/injection.dart';

/// Renders a stamp from a local asset path or a CDN URL (disk-cached).
class StampImage extends StatefulWidget {
  const StampImage({
    required this.path,
    this.stampId = '',
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.errorBuilder,
    super.key,
  });

  final String path;
  final String stampId;
  final double? width;
  final double? height;
  final BoxFit fit;
  final ImageErrorWidgetBuilder? errorBuilder;

  static bool isNetworkPath(String path) =>
      path.startsWith('http://') || path.startsWith('https://');

  @override
  State<StampImage> createState() => _StampImageState();
}

class _StampImageState extends State<StampImage> {
  File? _cachedFile;
  var _failed = false;
  var _loading = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void didUpdateWidget(covariant StampImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path || oldWidget.stampId != widget.stampId) {
      _cachedFile = null;
      _failed = false;
      _loading = false;
      _bootstrap();
    }
  }

  void _bootstrap() {
    if (!StampImage.isNetworkPath(widget.path)) return;

    final peeked = getIt<StampImageCache>().peekFile(
      stampId: widget.stampId,
      url: widget.path,
    );
    if (peeked != null) {
      _cachedFile = peeked;
      return;
    }
    _resolve();
  }

  Future<void> _resolve() async {
    if (!StampImage.isNetworkPath(widget.path)) return;
    _loading = true;
    try {
      final file = await getIt<StampImageCache>().resolveFile(
        stampId: widget.stampId,
        url: widget.path,
      );
      if (!mounted) return;
      setState(() {
        _cachedFile = file;
        _loading = false;
        _failed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!StampImage.isNetworkPath(widget.path)) {
      return Image.asset(
        widget.path,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: widget.errorBuilder,
      );
    }

    final cached = _cachedFile;
    if (cached != null) {
      return Image.file(
        cached,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        gaplessPlayback: true,
        errorBuilder: widget.errorBuilder,
      );
    }

    if (_failed) {
      return Image.network(
        widget.path,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: widget.errorBuilder,
      );
    }

    // Prefer waiting on disk cache over hammering CDN for every cell.
    if (_loading) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const ColoredBox(color: Color(0x14000000)),
      );
    }

    return Image.network(
      widget.path,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: widget.errorBuilder,
    );
  }
}
