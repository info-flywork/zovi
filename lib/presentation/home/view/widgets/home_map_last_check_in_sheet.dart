part of '../home_view.dart';

class HomeMapLastCheckInSheet extends StatelessWidget {
  const HomeMapLastCheckInSheet({
    required this.checkIn,
    required this.onClose,
    super.key,
  });

  final ActiveMapCheckIn checkIn;
  final VoidCallback onClose;

  static const _thumbSize = 68.0;
  static const _stampSize = 32.0;

  String _relativeTime(DateTime? at) {
    if (at == null) return 'map_friend_checked_just_now'.tr();
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
    final local = at.toLocal();
    final day = '${local.day}.${local.month}.${local.year}';
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day · $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
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
        child: GestureDetector(
          onTap: onClose,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
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
                      indexListenable:
                          getIt<UserRepository>().checkInPhotoIndexListenable,
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: checkIn.hasTitle
                          ? Container(
                              height: 24,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.black.withValues(
                                      alpha: 0.2,
                                    ),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                checkIn.titleLabel!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  height: 1,
                                  color: AppColors.black,
                                ),
                              ),
                            )
                          : Image.asset(
                              checkIn.stampImagePath,
                              width: _stampSize,
                              height: _stampSize,
                              fit: BoxFit.contain,
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'last_check_in_title'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 18 / 16,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      checkIn.placeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 18 / 14,
                        color: AppColors.zoviOrange,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _relativeTime(checkIn.checkedAt),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1,
                        color: AppColors.deepRoast.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
