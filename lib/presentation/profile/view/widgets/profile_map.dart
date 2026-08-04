part of '../profile_view.dart';

class ProfileMap extends StatelessWidget {
  const ProfileMap({
    required this.location,
    required this.point,
    required this.avatarPath,
    required this.hasRealLocation,
    super.key,
  });

  final String location;
  final LatLng point;
  final String avatarPath;
  final bool hasRealLocation;

  static const _zoom = 14.5;

  void _openExpanded(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 560),
        reverseTransitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _ProfileMapExpanded(
            location: location,
            point: point,
            avatarPath: avatarPath,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
              alignment: Alignment.center,
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 398 / 180,
            child: Stack(
              fit: StackFit.expand,
              children: [
                IgnorePointer(
                  child: _ProfileMapSurface(
                    point: point,
                    avatarPath: avatarPath,
                    interactive: false,
                    zoom: _zoom,
                  ),
                ),
                if (!hasRealLocation)
                  const IgnorePointer(
                    child: ColoredBox(
                      color: Color(0x33FFFFFF),
                      child: AppLoading(
                        size: 22,
                        strokeWidth: 2.2,
                      ),
                    ),
                  ),
                IgnorePointer(
                  child: _ProfileMapLocationChip(
                    location: location,
                    showDistance: true,
                  ),
                ),
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _openExpanded(context),
                      splashColor: Colors.black.withValues(alpha: 0.06),
                      highlightColor: Colors.black.withValues(alpha: 0.04),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileMapExpanded extends StatelessWidget {
  const _ProfileMapExpanded({
    required this.location,
    required this.point,
    required this.avatarPath,
  });

  final String location;
  final LatLng point;
  final String avatarPath;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _ProfileMapSurface(
            point: point,
            avatarPath: avatarPath,
            interactive: true,
            zoom: 15,
          ),
          Positioned(
            top: top + 8,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const AppIcon(AssetPaths.iconArrowLeft, size: 24),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: bottom + 16,
            child: _ProfileMapLocationChip(
              location: location,
              showDistance: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMapSurface extends StatelessWidget {
  const _ProfileMapSurface({
    required this.point,
    required this.avatarPath,
    required this.interactive,
    required this.zoom,
  });

  final LatLng point;
  final String avatarPath;
  final bool interactive;
  final double zoom;

  static const _tileUrl =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';
  static const _tileSubdomains = ['a', 'b', 'c', 'd'];

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      key: ValueKey(
        '${point.latitude.toStringAsFixed(5)}_'
        '${point.longitude.toStringAsFixed(5)}_$interactive',
      ),
      options: MapOptions(
        initialCenter: point,
        initialZoom: zoom,
        interactionOptions: InteractionOptions(
          flags: interactive
              ? InteractiveFlag.drag |
                    InteractiveFlag.flingAnimation |
                    InteractiveFlag.pinchMove |
                    InteractiveFlag.pinchZoom |
                    InteractiveFlag.doubleTapZoom |
                    InteractiveFlag.doubleTapDragZoom |
                    InteractiveFlag.scrollWheelZoom
              : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: _tileUrl,
          subdomains: _tileSubdomains,
          userAgentPackageName: 'com.flywork.zovi',
          maxZoom: 20,
          retinaMode: RetinaMode.isHighDensity(context),
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: point,
              width: 44,
              height: 44,
              alignment: Alignment.center,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.zoviOrange,
                    width: 2.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: ProfileAvatar(path: avatarPath, size: 39),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileMapLocationChip extends StatelessWidget {
  const _ProfileMapLocationChip({
    required this.location,
    required this.showDistance,
  });

  final String location;
  final bool showDistance;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: showDistance
            ? const EdgeInsets.fromLTRB(12, 0, 12, 12)
            : EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: showDistance
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1,
                  letterSpacing: -0.28,
                  color: AppColors.deepRoast,
                ),
              ),
            ),
            if (showDistance)
              Text(
                'distance_km'.tr(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1,
                  letterSpacing: -0.28,
                  color: AppColors.textTertiary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
