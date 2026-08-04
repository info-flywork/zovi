part of '../home_view.dart';

class HomeMapFriendSheet extends StatefulWidget {
  const HomeMapFriendSheet({
    required this.friend,
    required this.viewerLocation,
    required this.onClose,
    required this.onSend,
    required this.onOpenProfile,
    super.key,
  });

  final MapFriend friend;
  final LatLng viewerLocation;
  final VoidCallback onClose;
  final ValueChanged<String> onSend;
  final VoidCallback onOpenProfile;

  @override
  State<HomeMapFriendSheet> createState() => _HomeMapFriendSheetState();
}

class _HomeMapFriendSheetState extends State<HomeMapFriendSheet> {
  late final TextEditingController _controller = TextEditingController();

  static const _thumbSize = 68.0;
  static const _stampSize = 32.0;
  static const _distance = Distance();

  /// Average walking speed ≈ 5 km/h.
  static const _walkMetersPerMinute = 83.3;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    widget.onSend(_controller.text.trim());
  }

  int? _liveDistanceMeters(MapFriend friend) {
    if (friend.lat == 0 && friend.lng == 0) {
      return friend.distanceMeters;
    }
    return _distance
        .as(
          LengthUnit.Meter,
          widget.viewerLocation,
          LatLng(friend.lat, friend.lng),
        )
        .round();
  }

  String? _formatDistance(int? meters) {
    if (meters == null || meters < 0) return null;
    if (meters < 1000) return '${meters}m';
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  String? _formatCheckInAgo(DateTime at) {
    final elapsed = DateTime.now().difference(at.toLocal());
    if (elapsed.isNegative || elapsed.inMinutes < 1) {
      return 'map_friend_checked_just_now'.tr();
    }
    if (elapsed.inMinutes < 60) {
      return 'map_friend_checked_minutes_ago'.tr(
        namedArgs: {'minutes': '${elapsed.inMinutes}'},
      );
    }
    if (elapsed.inHours < 24) {
      return 'map_friend_checked_hours_ago'.tr(
        namedArgs: {'hours': '${elapsed.inHours}'},
      );
    }
    return null;
  }

  String? _formatWalkEta(int meters) {
    final minutes = meters / _walkMetersPerMinute;
    if (minutes < 1) return 'map_friend_walk_under_min'.tr();
    return 'map_friend_walk_minutes'.tr(
      namedArgs: {'minutes': '${minutes.round().clamp(1, 180)}'},
    );
  }

  String? _metaLine(MapFriend friend) {
    final meters = _liveDistanceMeters(friend);
    final distance = _formatDistance(meters);
    final checkedAt = friend.checkIn?.checkedAt;
    final time = checkedAt != null
        ? _formatCheckInAgo(checkedAt)
        : (meters == null ? null : _formatWalkEta(meters));

    if (time == null && distance == null) return null;
    if (time == null) return distance;
    if (distance == null) return time;
    return 'map_friend_eta'.tr(namedArgs: {'time': time, 'distance': distance});
  }

  String? _locationLabel(MapFriend friend) {
    final place = friend.checkIn?.placeName.trim() ?? '';
    if (place.isNotEmpty) return place;
    final label = friend.locationLabel?.trim() ?? '';
    return label.isEmpty ? null : label;
  }

  @override
  Widget build(BuildContext context) {
    final friend = widget.friend;
    final checkIn = friend.checkIn;
    final location = _locationLabel(friend);
    final meta = _metaLine(friend);

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
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
            GestureDetector(
              onTap: widget.onOpenProfile,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  if (checkIn != null)
                    SizedBox(
                      width: _thumbSize + 8,
                      height: _thumbSize + 8,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CheckInCyclingPhoto(
                            paths: checkIn.photoPaths,
                            size: _thumbSize,
                            borderRadius: BorderRadius.circular(16),
                            padding: const EdgeInsets.all(3),
                            gradient: AppColors.storyRingGradient,
                            indexListenable: getIt<UserRepository>()
                                .friendCheckInPhotoIndexListenable(
                                  friend.userId.isNotEmpty
                                      ? friend.userId
                                      : friend.name,
                                ),
                          ),
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Image.asset(
                              checkIn.stampImagePath,
                              width: _stampSize,
                              height: _stampSize,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ProfileAvatar(
                      path: friend.avatarPath,
                      size: 68,
                      showGradientRing: true,
                      ringWidth: 3,
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                friend.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  height: 18 / 16,
                                  color: AppColors.black,
                                ),
                              ),
                            ),
                            if (friend.streak > 0) ...[
                              const SizedBox(width: 8),
                              _FriendSheetStreakBadge(streak: friend.streak),
                            ],
                          ],
                        ),
                        if (location != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            friend.hasCheckIn
                                ? 'map_friend_check_in_location'.tr(
                                    namedArgs: {'location': location},
                                  )
                                : location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 18 / 14,
                              color: AppColors.zoviOrange,
                            ),
                          ),
                        ],
                        if (meta != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  meta,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    height: 1,
                                    color: AppColors.deepRoast.withValues(
                                      alpha: 0.35,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const AppIcon(AssetPaths.iconSendGray, size: 16),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const AppIcon(AssetPaths.iconRight, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 44,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.deepRoast.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submit(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1,
                        color: AppColors.deepRoast,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'map_friend_write'.tr(
                          namedArgs: {'name': friend.name},
                        ),
                        hintStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1,
                          color: AppColors.deepRoast.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _submit,
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      'map_friend_send'.tr(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        color: Color(0xFF34C759),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendSheetStreakBadge extends StatelessWidget {
  const _FriendSheetStreakBadge({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFF4D6D).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$streak',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1,
              color: Color(0xFFFF4D6D),
            ),
          ),
          const SizedBox(width: 2),
          const AppIcon(AssetPaths.iconStreak, size: 12),
        ],
      ),
    );
  }
}
