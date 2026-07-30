part of '../home_view.dart';

class HomeMapSection extends StatefulWidget {
  const HomeMapSection({
    required this.mapFriends,
    required this.onAddTap,
    super.key,
  });

  final List<MapFriend> mapFriends;
  final VoidCallback onAddTap;

  @override
  State<HomeMapSection> createState() => _HomeMapSectionState();
}

class _HomeMapSectionState extends State<HomeMapSection>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const _fallbackCenter = LatLng(34.0522, -118.2437);
  static const _defaultZoom = 14.5;

  /// Carto Voyager — temiz, renkli, modern (ücretsiz tile).
  static const _tileUrl =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';
  static const _tileSubdomains = ['a', 'b', 'c', 'd'];

  final _mapController = MapController();
  late final AnimationController _filterMenuController;
  late final AnimationController _markersController;
  late final CurvedAnimation _markersFade;
  late final CurvedAnimation _markersScaleCurve;
  late final Animation<double> _markersScale;

  LatLng _userLocation = _fallbackCenter;
  String _cityLabel = '';
  bool _locating = true;
  bool _mapReady = false;
  bool _hasRealLocation = false;
  bool _filterMenuOpen = false;
  bool _filterTransitioning = false;
  _MapFilter _selectedFilter = _MapFilter.friends;
  List<MapFriend> _nearbyAnons = const [];
  List<MapVenue> _venues = const [];
  int? _expandedAnonIndex;
  MapFriend? _selectedFriend;
  MapFriend? _friendSheetFriend;
  ActiveMapCheckIn? _lastCheckInSheet;
  int _sheetPresentGeneration = 0;
  AnimationController? _cameraAnimation;
  late final AnimationController _friendSheetController;
  late final Animation<Offset> _friendSheetSlide;
  late final Animation<double> _friendSheetFade;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cityLabel = '';
    _filterMenuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _friendSheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _friendSheetSlide =
        Tween<Offset>(begin: const Offset(0, 0.45), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _friendSheetController,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );
    _friendSheetFade = CurvedAnimation(
      parent: _friendSheetController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _markersController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      value: 1,
    );
    _markersFade = CurvedAnimation(
      parent: _markersController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _markersScaleCurve = CurvedAnimation(
      parent: _markersController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );
    _markersScale = Tween<double>(
      begin: 0.82,
      end: 1,
    ).animate(_markersScaleCurve);
    unawaited(_resolveUserLocation(animate: false));
    unawaited(_loadNearbyAnons());
    unawaited(_loadVenues());
    getIt<UserRepository>().mapFriendsListenable.addListener(
      _onMapFriendsChanged,
    );
  }

  List<MapFriend> get _mapFriends {
    final live = getIt<UserRepository>().mapFriendsListenable.value;
    return live.isNotEmpty ? live : widget.mapFriends;
  }

  void _onMapFriendsChanged() {
    if (!mounted) return;
    final friends = _mapFriends;
    final openFriend = _friendSheetFriend;
    final selectedFriend = _selectedFriend;
    setState(() {
      if (openFriend != null) {
        final match = friends.where((f) => f.name == openFriend.name);
        _friendSheetFriend = match.isEmpty ? openFriend : match.first;
      }
      if (selectedFriend != null) {
        final match = friends.where((f) => f.name == selectedFriend.name);
        _selectedFriend = match.isEmpty ? selectedFriend : match.first;
      }
    });
  }

  Future<void> _loadNearbyAnons() async {
    final items = await getIt<UserRepository>().getMapNearbyAnons();
    if (!mounted) return;
    setState(() => _nearbyAnons = items);
  }

  Future<void> _loadVenues() async {
    final items = await getIt<UserRepository>().getMapVenues();
    if (!mounted) return;
    setState(() => _venues = items);
  }

  @override
  void dispose() {
    getIt<UserRepository>().mapFriendsListenable.removeListener(
      _onMapFriendsChanged,
    );
    WidgetsBinding.instance.removeObserver(this);
    _filterMenuController.dispose();
    _friendSheetController.dispose();
    _markersFade.dispose();
    _markersScaleCurve.dispose();
    _markersController.dispose();
    _cameraAnimation?.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _toggleFilterMenu() {
    setState(() => _filterMenuOpen = !_filterMenuOpen);
    if (_filterMenuOpen) {
      _filterMenuController.forward();
    } else {
      _filterMenuController.reverse();
    }
  }

  void _closeFilterMenu() {
    if (!_filterMenuOpen) return;
    setState(() => _filterMenuOpen = false);
    _filterMenuController.reverse();
  }

  void _selectFilter(_MapFilter filter) {
    if (filter == _selectedFilter || _filterTransitioning) return;
    unawaited(_transitionToFilter(filter));
  }

  Future<void> _transitionToFilter(_MapFilter filter) async {
    _filterTransitioning = true;
    try {
      await _markersController.reverse();
      if (!mounted) return;
      setState(() {
        _selectedFilter = filter;
        _expandedAnonIndex = null;
        _selectedFriend = null;
        _friendSheetFriend = null;
      });
      _friendSheetController.value = 0;
      unawaited(_pulseCameraForFilter());
      await _markersController.forward();
    } finally {
      _filterTransitioning = false;
    }
  }

  Future<void> _pulseCameraForFilter() async {
    if (!_mapReady || !mounted) return;
    final zoom = _mapController.camera.zoom;
    final dip = (zoom - 0.4).clamp(3.0, 19.0);
    await _animateTo(
      _userLocation,
      zoom: dip,
      duration: const Duration(milliseconds: 280),
    );
    if (!mounted) return;
    await _animateTo(
      _userLocation,
      zoom: _defaultZoom,
      duration: const Duration(milliseconds: 360),
    );
  }

  Widget _animatedMarker(Widget child) {
    return FadeTransition(
      opacity: _markersFade,
      child: ScaleTransition(scale: _markersScale, child: child),
    );
  }

  void _onAnonTap(int index) {
    if (_friendSheetFriend != null) {
      unawaited(_closeFriendSheet());
    }
    if (_filterMenuOpen) {
      setState(() {
        _filterMenuOpen = false;
        _expandedAnonIndex = index;
      });
      _filterMenuController.reverse();
      return;
    }
    setState(() {
      _expandedAnonIndex = _expandedAnonIndex == index ? null : index;
    });
  }

  void _onFriendTap(MapFriend friend) {
    if (_filterMenuOpen) {
      _closeFilterMenu();
    }
    // Aynı arkadaş zaten açıksa yeniden animasyonlama.
    if (_friendSheetFriend == friend &&
        _lastCheckInSheet == null &&
        _friendSheetController.value > 0 &&
        _friendSheetController.status != AnimationStatus.reverse) {
      return;
    }
    unawaited(
      _presentBottomSheet(
        apply: () {
          _expandedAnonIndex = null;
          _lastCheckInSheet = null;
          _selectedFriend = friend;
          _friendSheetFriend = friend;
        },
      ),
    );
  }

  void _onSelfTap() {
    final checkIn = getIt<UserRepository>().activeMapCheckIn;
    if (checkIn == null) return;
    if (_filterMenuOpen) {
      _closeFilterMenu();
    }
    if (_lastCheckInSheet != null &&
        _friendSheetFriend == null &&
        _friendSheetController.value > 0 &&
        _friendSheetController.status != AnimationStatus.reverse) {
      return;
    }
    unawaited(
      _presentBottomSheet(
        apply: () {
          _expandedAnonIndex = null;
          _selectedFriend = null;
          _friendSheetFriend = null;
          _lastCheckInSheet = checkIn;
        },
      ),
    );
  }

  /// Açık bir sheet varken geçişte önce kapatır, sonra yenisini açar.
  Future<void> _presentBottomSheet({required VoidCallback apply}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final generation = ++_sheetPresentGeneration;
    final wasOpen =
        _friendSheetController.value > 0 &&
        (_friendSheetFriend != null || _lastCheckInSheet != null);

    if (wasOpen) {
      await _friendSheetController.reverse();
      if (!mounted || generation != _sheetPresentGeneration) return;
    }

    setState(apply);
    await _friendSheetController.forward(from: 0);
  }

  Future<void> _closeFriendSheet() async {
    if (_friendSheetFriend == null && _lastCheckInSheet == null) return;
    _sheetPresentGeneration++;
    FocusManager.instance.primaryFocus?.unfocus();
    if (_selectedFriend != null) {
      setState(() => _selectedFriend = null);
    }
    await _friendSheetController.reverse();
    if (!mounted) return;
    if (_friendSheetFriend != null || _lastCheckInSheet != null) {
      setState(() {
        _friendSheetFriend = null;
        _lastCheckInSheet = null;
      });
    }
  }

  void _onSheetVerticalDragUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta ?? 0;
    if (delta == 0) return;
    // ~220px ≈ sheet yüksekliği; aşağı sürükleyince controller düşer.
    const dismissDistance = 220.0;
    final next = (_friendSheetController.value - (delta / dismissDistance))
        .clamp(0.0, 1.0);
    _friendSheetController.value = next;
  }

  void _onSheetVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final shouldDismiss = velocity > 500 || _friendSheetController.value < 0.7;
    if (shouldDismiss) {
      unawaited(_closeFriendSheet());
    } else {
      unawaited(_friendSheetController.forward());
    }
  }

  Future<void> _sendFriendMessage(String message) async {
    final friend = _friendSheetFriend ?? _selectedFriend;
    if (friend == null) return;

    await _closeFriendSheet();
    if (!mounted) return;

    // Kart kapandıktan sonra üst banner’ı göster.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppInAppNotification.instance.show(
        InAppNotificationData(
          username: friend.name,
          messageKey: 'map_friend_message_sent',
          avatarPath: friend.avatarPath,
          displayName: friend.name,
          showGradientRing: true,
        ),
      );
    });
  }

  void _onMapBackgroundTap() {
    if (_expandedAnonIndex != null) {
      setState(() => _expandedAnonIndex = null);
    }
    unawaited(_closeFriendSheet());
    _closeFilterMenu();
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

  LatLng _venuePoint(MapVenue venue) {
    return LatLng(
      _userLocation.latitude + venue.y * 0.02,
      _userLocation.longitude + venue.x * 0.02,
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

  Future<void> _animateTo(
    LatLng target, {
    required double zoom,
    Duration duration = const Duration(milliseconds: 700),
  }) async {
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

    final controller = AnimationController(vsync: this, duration: duration);
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
    final viewPaddingBottom = MediaQuery.viewPaddingOf(context).bottom;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final mapActionsBottom = viewPaddingBottom + MainWrapper.navBarHeight - 4;
    final friendSheetBottom = keyboardInset > 0
        ? keyboardInset + 12
        : mapActionsBottom + 10;

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
            onTap: (_, _) => _onMapBackgroundTap(),
          ),
          children: [
            TileLayer(
              urlTemplate: _tileUrl,
              subdomains: _tileSubdomains,
              userAgentPackageName: 'com.flywork.zovi',
              maxZoom: 20,
              retinaMode: RetinaMode.isHighDensity(context),
            ),
            const RichAttributionWidget(
              alignment: AttributionAlignment.bottomRight,
              showFlutterMapAttribution: false,
              attributions: [
                TextSourceAttribution('OpenStreetMap'),
                TextSourceAttribution('CARTO'),
              ],
            ),
            MarkerLayer(
              markers: [
                if (_selectedFilter == _MapFilter.friends)
                  for (final friend in _mapFriends)
                    Marker(
                      point: _friendPoint(friend),
                      width: friend.hasCheckIn
                          ? HomeMapCheckInMarker.width
                          : 96,
                      height: friend.hasCheckIn
                          ? HomeMapCheckInMarker.height
                          : 100,
                      alignment: friend.hasCheckIn
                          ? Alignment.center
                          : Alignment.topCenter,
                      child: _animatedMarker(
                        GestureDetector(
                          onTap: () => _onFriendTap(friend),
                          behavior: HitTestBehavior.opaque,
                          child: friend.hasCheckIn
                              ? HomeMapCheckInMarker.fromFriend(friend)
                              : HomeMapMarker(friend: friend),
                        ),
                      ),
                    ),
                if (_selectedFilter == _MapFilter.nearby)
                  for (var i = 0; i < _nearbyAnons.length; i++)
                    Marker(
                      point: _friendPoint(_nearbyAnons[i]),
                      width: 180,
                      height: 120,
                      alignment: Alignment.topCenter,
                      child: _animatedMarker(
                        HomeMapAnonMarker(
                          user: _nearbyAnons[i],
                          expanded: _expandedAnonIndex == i,
                          onTap: () => _onAnonTap(i),
                        ),
                      ),
                    ),
                if (_selectedFilter == _MapFilter.venues)
                  for (final venue in _venues)
                    Marker(
                      point: _venuePoint(venue),
                      width: 1,
                      height: 1,
                      alignment: Alignment.center,
                      child: IgnorePointer(
                        child: OverflowBox(
                          maxWidth: 320,
                          maxHeight: 80,
                          child: _animatedMarker(
                            HomeMapVenueMarker(venue: venue),
                          ),
                        ),
                      ),
                    ),
                Marker(
                  point: _userLocation,
                  width: HomeMapTitleMarker.width,
                  height: HomeMapTitleMarker.height,
                  alignment: Alignment.center,
                  child: ValueListenableBuilder<ActiveMapCheckIn?>(
                    valueListenable:
                        getIt<UserRepository>().activeMapCheckInListenable,
                    builder: (context, activeCheckIn, _) {
                      final Widget marker;
                      if (activeCheckIn == null) {
                        marker = Center(
                          child: ValueListenableBuilder<UserProfile?>(
                            valueListenable:
                                getIt<UserRepository>().currentUserListenable,
                            builder: (context, user, _) {
                              final path =
                                  user?.hasPhoto == true ? user!.avatarPath : '';
                              return Container(
                                width: HomeMapCheckInMarker.avatarSize,
                                height: HomeMapCheckInMarker.avatarSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.zoviOrange,
                                    width: HomeMapCheckInMarker.border,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x33000000),
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ProfileAvatar(
                                  path: path,
                                  size: HomeMapCheckInMarker.avatarSize -
                                      HomeMapCheckInMarker.border * 2,
                                ),
                              );
                            },
                          ),
                        );
                      } else if (activeCheckIn.hasTitle) {
                        marker = HomeMapTitleMarker.fromActive(activeCheckIn);
                      } else {
                        marker = Center(
                          child: SizedBox(
                            width: HomeMapCheckInMarker.width,
                            height: HomeMapCheckInMarker.height,
                            child: HomeMapCheckInMarker.fromActive(
                              activeCheckIn,
                            ),
                          ),
                        );
                      }
                      if (activeCheckIn == null) {
                        return IgnorePointer(child: marker);
                      }
                      return GestureDetector(
                        onTap: _onSelfTap,
                        behavior: HitTestBehavior.opaque,
                        child: marker,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        Positioned(
          top: 12,
          left: 16,
          child: Container(
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.zoviOrange, width: 2),
                  ),
                  child: ValueListenableBuilder<UserProfile?>(
                    valueListenable:
                        getIt<UserRepository>().currentUserListenable,
                    builder: (context, user, _) {
                      final path =
                          user?.hasPhoto == true ? user!.avatarPath : '';
                      return ProfileAvatar(path: path, size: 20);
                    },
                  ),
                ),
                if (_cityLabel.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.25),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      _cityLabel,
                      key: ValueKey(_cityLabel),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ],
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 16,
          child: _MapFilterMenu(
            animation: _filterMenuController,
            selected: _selectedFilter,
            onToggle: _toggleFilterMenu,
            onSelect: _selectFilter,
          ),
        ),
        if (_friendSheetFriend != null || _lastCheckInSheet != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: friendSheetBottom,
            child: GestureDetector(
              onVerticalDragUpdate: _onSheetVerticalDragUpdate,
              onVerticalDragEnd: _onSheetVerticalDragEnd,
              behavior: HitTestBehavior.opaque,
              child: SlideTransition(
                position: _friendSheetSlide,
                child: FadeTransition(
                  opacity: _friendSheetFade,
                  child: _friendSheetFriend != null
                      ? HomeMapFriendSheet(
                          friend: _friendSheetFriend!,
                          onClose: () => unawaited(_closeFriendSheet()),
                          onSend: (text) => unawaited(_sendFriendMessage(text)),
                          onOpenProfile: () => unawaited(
                            openUserProfile(
                              context,
                              _friendSheetFriend!.name,
                            ),
                          ),
                        )
                      : HomeMapLastCheckInSheet(
                          checkIn: _lastCheckInSheet!,
                          onClose: () => unawaited(_closeFriendSheet()),
                        ),
                ),
              ),
            ),
          )
        else ...[
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
      ],
    );
  }
}

enum _MapFilter { nearby, friends, venues }

class _MapFilterMenu extends StatelessWidget {
  const _MapFilterMenu({
    required this.animation,
    required this.selected,
    required this.onToggle,
    required this.onSelect,
  });

  final AnimationController animation;
  final _MapFilter selected;
  final VoidCallback onToggle;
  final ValueChanged<_MapFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
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
        ),
        SizeTransition(
          sizeFactor: curved,
          axis: Axis.vertical,
          child: FadeTransition(
            opacity: curved,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.25),
                  end: Offset.zero,
                ).animate(curved),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _MapFilterLabel(
                            label: 'map_filter_nearby'.tr(),
                            selected: selected == _MapFilter.nearby,
                            onTap: () => onSelect(_MapFilter.nearby),
                          ),
                          const SizedBox(height: 18),
                          _MapFilterLabel(
                            label: 'map_filter_friends'.tr(),
                            selected: selected == _MapFilter.friends,
                            onTap: () => onSelect(_MapFilter.friends),
                          ),
                          const SizedBox(height: 18),
                          _MapFilterLabel(
                            label: 'map_filter_venues'.tr(),
                            selected: selected == _MapFilter.venues,
                            onTap: () => onSelect(_MapFilter.venues),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 10,
                      ),
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _MapFilterIconButton(
                            asset: AssetPaths.iconRadar,
                            selected: selected == _MapFilter.nearby,
                            onTap: () => onSelect(_MapFilter.nearby),
                          ),
                          const SizedBox(height: 14),
                          _MapFilterIconButton(
                            asset: AssetPaths.iconProfile6,
                            selected: selected == _MapFilter.friends,
                            onTap: () => onSelect(_MapFilter.friends),
                          ),
                          const SizedBox(height: 14),
                          _MapFilterIconButton(
                            asset: AssetPaths.iconLocationOutlined,
                            selected: selected == _MapFilter.venues,
                            onTap: () => onSelect(_MapFilter.venues),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MapFilterLabel extends StatelessWidget {
  const _MapFilterLabel({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.04 : 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 14 / 12,
              color: selected ? AppColors.zoviOrange : AppColors.black,
            ),
            child: Text(label, textAlign: TextAlign.right),
          ),
        ),
      ),
    );
  }
}

class _MapFilterIconButton extends StatelessWidget {
  const _MapFilterIconButton({
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  final String asset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: selected ? 1.14 : 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: TweenAnimationBuilder<Color?>(
          tween: ColorTween(
            end: selected ? AppColors.zoviOrange : AppColors.deepRoast,
          ),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          builder: (context, color, _) {
            return AppIcon(asset, size: 24, color: color);
          },
        ),
      ),
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
