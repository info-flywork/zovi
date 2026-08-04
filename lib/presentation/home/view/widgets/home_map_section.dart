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
  static const _fallbackCenter = LatLng(41.0082, 28.9784);
  static const _defaultZoom = 16.0;

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
  double _mapZoom = _defaultZoom;
  static const _distance = Distance();
  /// Zoom’a göre marker’ların “çakışma” eşiği (metre).
  static const _spiderfyZoom = 16.8;

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
    getIt<UserRepository>().mapFriendsListenable.addListener(
      _onMapFriendsChanged,
    );
    getIt<UserRepository>().activeMapCheckInListenable.addListener(
      _onActiveCheckInChanged,
    );
  }

  void _onActiveCheckInChanged() {
    if (mounted) setState(() {});
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
        final match = friends.where(
          (f) =>
              (openFriend.userId.isNotEmpty && f.userId == openFriend.userId) ||
              f.name == openFriend.name,
        );
        _friendSheetFriend = match.isEmpty ? openFriend : match.first;
      }
      if (selectedFriend != null) {
        final match = friends.where(
          (f) =>
              (selectedFriend.userId.isNotEmpty &&
                  f.userId == selectedFriend.userId) ||
              f.name == selectedFriend.name,
        );
        _selectedFriend = match.isEmpty ? selectedFriend : match.first;
      }
    });
  }

  Future<void> _loadNearbyAnons() async {
    final items = await getIt<UserRepository>().getMapNearbyAnons(
      lat: _hasRealLocation ? _userLocation.latitude : null,
      lng: _hasRealLocation ? _userLocation.longitude : null,
    );
    if (!mounted) return;
    setState(() => _nearbyAnons = items);
  }

  Future<void> _loadVenues() async {
    final items = await getIt<UserRepository>().getMapVenues(
      lat: _hasRealLocation ? _userLocation.latitude : null,
      lng: _hasRealLocation ? _userLocation.longitude : null,
    );
    if (!mounted) return;
    setState(() => _venues = items);
  }

  @override
  void dispose() {
    getIt<UserRepository>().mapFriendsListenable.removeListener(
      _onMapFriendsChanged,
    );
    getIt<UserRepository>().activeMapCheckInListenable.removeListener(
      _onActiveCheckInChanged,
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
    final text = message.trim();
    if (text.isEmpty) return;
    if (friend.userId.isEmpty) return;

    // Sheet kapanmasını / API’yi beklemeden banner’ı hemen göster.
    unawaited(_closeFriendSheet());
    AppInAppNotification.instance.show(
      InAppNotificationData(
        username: friend.profileHandle,
        messageKey: 'map_friend_message_sent',
        avatarPath: friend.avatarPath,
        displayName: friend.name,
        showGradientRing: true,
      ),
    );

    try {
      final chat = getIt<ChatRepository>();
      final conversation = await chat.openDm(friend.userId);
      await chat.sendMessage(
        conversationId: conversation.id,
        type: 'text',
        body: text,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.instance.show(
        context,
        'error_save_profile_failed'.tr(),
        isError: true,
      );
    }
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
    if (state != AppLifecycleState.resumed) return;
    if (!_hasRealLocation) {
      unawaited(_resolveUserLocation(animate: true));
      return;
    }
    unawaited(
      getIt<UserRepository>().syncMapPresence(
        lat: _userLocation.latitude,
        lng: _userLocation.longitude,
        locationLabel: _cityLabel.isEmpty ? null : _cityLabel,
      ),
    );
    unawaited(_loadNearbyAnons());
    unawaited(_loadVenues());
  }

  LatLng _friendPoint(MapFriend friend) {
    if (friend.lat != 0 || friend.lng != 0) {
      return LatLng(friend.lat, friend.lng);
    }
    return LatLng(
      _userLocation.latitude + friend.y * 0.02,
      _userLocation.longitude + friend.x * 0.02,
    );
  }

  double _clusterThresholdMeters(double zoom) {
    // Zoom 14 ≈ 70m, 16 ≈ 25m, 18 ≈ 10m — büyük check-in marker’lara göre.
    final meters = 70 * math.pow(2, 14 - zoom);
    return meters.clamp(10.0, 90.0).toDouble();
  }

  List<_MapPinItem> _friendLayerPins() {
    final pins = <_MapPinItem>[
      for (final friend in _mapFriends)
        _MapPinItem.friend(friend: friend, point: _friendPoint(friend)),
    ];
    final selfCheckIn = getIt<UserRepository>().activeMapCheckIn;
    final selfAvatar =
        getIt<UserRepository>().currentUserListenable.value?.hasPhoto == true
        ? getIt<UserRepository>().currentUserListenable.value!.avatarPath
        : '';
    pins.add(
      _MapPinItem.self(
        point: _userLocation,
        checkIn: selfCheckIn,
        avatarPath: selfAvatar,
      ),
    );
    return pins;
  }

  List<_MapPinCluster> _clusterPins(List<_MapPinItem> pins, double zoom) {
    final threshold = _clusterThresholdMeters(zoom);
    final used = List<bool>.filled(pins.length, false);
    final clusters = <_MapPinCluster>[];

    for (var i = 0; i < pins.length; i++) {
      if (used[i]) continue;
      used[i] = true;
      final members = <_MapPinItem>[pins[i]];
      for (var j = i + 1; j < pins.length; j++) {
        if (used[j]) continue;
        final meters = _distance.as(
          LengthUnit.Meter,
          pins[i].point,
          pins[j].point,
        );
        if (meters <= threshold) {
          used[j] = true;
          members.add(pins[j]);
        }
      }
      final lat =
          members.map((m) => m.point.latitude).reduce((a, b) => a + b) /
          members.length;
      final lng =
          members.map((m) => m.point.longitude).reduce((a, b) => a + b) /
          members.length;
      clusters.add(
        _MapPinCluster(center: LatLng(lat, lng), members: members),
      );
    }
    return clusters;
  }

  LatLng _spiderfyPoint({
    required LatLng center,
    required int index,
    required int total,
    required double zoom,
  }) {
    if (!_mapReady || total <= 1) return center;
    try {
      final camera = _mapController.camera;
      final centerPx = camera.projectAtZoom(center, zoom);
      final angle = (2 * math.pi * index / total) - (math.pi / 2);
      final radius = 52.0 + (total > 4 ? 8.0 : 0.0);
      final offset = Offset(
        centerPx.dx + math.cos(angle) * radius,
        centerPx.dy + math.sin(angle) * radius,
      );
      return camera.unprojectAtZoom(offset, zoom);
    } catch (_) {
      return center;
    }
  }

  List<Marker> _buildFriendLayerMarkers() {
    final clusters = _clusterPins(_friendLayerPins(), _mapZoom);
    final markers = <Marker>[];

    for (final cluster in clusters) {
      if (cluster.members.length == 1) {
        markers.add(_markerForPin(cluster.members.first, cluster.center));
        continue;
      }

      if (_mapZoom >= _spiderfyZoom) {
        for (var i = 0; i < cluster.members.length; i++) {
          final point = _spiderfyPoint(
            center: cluster.center,
            index: i,
            total: cluster.members.length,
            zoom: _mapZoom,
          );
          markers.add(_markerForPin(cluster.members[i], point));
        }
        continue;
      }

      markers.add(
        Marker(
          point: cluster.center,
          width: HomeMapClusterMarker.width,
          height: HomeMapClusterMarker.height,
          alignment: Alignment.center,
          child: _animatedMarker(
            GestureDetector(
              onTap: () => _onClusterTap(cluster),
              behavior: HitTestBehavior.opaque,
              child: HomeMapClusterMarker(
                avatarPaths: [
                  for (final m in cluster.members) m.avatarPath,
                ],
                count: cluster.members.length,
              ),
            ),
          ),
        ),
      );
    }
    return markers;
  }

  Marker _markerForPin(_MapPinItem pin, LatLng point) {
    if (pin.isSelf) {
      return Marker(
        point: point,
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
                  child: HomeMapCheckInMarker.fromActive(activeCheckIn),
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
      );
    }

    final friend = pin.friend!;
    return Marker(
      point: point,
      width: friend.hasCheckIn ? HomeMapCheckInMarker.width : 96,
      height: friend.hasCheckIn ? HomeMapCheckInMarker.height : 100,
      alignment: friend.hasCheckIn ? Alignment.center : Alignment.topCenter,
      child: _animatedMarker(
        GestureDetector(
          onTap: () => _onFriendTap(friend),
          behavior: HitTestBehavior.opaque,
          child: friend.hasCheckIn
              ? HomeMapCheckInMarker.fromFriend(friend)
              : HomeMapMarker(friend: friend),
        ),
      ),
    );
  }

  Future<void> _onClusterTap(_MapPinCluster cluster) async {
    if (_filterMenuOpen) _closeFilterMenu();
    // Önce yakınlaştır; yeterince yakınsa seçim listesi aç.
    if (_mapZoom < _spiderfyZoom - 0.15) {
      final targetZoom = math.max(_mapZoom + 1.8, _spiderfyZoom + 0.2);
      await _animateTo(
        cluster.center,
        zoom: targetZoom.clamp(_mapZoom, 18.5),
        duration: const Duration(milliseconds: 480),
      );
      if (!mounted) return;
      setState(() => _mapZoom = _mapController.camera.zoom);
      return;
    }
    await _showClusterPicker(cluster);
  }

  Future<void> _showClusterPicker(_MapPinCluster cluster) async {
    final picked = await showModalBottomSheet<_MapPinItem>(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.progressInactive,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'map_cluster_title'.tr(
                    namedArgs: {'count': '${cluster.members.length}'},
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 12),
                for (final member in cluster.members)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ProfileAvatar(
                      path: member.avatarPath,
                      size: 44,
                      showGradientRing: true,
                      ringWidth: 2,
                    ),
                    title: Text(
                      member.isSelf
                          ? 'map_cluster_you'.tr()
                          : (member.friend?.name ?? 'user'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      member.isSelf
                          ? (member.checkIn?.placeName ?? '')
                          : (member.friend?.checkIn?.placeName ??
                                member.friend?.locationLabel ??
                                ''),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => Navigator.of(context).pop(member),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || picked == null) return;
    if (picked.isSelf) {
      _onSelfTap();
    } else if (picked.friend != null) {
      _onFriendTap(picked.friend!);
    }
  }

  LatLng _venuePoint(MapVenue venue) {
    if (venue.lat != 0 || venue.lng != 0) {
      return LatLng(venue.lat, venue.lng);
    }
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
      // City + region when available — matches the own-profile live label.
      final syncLabel = [
        place.locality,
        place.administrativeArea ?? place.country,
      ]
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .take(2)
          .join(', ');
      if (syncLabel.isNotEmpty) {
        unawaited(getIt<UserRepository>().syncLiveLocationLabel(syncLabel));
      }
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

      final accuracy = position.accuracy;
      unawaited(_updateCityLabel(target).then((_) async {
        if (!mounted) return;
        await getIt<UserRepository>().syncMapPresence(
          lat: target.latitude,
          lng: target.longitude,
          accuracyM: accuracy,
          locationLabel: _cityLabel.isEmpty ? null : _cityLabel,
        );
      }));
      unawaited(_loadNearbyAnons());
      unawaited(_loadVenues());
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
        RepaintBoundary(
          child: FlutterMap(
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
              _mapZoom = _mapController.camera.zoom;
              _moveCamera(_userLocation, _defaultZoom);
            },
            onMapEvent: (event) {
              if (event is MapEventMoveEnd ||
                  event is MapEventScrollWheelZoom ||
                  event is MapEventDoubleTapZoom) {
                final zoom = _mapController.camera.zoom;
                if ((zoom - _mapZoom).abs() >= 0.08 && mounted) {
                  setState(() => _mapZoom = zoom);
                }
              }
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
                  ..._buildFriendLayerMarkers(),
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
                if (_selectedFilter != _MapFilter.friends)
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
                              _friendSheetFriend!.username.isNotEmpty
                                  ? _friendSheetFriend!.username
                                  : _friendSheetFriend!.name,
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
            ? const AppLoading(
                size: 24,
                strokeWidth: 2.5,
                color: AppColors.mintGreen,
                centered: false,
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

class _MapPinItem {
  const _MapPinItem._({
    required this.point,
    required this.avatarPath,
    this.friend,
    this.checkIn,
  });

  factory _MapPinItem.friend({
    required MapFriend friend,
    required LatLng point,
  }) {
    return _MapPinItem._(
      point: point,
      friend: friend,
      avatarPath: friend.avatarPath,
      checkIn: null,
    );
  }

  factory _MapPinItem.self({
    required LatLng point,
    required String avatarPath,
    ActiveMapCheckIn? checkIn,
  }) {
    return _MapPinItem._(
      point: point,
      avatarPath: avatarPath,
      checkIn: checkIn,
    );
  }

  final LatLng point;
  final String avatarPath;
  final MapFriend? friend;
  final ActiveMapCheckIn? checkIn;

  bool get isSelf => friend == null;
}

class _MapPinCluster {
  const _MapPinCluster({
    required this.center,
    required this.members,
  });

  final LatLng center;
  final List<_MapPinItem> members;
}
