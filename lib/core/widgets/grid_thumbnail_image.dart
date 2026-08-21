import 'package:flutter/material.dart';
import 'package:zovi/core/utils/media_kind.dart';

/// Small square grid tile — decode-resized, cache-friendly network image.
@immutable
final class GridThumbnailImage extends StatelessWidget {
  const GridThumbnailImage({
    required this.url,
    this.cacheSize,
    super.key,
  });

  final String url;
  final int? cacheSize;

  static int cacheSideFor(BuildContext context, {int columns = 3}) {
    final width = MediaQuery.sizeOf(context).width;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return ((width / columns) * dpr).ceil().clamp(160, 480);
  }

  /// Bunny Optimizer query — ignored if the zone has no optimizer.
  static String sizedUrl(String url, int width) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.host.contains('b-cdn.net')) return url;
    if (uri.queryParameters.containsKey('width')) return url;
    return uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        'width': '$width',
        'quality': '70',
      },
    ).toString();
  }

  @override
  Widget build(BuildContext context) {
    if (isVideoMediaPath(url)) {
      return const ColoredBox(color: Color(0xFFE8E8E8));
    }
    final side = cacheSize ?? cacheSideFor(context);
    return Image.network(
      sizedUrl(url, side),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      cacheWidth: side,
      filterQuality: FilterQuality.low,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        final ready = wasSynchronouslyLoaded || frame != null;
        return ColoredBox(
          color: const Color(0xFFE8E8E8),
          child: ready ? child : null,
        );
      },
      errorBuilder: (_, _, _) =>
          const ColoredBox(color: Color(0xFFE8E8E8)),
    );
  }
}
