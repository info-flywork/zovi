part of '../home_view.dart';

class HomeMapFriendSheet extends StatefulWidget {
  const HomeMapFriendSheet({
    required this.friend,
    required this.onClose,
    required this.onSend,
    super.key,
  });

  final MapFriend friend;
  final VoidCallback onClose;
  final ValueChanged<String> onSend;

  @override
  State<HomeMapFriendSheet> createState() => _HomeMapFriendSheetState();
}

class _HomeMapFriendSheetState extends State<HomeMapFriendSheet> {
  late final TextEditingController _controller = TextEditingController();

  static const _thumbSize = 68.0;
  static const _stampSize = 32.0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    widget.onSend(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final friend = widget.friend;
    final minutes = friend.etaMinutes ?? 10;
    final distance = friend.distanceMeters ?? 50;
    final checkIn = friend.checkIn;

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
              onTap: widget.onClose,
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
                                .friendCheckInPhotoIndexListenable(friend.name),
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
                            const SizedBox(width: 8),
                            _FriendSheetStreakBadge(streak: friend.streak),
                          ],
                        ),
                        if (friend.locationLabel != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            friend.hasCheckIn
                                ? 'map_friend_check_in_location'.tr(
                                    namedArgs: {
                                      'location': friend.locationLabel!,
                                    },
                                  )
                                : friend.locationLabel!,
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
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'map_friend_eta'.tr(
                                namedArgs: {
                                  'minutes': '$minutes',
                                  'distance': '$distance',
                                },
                              ),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 1,
                                color: AppColors.deepRoast.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const AppIcon(
                              AssetPaths.iconSendGray,
                              size: 16,
                            ),
                          ],
                        ),
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
                          color: AppColors.deepRoast.withValues(alpha: 0.3),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _submit,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mintGreen,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        'map_friend_send'.tr(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1,
                          color: AppColors.white,
                        ),
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
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0x1AFF4D6D),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$streak',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 14 / 12,
              color: AppColors.black,
            ),
          ),
          const SizedBox(width: 4),
          const AppIcon(AssetPaths.iconStreak, size: 18),
        ],
      ),
    );
  }
}
