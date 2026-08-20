part of '../home_view.dart';

@immutable
final class HomeMapSection extends StatefulWidget {
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

final class _HomeMapSectionState extends State<HomeMapSection>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const _fallbackCenter = LatLng(41.0082, 28.9784);
  static const _defaultZoom = 16.0;
  static const _venueLoadMinZoom = 14.8;
  static const _venueReloadDistanceMeters = 280.0;
  static const _venueReloadZoomDelta = 0.35;

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
  _MapFilter _selectedFilter = _MapFilter.nearby;
  bool _venueZoomHintDismissed = false;
  List<MapFriend> _nearbyAnons = const [];
  List<MapVenue> _venues = const [];
  static const _peopleReloadDistanceMeters = 220.0;
  static const _peopleReloadZoomDelta = 0.4;
  LatLng? _lastPeopleFetchCenter;
  double? _lastPeopleFetchZoom;
  LatLng? _lastVenueFetchCenter;
  double? _lastVenueFetchZoom;
  Timer? _venuesDebounce;
  Timer? _peopleDebounce;
  bool _venuesLoading = false;
  MapFriend? _selectedFriend;
  MapVenue? _selectedVenue;
  MapFriend? _friendSheetFriend;
  ActiveMapCheckIn? _lastCheckInSheet;
  int _sheetPresentGeneration = 0;
  int _venuePresentGeneration = 0;
  AnimationController? _cameraAnimation;
  late final AnimationController _friendSheetController;
  late final Animation<Offset> _friendSheetSlide;
  late final Animation<double> _friendSheetFade;
  late final AnimationController _venueSheetController;
  late final Animation<Offset> _venueSheetSlide;
  late final Animation<double> _venueSheetFade;
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
    _venueSheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _venueSheetSlide =
        Tween<Offset>(begin: const Offset(0, 0.42), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _venueSheetController,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );
    _venueSheetFade = CurvedAnimation(
      parent: _venueSheetController,
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
      final selectedVenue = _selectedVenue;
      if (selectedVenue != null) {
        final stillVisible = _venues.any(
          (v) =>
              v.name == selectedVenue.name &&
              (v.lat - selectedVenue.lat).abs() < 0.0001 &&
              (v.lng - selectedVenue.lng).abs() < 0.0001,
        );
        if (!stillVisible) _selectedVenue = null;
      }
    });
  }

  double _radiusKmForZoom(double zoom) {
    final km = 50 * math.pow(2, 14.5 - zoom);
    return km.clamp(50.0, 20000.0).toDouble();
  }

  MapFriend _withLiveDistance(MapFriend person) {
    if (!_hasRealLocation || (person.lat == 0 && person.lng == 0)) {
      return person;
    }
    final meters = _distance
        .as(
          LengthUnit.Meter,
          _userLocation,
          LatLng(person.lat, person.lng),
        )
        .round();
    return person.copyWith(distanceMeters: meters);
  }

  Future<void> _loadNearbyAnons({LatLng? center, double? radiusKm}) async {
    final items = await getIt<UserRepository>().getMapNearbyAnons(
      lat: center?.latitude ??
          (_hasRealLocation ? _userLocation.latitude : null),
      lng: center?.longitude ??
          (_hasRealLocation ? _userLocation.longitude : null),
      radiusKm: radiusKm ?? 50,
    );
    if (!mounted) return;
    final visible = [
      for (final item in items)
        if (item.isAnonymous || item.avatarPath.trim().isNotEmpty)
          _withLiveDistance(item),
    ];
    final same = visible.length == _nearbyAnons.length &&
        [
          for (var i = 0; i < visible.length; i++)
            visible[i].userId == _nearbyAnons[i].userId &&
                visible[i].isAnonymous == _nearbyAnons[i].isAnonymous &&
                visible[i].hasCheckIn == _nearbyAnons[i].hasCheckIn &&
                (visible[i].checkIn?.stampImagePath ?? '') ==
                    (_nearbyAnons[i].checkIn?.stampImagePath ?? ''),
        ].every((ok) => ok);
    if (same) return;
    setState(() => _nearbyAnons = visible);
  }

  void _schedulePeopleRefresh({bool force = false}) {
    if (!_mapReady) return;
    _peopleDebounce?.cancel();
    _peopleDebounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      unawaited(_refreshPeopleAtCamera(force: force));
    });
  }

  Future<void> _refreshPeopleAtCamera({bool force = false}) async {
    if (!_mapReady) return;
    final cam = _mapController.camera;
    if (!force) {
      final movedEnough = _lastPeopleFetchCenter == null
          ? true
          : _distance.as(
                  LengthUnit.Meter,
                  _lastPeopleFetchCenter!,
                  cam.center,
                ) >=
                _peopleReloadDistanceMeters;
      final zoomChangedEnough = _lastPeopleFetchZoom == null
          ? true
          : (cam.zoom - _lastPeopleFetchZoom!).abs() >= _peopleReloadZoomDelta;
      if (!movedEnough && !zoomChangedEnough) return;
    }
    _lastPeopleFetchCenter = cam.center;
    _lastPeopleFetchZoom = cam.zoom;
    final radiusKm = _radiusKmForZoom(cam.zoom);
    if (_selectedFilter == _MapFilter.nearby) {
      await _loadNearbyAnons(center: cam.center, radiusKm: radiusKm);
      return;
    }
    if (_selectedFilter == _MapFilter.friends) {
      await getIt<UserRepository>().getMapFriends(
        lat: cam.center.latitude,
        lng: cam.center.longitude,
        radiusKm: radiusKm,
      );
    }
  }

  Future<void> _loadVenues({
    required LatLng center,
    required double zoom,
    bool force = false,
  }) async {
    final movedEnough = _lastVenueFetchCenter == null
        ? true
        : _distance.as(LengthUnit.Meter, _lastVenueFetchCenter!, center) >=
              _venueReloadDistanceMeters;
    final zoomChangedEnough = _lastVenueFetchZoom == null
        ? true
        : (zoom - _lastVenueFetchZoom!).abs() >= _venueReloadZoomDelta;

    if (!force && !movedEnough && !zoomChangedEnough) return;

    _venuesLoading = true;
    final items = await getIt<UserRepository>().getMapVenues(
      lat: center.latitude,
      lng: center.longitude,
    );
    if (!mounted) return;
    setState(() {
      _venuesLoading = false;
      _lastVenueFetchCenter = center;
      _lastVenueFetchZoom = zoom;
      _venues = items;
      final selectedVenue = _selectedVenue;
      if (selectedVenue != null) {
        final refreshed = items.where(
          (v) =>
              v.name == selectedVenue.name &&
              (v.lat - selectedVenue.lat).abs() < 0.0001 &&
              (v.lng - selectedVenue.lng).abs() < 0.0001,
        );
        _selectedVenue = refreshed.isEmpty ? null : refreshed.first;
      }
    });
  }

  void _scheduleVenueRefresh({bool force = false}) {
    if (_selectedFilter != _MapFilter.venues || !_mapReady) return;
    if (_venuesLoading && !force) return;
    final zoom = _mapController.camera.zoom;
    if (!force && zoom < _venueLoadMinZoom) return;
    final center = _mapController.camera.center;
    _venuesDebounce?.cancel();
    _venuesDebounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      unawaited(_loadVenues(center: center, zoom: zoom, force: force));
    });
  }

  bool get _shouldHideVenuesByZoom => _mapZoom < _venueLoadMinZoom;

  bool get _showVenueZoomHint =>
      _selectedFilter == _MapFilter.venues &&
      _shouldHideVenuesByZoom &&
      !_venueZoomHintDismissed;

  String _normalizeVenueText(String value) {
    final lower = value.toLowerCase().trim();
    final compact = lower.replaceAll(RegExp(r'\s+'), ' ');
    return compact.replaceAll(RegExp(r'[^a-z0-9çğıöşü ]', unicode: true), '');
  }

  int _venueFriendCount(MapVenue venue) {
    final venuePoint = _venuePoint(venue);
    final venueName = _normalizeVenueText(venue.name);
    final seen = <String>{};
    var count = 0;

    for (final friend in _mapFriends) {
      if (!friend.isFriend || !friend.hasCheckIn) continue;
      final friendPlace = _normalizeVenueText(friend.checkIn?.placeName ?? '');
      final nameMatches = friendPlace.isNotEmpty && friendPlace == venueName;
      final meters = _distance.as(
        LengthUnit.Meter,
        venuePoint,
        _friendPoint(friend),
      );
      final nearEnough = meters <= 120;
      if (!nameMatches && !nearEnough) continue;

      final key = friend.userId.isNotEmpty ? friend.userId : friend.name;
      if (seen.add(key)) count++;
    }
    return count;
  }

  List<MapVenue> _venuesWithFriendCounts() {
    if (_venues.isEmpty) return const [];
    return [
      for (final venue in _venues)
        MapVenue(
          name: venue.name,
          peopleCount: _venueFriendCount(venue),
          lat: venue.lat,
          lng: venue.lng,
          photoPath: venue.photoPath,
          x: venue.x,
          y: venue.y,
        ),
    ];
  }

  String? _venuePreviewPhoto(MapVenue venue) {
    final direct = (venue.photoPath ?? '').trim();
    if (direct.isNotEmpty) return direct;
    final venueName = _normalizeVenueText(venue.name);
    final venuePoint = _venuePoint(venue);
    for (final friend in _mapFriends) {
      if (!friend.hasCheckIn) continue;
      final photos = friend.checkIn?.photoPaths ?? const <String>[];
      if (photos.isEmpty) continue;
      final friendPlace = _normalizeVenueText(friend.checkIn?.placeName ?? '');
      final meters = _distance.as(
        LengthUnit.Meter,
        venuePoint,
        _friendPoint(friend),
      );
      final nameMatches = friendPlace.isNotEmpty && friendPlace == venueName;
      if (!nameMatches && meters > 120) continue;
      final first = photos.firstWhere(
        (p) => p.trim().isNotEmpty,
        orElse: () => '',
      );
      if (first.isNotEmpty) return first;
    }
    return null;
  }

  List<MapVenue> _compactVenueLabels() {
    final source = _venuesWithFriendCounts();
    if (!_mapReady || source.isEmpty) return source;
    final zoom = _mapController.camera.zoom;
    final camera = _mapController.camera;
    final viewport = camera.visibleBounds;
    final labelGap = (92 - ((zoom - 15.5) * 10)).clamp(54, 96).toDouble();
    final maxCount = (18 + ((zoom - 15) * 8)).clamp(18, 40).toInt();
    final placed = <Offset>[];
    final output = <MapVenue>[];

    for (final venue in source) {
      if (output.length >= maxCount) break;
      final point = _venuePoint(venue);
      if (!viewport.contains(point)) continue;
      final px = camera.projectAtZoom(point, zoom);
      var collide = false;
      for (final prev in placed) {
        if ((prev - px).distance < labelGap) {
          collide = true;
          break;
        }
      }
      if (collide) continue;
      placed.add(px);
      output.add(venue);
    }
    return output;
  }

  List<Marker> _buildVenueMarkers() {
    return [
      for (final venue in _compactVenueLabels())
        Marker(
          point: _venuePoint(venue),
          width: 300,
          height: 88,
          alignment: Alignment.center,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _onVenueTap(venue),
            child: Center(
              child: _animatedMarker(HomeMapVenueMarker(venue: venue)),
            ),
          ),
        ),
    ];
  }

  void _onVenueTap(MapVenue venue) {
    unawaited(_presentVenueSheet(venue));
  }

  Future<void> _presentVenueSheet(MapVenue venue) async {
    final generation = ++_venuePresentGeneration;
    FocusManager.instance.primaryFocus?.unfocus();
    final wasOpen = _venueSheetController.value > 0 && _selectedVenue != null;
    if (wasOpen) {
      await _venueSheetController.reverse();
      if (!mounted || generation != _venuePresentGeneration) return;
    }
    if (_filterMenuOpen) _closeFilterMenu();
    setState(() {
      _selectedFriend = null;
      _lastCheckInSheet = null;
      _friendSheetFriend = null;
      _selectedVenue = venue;
    });
    _friendSheetController.value = 0;
    await _venueSheetController.forward(from: 0);
  }

  Future<void> _closeVenueSheet() async {
    if (_selectedVenue == null) return;
    _venuePresentGeneration++;
    FocusManager.instance.primaryFocus?.unfocus();
    await _venueSheetController.reverse();
    if (!mounted) return;
    if (_selectedVenue != null) {
      setState(() => _selectedVenue = null);
    }
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
    _venueSheetController.dispose();
    _markersFade.dispose();
    _markersScaleCurve.dispose();
    _markersController.dispose();
    _cameraAnimation?.dispose();
    _venuesDebounce?.cancel();
    _peopleDebounce?.cancel();
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
        _selectedFriend = null;
        _selectedVenue = null;
        _friendSheetFriend = null;
        if (filter != _MapFilter.venues) {
          _venueZoomHintDismissed = false;
        }
      });
      if (filter == _MapFilter.venues) {
        _scheduleVenueRefresh(force: true);
      }
      if (filter == _MapFilter.nearby || filter == _MapFilter.friends) {
        unawaited(_refreshPeopleAtCamera(force: true));
      }
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

  void _onFriendTap(MapFriend friend) {
    if (_filterMenuOpen) {
      _closeFilterMenu();
    }

    // Anonim pin: sadece harita balonunu aç/kapat, alt sheet gösterme.
    if (friend.isAnonymous) {
      final alreadySelected =
          _selectedFriend?.userId.isNotEmpty == true &&
          _selectedFriend!.userId == friend.userId;
      final next = alreadySelected ? null : friend;
      final hasSheet =
          _friendSheetFriend != null || _lastCheckInSheet != null;

      void apply() {
        _selectedVenue = null;
        _friendSheetFriend = null;
        _lastCheckInSheet = null;
        _selectedFriend = next;
      }

      if (hasSheet && _friendSheetController.value > 0) {
        _sheetPresentGeneration++;
        FocusManager.instance.primaryFocus?.unfocus();
        unawaited(() async {
          await _friendSheetController.reverse();
          if (!mounted) return;
          setState(apply);
        }());
      } else {
        setState(apply);
      }
      return;
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
          _selectedVenue = null;
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
          _selectedFriend = null;
          _selectedVenue = null;
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
    final hasSheet = _friendSheetFriend != null || _lastCheckInSheet != null;
    final hasAnonSelection =
        _selectedFriend != null && _selectedFriend!.isAnonymous;
    if (!hasSheet && !hasAnonSelection) return;
    _sheetPresentGeneration++;
    FocusManager.instance.primaryFocus?.unfocus();
    if (_selectedFriend != null) {
      setState(() => _selectedFriend = null);
    }
    if (!hasSheet) return;
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
    unawaited(_closeVenueSheet());
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
    unawaited(_refreshPeopleAtCamera(force: true));
    _scheduleVenueRefresh(force: true);
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

  /// Prefer card below the question mark; open above when something sits in
  /// the below footprint (self pin or another nearby person).
  bool _anonCardShouldOpenAbove(MapFriend person) {
    if (!_mapReady) return false;
    final camera = _mapController.camera;
    final zoom = camera.zoom;
    final origin = camera.projectAtZoom(_friendPoint(person), zoom);

    const cardH = HomeMapAnonMarker.cardSlot;
    const cardHalfW = 90.0;
    const questionHalf = HomeMapAnonMarker.questionSize / 2;

    bool blocksBelow(Offset other, double radius) {
      final dx = (other.dx - origin.dx).abs();
      final dy = other.dy - origin.dy;
      // Only care about markers sitting under the question mark.
      if (dy < questionHalf * 0.4) return false;
      if (dy > questionHalf + cardH + 24) return false;
      if (dx > cardHalfW + radius) return false;
      return true;
    }

    final selfPx = camera.projectAtZoom(_userLocation, zoom);
    if (blocksBelow(selfPx, 36)) return true;

    for (final other in _nearbyAnons) {
      if (other.userId == person.userId) continue;
      final px = camera.projectAtZoom(_friendPoint(other), zoom);
      if (blocksBelow(px, 28)) return true;
    }
    return false;
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

  Marker _nearbyPersonMarker(MapFriend person) {
    if (person.isAnonymous) {
      final expanded =
          _selectedFriend?.userId.isNotEmpty == true &&
          _selectedFriend!.userId == person.userId;
      final openAbove = expanded && _anonCardShouldOpenAbove(person);
      return Marker(
        point: _friendPoint(person),
        width: HomeMapAnonMarker.width,
        height: HomeMapAnonMarker.height,
        alignment: Alignment.center,
        child: HomeMapAnonMarker(
          key: ValueKey('anon-${person.userId}'),
          user: person,
          viewerLocation: _userLocation,
          expanded: expanded,
          openAbove: openAbove,
          onTap: () => _onFriendTap(person),
        ),
      );
    }

    final friendHasPhoto = HomeMapCheckInMarker.hasDistinctCheckInPhoto(
      photoPaths: person.checkIn?.photoPaths ?? const [],
      avatarPath: person.avatarPath,
    );
    return Marker(
      point: _friendPoint(person),
      width: person.hasCheckIn
          ? HomeMapCheckInMarker.widthFor(hasPhoto: friendHasPhoto)
          : 96,
      height: person.hasCheckIn ? HomeMapCheckInMarker.height : 100,
      alignment: person.hasCheckIn ? Alignment.center : Alignment.topCenter,
      child: KeyedSubtree(
        key: ValueKey('near-${person.userId}'),
        child: GestureDetector(
          onTap: () => _onFriendTap(person),
          behavior: HitTestBehavior.opaque,
          child: person.hasCheckIn
              ? HomeMapCheckInMarker.fromFriend(person)
              : HomeMapMarker(friend: person),
        ),
      ),
    );
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
    final friendHasPhoto = HomeMapCheckInMarker.hasDistinctCheckInPhoto(
      photoPaths: friend.checkIn?.photoPaths ?? const [],
      avatarPath: friend.avatarPath,
    );
    return Marker(
      point: point,
      width: friend.hasCheckIn
          ? HomeMapCheckInMarker.widthFor(hasPhoto: friendHasPhoto)
          : 96,
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
                          : (member.friend?.mapLabel ?? 'user'),
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
      unawaited(_refreshPeopleAtCamera(force: true));
      _scheduleVenueRefresh(force: true);
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
              _scheduleVenueRefresh(force: true);
              _schedulePeopleRefresh();
            },
            onMapEvent: (event) {
              if (event is MapEventMoveEnd ||
                  event is MapEventScrollWheelZoom ||
                  event is MapEventDoubleTapZoom) {
                final zoom = _mapController.camera.zoom;
                if ((zoom - _mapZoom).abs() >= 0.08 && mounted) {
                  setState(() {
                    _mapZoom = zoom;
                    // Yeterince yakınlaşınca ipucunu tekrar gösterilebilir hale al.
                    if (zoom >= _venueLoadMinZoom) {
                      _venueZoomHintDismissed = false;
                    }
                  });
                }
                _scheduleVenueRefresh();
                _schedulePeopleRefresh();
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
                  for (final person in _nearbyAnons)
                    _nearbyPersonMarker(person),
                if (_selectedFilter == _MapFilter.venues)
                  ...(_shouldHideVenuesByZoom ? const <Marker>[] : _buildVenueMarkers()),
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
                          viewerLocation: _userLocation,
                          onClose: () => unawaited(_closeFriendSheet()),
                          onSend: (text) => unawaited(_sendFriendMessage(text)),
                          onOpenProfile: () {
                            final friend = _friendSheetFriend!;
                            unawaited(
                              openUserProfile(
                                context,
                                friend.username.isNotEmpty
                                    ? friend.username
                                    : friend.name,
                                userId: friend.userId,
                                seed: friend.isAnonymous
                                    ? PublicUserProfile.skeleton(
                                        username: 'user',
                                        name: friend.name,
                                        userId: friend.userId,
                                      )
                                    : null,
                              ),
                            );
                          },
                        )
                      : HomeMapLastCheckInSheet(
                          checkIn: _lastCheckInSheet!,
                          onClose: () => unawaited(_closeFriendSheet()),
                        ),
                ),
              ),
            ),
          )
        else if (_selectedVenue != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: friendSheetBottom,
            child: SlideTransition(
              position: _venueSheetSlide,
              child: FadeTransition(
                opacity: _venueSheetFade,
                child: HomeMapVenueSheet(
                  venue: _selectedVenue!,
                  photoPath: _venuePreviewPhoto(_selectedVenue!),
                  onClose: () => unawaited(_closeVenueSheet()),
                ),
              ),
            ),
          )
        else if (_showVenueZoomHint)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                if (!mounted) return;
                setState(() => _venueZoomHintDismissed = true);
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                color: AppColors.black.withValues(alpha: 0.18),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppIcon(
                        AssetPaths.iconLocationOutlined,
                        size: 22,
                        color: AppColors.zoviOrange,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Mekanları görmek için biraz yakınlaştır.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.black.withValues(alpha: 0.84),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 20 / 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'İpucu ekranına dokunarak kapatabilirsin.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.black.withValues(alpha: 0.56),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 16 / 12,
                        ),
                      ),
                    ],
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

@immutable
final class _MapFilterMenu extends StatelessWidget {
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

@immutable
final class _MapFilterLabel extends StatelessWidget {
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

@immutable
final class _MapFilterIconButton extends StatelessWidget {
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

@immutable
final class _MapSendButton extends StatelessWidget {
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

@immutable
final class _MapAddButton extends StatelessWidget {
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

@immutable
final class _MapPinItem {
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

@immutable
final class _MapPinCluster {
  const _MapPinCluster({
    required this.center,
    required this.members,
  });

  final LatLng center;
  final List<_MapPinItem> members;
}
