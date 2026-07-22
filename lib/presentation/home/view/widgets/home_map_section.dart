part of '../home_view.dart';

class HomeMapSection extends StatefulWidget {
  const HomeMapSection({
    required this.city,
    required this.mapFriends,
    required this.onAddTap,
    super.key,
  });

  final String city;
  final List<MapFriend> mapFriends;
  final VoidCallback onAddTap;

  @override
  State<HomeMapSection> createState() => _HomeMapSectionState();
}

class _HomeMapSectionState extends State<HomeMapSection>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const _fallbackCenter = LatLng(34.0522, -118.2437);
  static const _defaultZoom = 14.5;

  final _mapController = MapController();

  LatLng _userLocation = _fallbackCenter;
  String _cityLabel = '';
  bool _locating = true;
  bool _mapReady = false;
  bool _hasRealLocation = false;
  AnimationController? _cameraAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cityLabel = widget.city;
    unawaited(_resolveUserLocation(animate: false));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraAnimation?.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_hasRealLocation) {
      unawaited(_resolveUserLocation(animate: true));
    }
  }

  LatLng _friendPoint(MapFriend friend) {
    return LatLng(
      _userLocation.latitude + friend.y * 0.02,
      _userLocation.longitude + friend.x * 0.02,
    );
  }

  void _moveCamera(LatLng target, double zoom) {
    if (!_mapReady) return;
    _mapController.move(target, zoom);
  }

  Future<void> _updateCityLabel(LatLng target) async {
    try {
      final placemarks = await Geocoding().placemarkFromCoordinates(
        target.latitude,
        target.longitude,
      );
      if (!mounted || placemarks.isEmpty) return;
      final place = placemarks.first;
      final label = [
        place.locality,
        place.subAdministrativeArea,
        place.administrativeArea,
      ].whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty);
      if (label.isEmpty) return;
      setState(() => _cityLabel = label.first);
    } catch (_) {
      // Etiket opsiyonel; harita yine de konuma gider.
    }
  }

  Future<Position?> _readPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } on TimeoutException {
      return Geolocator.getLastKnownPosition();
    } catch (_) {
      return Geolocator.getLastKnownPosition();
    }
  }

  Future<void> _resolveUserLocation({required bool animate}) async {
    if (mounted) setState(() => _locating = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _locating = false);
          AppSnackbar.instance.show(
            context,
            'location_service_disabled'.tr(),
            isError: true,
          );
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _locating = false);
          AppSnackbar.instance.show(
            context,
            'location_permission_denied'.tr(),
            isError: true,
          );
        }
        return;
      }

      Position? position;
      try {
        position = await _readPosition();
      } on TimeoutException {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        if (mounted) {
          setState(() => _locating = false);
          AppSnackbar.instance.show(
            context,
            'location_unavailable'.tr(),
            isError: true,
          );
        }
        return;
      }

      final target = LatLng(position.latitude, position.longitude);

      if (!mounted) return;
      setState(() {
        _userLocation = target;
        _hasRealLocation = true;
        _locating = false;
      });

      // Harita henüz hazır değilse onMapReady konumla merkezler.
      if (_mapReady) {
        if (animate) {
          await _animateTo(target, zoom: _defaultZoom);
        } else {
          _moveCamera(target, _defaultZoom);
        }
      }

      unawaited(_updateCityLabel(target));
    } catch (_) {
      if (mounted) {
        setState(() => _locating = false);
        AppSnackbar.instance.show(
          context,
          'location_unavailable'.tr(),
          isError: true,
        );
      }
    }
  }

  Future<void> _animateTo(LatLng target, {required double zoom}) async {
    if (!_mapReady) {
      _moveCamera(target, zoom);
      return;
    }

    _cameraAnimation?.stop();
    _cameraAnimation?.dispose();

    final begin = _mapController.camera.center;
    final beginZoom = _mapController.camera.zoom;
    final latLngTween = LatLngTween(begin: begin, end: target);
    final zoomTween = Tween<double>(begin: beginZoom, end: zoom);

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _cameraAnimation = controller;

    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutCubic,
    );

    void tick() {
      _mapController.move(
        latLngTween.evaluate(animation),
        zoomTween.evaluate(animation),
      );
    }

    animation.addListener(tick);
    try {
      await controller.forward();
    } finally {
      animation.removeListener(tick);
      controller.dispose();
      if (identical(_cameraAnimation, controller)) {
        _cameraAnimation = null;
      }
    }
  }

  Future<void> _onRecenterTap() => _resolveUserLocation(animate: true);

  @override
  Widget build(BuildContext context) {
    final mapActionsBottom =
        MediaQuery.paddingOf(context).bottom + MainWrapper.navBarHeight + 20;

    return Stack(
      fit: StackFit.expand,
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _userLocation,
            initialZoom: _defaultZoom,
            minZoom: 3,
            maxZoom: 19,
            backgroundColor: AppColors.offWhite,
            interactionOptions: const InteractionOptions(
              flags:
                  InteractiveFlag.drag |
                  InteractiveFlag.flingAnimation |
                  InteractiveFlag.pinchMove |
                  InteractiveFlag.pinchZoom |
                  InteractiveFlag.doubleTapZoom |
                  InteractiveFlag.doubleTapDragZoom |
                  InteractiveFlag.scrollWheelZoom,
            ),
            onMapReady: () {
              _mapReady = true;
              _moveCamera(_userLocation, _defaultZoom);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.flywork.zovi',
              maxZoom: 19,
            ),
            MarkerLayer(
              markers: [
                for (final friend in widget.mapFriends)
                  Marker(
                    point: _friendPoint(friend),
                    width: 90,
                    height: 110,
                    alignment: Alignment.topCenter,
                    child: IgnorePointer(child: HomeMapMarker(friend: friend)),
                  ),
                Marker(
                  point: _userLocation,
                  width: 48,
                  height: 48,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.zoviOrange,
                          width: 3,
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
                        child: Image.asset(
                          AssetPaths.avatarYou,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.zoviOrange,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          AssetPaths.avatarYou,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _cityLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                width: 36,
                height: 36,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(9999),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const AppIcon(AssetPaths.iconSetting2, size: 24),
              ),
            ],
          ),
        ),
        Positioned(
          left: 20,
          bottom: mapActionsBottom,
          child: _MapSendButton(isLoading: _locating, onTap: _onRecenterTap),
        ),
        Positioned(
          right: 20,
          bottom: mapActionsBottom,
          child: _MapAddButton(onTap: widget.onAddTap),
        ),
      ],
    );
  }
}

class _MapSendButton extends StatelessWidget {
  const _MapSendButton({required this.onTap, this.isLoading = false});

  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 52,
        height: 52,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(9999),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.mintGreen,
                ),
              )
            : const AppIcon(
                AssetPaths.iconChatSend,
                size: 24,
                color: AppColors.mintGreen,
              ),
      ),
    );
  }
}

class _MapAddButton extends StatelessWidget {
  const _MapAddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        padding: const EdgeInsets.symmetric(vertical: 1),
        decoration: BoxDecoration(
          color: AppColors.zoviOrange,
          borderRadius: BorderRadius.circular(9999),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const AppIcon(AssetPaths.iconAdd2, size: 36),
      ),
    );
  }
}
