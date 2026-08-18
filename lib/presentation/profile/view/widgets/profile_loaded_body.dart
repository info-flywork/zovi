part of '../profile_view.dart';

@immutable
final class ProfileLoadedBody extends StatefulWidget {
  const ProfileLoadedBody({
    required this.user,
    required this.checkIns,
    required this.pulses,
    required this.stamps,
    required this.plans,
    required this.tabController,
    required this.onTabSelected,
    this.sectionsReady = true,
    super.key,
  });

  final UserProfile user;
  final List<CheckInItem> checkIns;
  final List<PulseItem> pulses;
  final List<StampItem> stamps;
  final List<PlanItem> plans;
  final bool sectionsReady;
  final TabController tabController;
  final ValueChanged<ProfileContentTab> onTabSelected;

  @override
  State<ProfileLoadedBody> createState() => _ProfileLoadedBodyState();
}

final class _ProfileLoadedBodyState extends State<ProfileLoadedBody> {
  static const _fallbackCenter = LatLng(34.0522, -118.2437);

  final _scrollController = ScrollController();
  final _tabsSectionKey = GlobalKey();
  var _scrollGeneration = 0;

  String? _liveLocation;
  LatLng _mapPoint = _fallbackCenter;
  var _hasRealLocation = false;

  UserProfile get user => widget.user;

  @override
  void initState() {
    super.initState();
    _resolveLiveLocation();
  }

  @override
  void dispose() {
    _cancelPendingScroll();
    _scrollController.dispose();
    super.dispose();
  }

  void _cancelPendingScroll() {
    _scrollGeneration++;
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.isScrollingNotifier.value) {
      position.jumpTo(position.pixels);
    }
  }

  void _scrollToCheckInTab() {
    widget.onTabSelected(ProfileContentTab.checkIn);
    final generation = ++_scrollGeneration;
    _attemptScrollToTabs(generation);
  }

  bool _isTabsSectionVisible() {
    final targetContext = _tabsSectionKey.currentContext;
    if (targetContext == null) return false;

    final box = targetContext.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return false;

    final topLeft = box.localToGlobal(Offset.zero);
    final bottom = topLeft.dy + box.size.height;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset =
        MainWrapper.navBarHeight + MediaQuery.paddingOf(context).bottom;

    return bottom > topInset && topLeft.dy < screenHeight - bottomInset;
  }

  void _attemptScrollToTabs(int generation, [int attempt = 0]) {
    if (!mounted || generation != _scrollGeneration) return;
    if (attempt > 12) return;

    final scrolled = _runScrollToTabs(generation: generation);
    if (scrolled || _isTabsSectionVisible()) return;

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _attemptScrollToTabs(generation, attempt + 1),
    );
  }

  bool _runScrollToTabs({required int generation}) {
    if (!mounted || generation != _scrollGeneration) return false;
    if (!_scrollController.hasClients) return false;
    if (_isTabsSectionVisible()) return true;

    final targetContext = _tabsSectionKey.currentContext;
    if (targetContext == null) return false;

    final renderObject = targetContext.findRenderObject();
    if (renderObject == null || !renderObject.attached) return false;

    final maxExtent = _scrollController.position.maxScrollExtent;
    final viewport = RenderAbstractViewport.of(renderObject);
    var target = viewport
        .getOffsetToReveal(renderObject, 0)
        .offset
        .clamp(0.0, maxExtent);

    if ((_scrollController.offset - target).abs() < 1) {
      final box = renderObject as RenderBox;
      final topLeft = box.localToGlobal(Offset.zero);
      final topInset = MediaQuery.paddingOf(context).top;
      final delta = topLeft.dy - topInset;
      if (delta.abs() < 4) return false;
      target = (_scrollController.offset + delta).clamp(0.0, maxExtent);
    }

    if ((_scrollController.offset - target).abs() < 1) return false;

    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOut,
    );
    return true;
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

  Future<String?> _labelFor(LatLng point) async {
    try {
      final placemarks = await Geocoding().placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      if (placemarks.isEmpty) return null;
      final place = placemarks.first;
      final city = (place.locality ?? place.subLocality)?.trim();
      final region = (place.administrativeArea ?? place.country)?.trim();
      final parts = [
        city,
        region,
      ].whereType<String>().where((e) => e.isNotEmpty).toList();
      if (parts.isEmpty) return null;
      return parts.take(2).join(', ');
    } catch (_) {
      return null;
    }
  }

  Future<void> _resolveLiveLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      var position = await _readPosition();
      position ??= await Geolocator.getLastKnownPosition();
      if (position == null || !mounted) return;

      final point = LatLng(position.latitude, position.longitude);
      final label = await _labelFor(point);
      if (!mounted) return;

      setState(() {
        _mapPoint = point;
        _hasRealLocation = true;
        if (label != null && label.isNotEmpty) {
          _liveLocation = label;
        }
      });
      if (label != null && label.isNotEmpty) {
        unawaited(getIt<UserRepository>().syncLiveLocationLabel(label));
      }
    } catch (_) {
      // Fallback: mock user.location / default map center.
    }
  }

  static double _tabHeight({
    required int index,
    required double width,
    required int pulseCount,
    required int stampCount,
    required int checkInCount,
  }) {
    switch (index) {
      case 0:
        const spacing = 10.0;
        final itemWidth = (width - 32 - spacing * 2) / 3;
        final cardHeight = itemWidth * (200 / 126);
        final rows = (pulseCount / 3).ceil().clamp(1, 100);
        return 16 + rows * cardHeight + (rows - 1) * spacing;
      case 1:
        const spacing = 10.0;
        final itemWidth = (width - 32 - spacing * 2) / 3;
        final cardHeight = itemWidth + 24;
        final rows = (stampCount / 3).ceil().clamp(1, 100);
        return 16 + rows * cardHeight + (rows - 1) * spacing;
      case 2:
      default:
        if (checkInCount == 0) {
          // Empty-state kartının görünmesi için minimum yükseklik.
          return 180;
        }
        // padding 16 + row(padding 20 + avatar 50 + border 2 + margin 10)
        return 16 + checkInCount * 82.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final locationLabel = _liveLocation ?? user.location;

    return ListView(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.only(
        bottom:
            MainWrapper.navBarHeight +
            MediaQuery.paddingOf(context).bottom +
            16,
      ),
      children: [
        ProfileHeader(
          user: user,
          onShareTap: () =>
              ProfileShareSheet.show(context, username: user.username),
        ),
        ProfileStats(
          user: user,
          onCheckInTap: _scrollToCheckInTab,
          onBeforeNavigation: _cancelPendingScroll,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(AssetPaths.iconLocationDark, size: 18),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      locationLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1,
                        letterSpacing: -0.28,
                        color: Color(0x001a1714).withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
              if (user.bio.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  user.bio,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.32,
                    color: AppColors.deepRoast,
                  ),
                ),
              ],
              if (user.links.isNotEmpty) ...[
                const SizedBox(height: 12),
                _ProfileLinksRow(links: user.links),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _ProfileActionButton(
                      label: 'edit_profile'.tr(),
                      backgroundColor: AppColors.zoviOrange,
                      foregroundColor: AppColors.white,
                      onTap: () async {
                        final updatedUser = await context.push<UserProfile>(
                          RoutePaths.editProfile.path,
                          extra: EditProfileRouteArgs(user: user),
                        );
                        if (updatedUser == null || !context.mounted) return;
                        context.read<ProfileBloc>().add(
                          ProfileUserUpdated(updatedUser),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ProfileActionButton(
                      label: 'share_profile'.tr(),
                      backgroundColor: AppColors.surfaceGray,
                      foregroundColor: AppColors.mutedGray,
                      onTap: () => ProfileShareSheet.show(
                        context,
                        username: user.username,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ProfileMap(
          location: locationLabel,
          point: _mapPoint,
          avatarPath: user.avatarPath,
          hasRealLocation: _hasRealLocation,
        ),
        const SizedBox(height: 16),
        ProfilePlans(plans: widget.plans),
        const SizedBox(height: 16),
        KeyedSubtree(
          key: _tabsSectionKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProfileTabs(
                controller: widget.tabController,
                onTabSelected: widget.onTabSelected,
              ),
              AnimatedBuilder(
                animation: widget.tabController.animation!,
                builder: (context, child) {
                  final value = widget.tabController.animation!.value.clamp(
                    0.0,
                    2.0,
                  );
                  final lower = value.floor().clamp(0, 2);
                  final upper = value.ceil().clamp(0, 2);
                  final t = value - lower;
                  final height = lerpDouble(
                    _tabHeight(
                      index: lower,
                      width: width,
                      pulseCount: widget.pulses.length,
                      stampCount: widget.stamps.length,
                      checkInCount: widget.checkIns.length,
                    ),
                    _tabHeight(
                      index: upper,
                      width: width,
                      pulseCount: widget.pulses.length,
                      stampCount: widget.stamps.length,
                      checkInCount: widget.checkIns.length,
                    ),
                    t,
                  )!;
                  return SizedBox(height: height, child: child);
                },
                child: TabBarView(
                  controller: widget.tabController,
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: ProfilePulses(
                        pulses: widget.pulses,
                        isLoading:
                            !widget.sectionsReady && widget.pulses.isEmpty,
                      ),
                    ),
                    Align(
                      alignment: Alignment.topLeft,
                      child: ProfileStamps(stamps: widget.stamps),
                    ),
                    Align(
                      alignment: Alignment.topLeft,
                      child: ProfileCheckins(checkIns: widget.checkIns),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

@immutable
final class _ProfileLinksRow extends StatelessWidget {
  const _ProfileLinksRow({required this.links});

  final List<ProfileLink> links;

  @override
  Widget build(BuildContext context) {
    final isSingle = links.length == 1;
    final label = isSingle ? links.first.displayUrl : 'my_links'.tr();

    return GestureDetector(
      onTap: () {
        if (isSingle) {
          openProfileLink(links.first.url);
          return;
        }
        showProfileLinksSheet(context, links: links);
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppIcon(AssetPaths.iconLink, size: 20),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1,
                letterSpacing: -0.32,
                color: AppColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

@immutable
final class _ProfileActionButton extends StatelessWidget {
  const _ProfileActionButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1,
            letterSpacing: -0.32,
            color: foregroundColor,
          ),
        ),
      ),
    );
  }
}
