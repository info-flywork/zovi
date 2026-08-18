part of '../home_view.dart';

@immutable
final class HomeMapAnonMarker extends StatefulWidget {
  const HomeMapAnonMarker({
    required this.user,
    required this.expanded,
    required this.onTap,
    super.key,
  });

  final MapFriend user;
  final bool expanded;
  final VoidCallback onTap;

  @override
  State<HomeMapAnonMarker> createState() => _HomeMapAnonMarkerState();
}

final class _HomeMapAnonMarkerState extends State<HomeMapAnonMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  @override
  void didUpdateWidget(covariant HomeMapAnonMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
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

  @override
  Widget build(BuildContext context) {
    final distance = widget.user.distanceMeters ?? 0;
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _TightPngIcon(
            asset: AssetPaths.iconPinkQuestion,
            size: 56,
            scale: 1.4,
          ),
          SizeTransition(
            sizeFactor: curve,
            axis: Axis.vertical,
            child: FadeTransition(
              opacity: curve,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.18),
                  end: Offset.zero,
                ).animate(curve),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
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
                ),
              ),
            ),
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
