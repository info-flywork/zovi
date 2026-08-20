part of '../home_view.dart';

@immutable
final class HomeMapAnonMarker extends StatefulWidget {
  const HomeMapAnonMarker({
    required this.user,
    required this.viewerLocation,
    required this.expanded,
    required this.openAbove,
    required this.onTap,
    super.key,
  });

  /// Full footprint so the question mark can stay centered while the card
  /// animates above or below without resizing the map Marker.
  static const double width = 220;
  static const double height = 200;
  static const double questionSize = 56;
  static const double cardSlot = 72;

  final MapFriend user;
  final LatLng viewerLocation;
  final bool expanded;

  /// Prefer opening the info card above the question mark (collision below).
  final bool openAbove;
  final VoidCallback onTap;

  @override
  State<HomeMapAnonMarker> createState() => _HomeMapAnonMarkerState();
}

final class _HomeMapAnonMarkerState extends State<HomeMapAnonMarker>
    with SingleTickerProviderStateMixin {
  static const _distance = Distance();

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    reverseDuration: const Duration(milliseconds: 380),
    value: widget.expanded ? 1 : 0,
  );

  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  /// Locked for the whole open→close cycle so the card doesn't flip mid-animation.
  late bool _openAbove = widget.openAbove;

  @override
  void didUpdateWidget(covariant HomeMapAnonMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.expanded && widget.expanded) {
      _openAbove = widget.openAbove;
    }
    if (oldWidget.expanded == widget.expanded) return;
    if (widget.expanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _liveDistanceMeters() {
    final cached = widget.user.distanceMeters;
    if (widget.user.lat == 0 && widget.user.lng == 0) {
      return cached ?? 0;
    }
    return _distance
        .as(
          LengthUnit.Meter,
          widget.viewerLocation,
          LatLng(widget.user.lat, widget.user.lng),
        )
        .round();
  }

  @override
  Widget build(BuildContext context) {
    final distance = _liveDistanceMeters();
    final openAbove = _openAbove;
    final questionTop =
        (HomeMapAnonMarker.height - HomeMapAnonMarker.questionSize) / 2;

    return SizedBox(
      width: HomeMapAnonMarker.width,
      height: HomeMapAnonMarker.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: openAbove
                ? questionTop - HomeMapAnonMarker.cardSlot
                : questionTop + HomeMapAnonMarker.questionSize,
            height: HomeMapAnonMarker.cardSlot,
            child: SizeTransition(
              sizeFactor: _curve,
              axis: Axis.vertical,
              axisAlignment: openAbove ? 1 : -1,
              child: FadeTransition(
                opacity: _curve,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0, openAbove ? 0.22 : -0.22),
                    end: Offset.zero,
                  ).animate(_curve),
                  child: Align(
                    alignment: openAbove
                        ? Alignment.bottomCenter
                        : Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: openAbove ? 0 : 4,
                        bottom: openAbove ? 4 : 0,
                      ),
                      child: GestureDetector(
                        onTap: widget.onTap,
                        behavior: HitTestBehavior.opaque,
                        child: _AnonInfoCard(distance: distance),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: (HomeMapAnonMarker.width - HomeMapAnonMarker.questionSize) / 2,
            top: questionTop,
            child: GestureDetector(
              onTap: widget.onTap,
              behavior: HitTestBehavior.opaque,
              child: const _TightPngIcon(
                asset: AssetPaths.iconPinkQuestion,
                size: HomeMapAnonMarker.questionSize,
                scale: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

@immutable
final class _AnonInfoCard extends StatelessWidget {
  const _AnonInfoCard({required this.distance});

  final int distance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(99),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _TightPngIcon(
            asset: AssetPaths.iconPinkPerson,
            size: 36,
            scale: 1.85,
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'map_anon_title'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 20 / 16,
                  color: AppColors.black,
                ),
              ),
              Text(
                'map_anon_distance'.tr(
                  namedArgs: {'distance': '$distance'},
                ),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 16 / 12,
                  color: AppColors.black.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

@immutable
final class _TightPngIcon extends StatelessWidget {
  const _TightPngIcon({
    required this.asset,
    required this.size,
    required this.scale,
  });

  final String asset;
  final double size;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRect(
        child: Transform.scale(
          scale: scale,
          child: Image.asset(asset, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
