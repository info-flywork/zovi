part of '../home_view.dart';

class HomeMapMarker extends StatelessWidget {
  const HomeMapMarker({required this.friend, super.key});

  final MapFriend friend;

  static const _avatarSize = 56.0;
  static const _ringWidth = 3.5;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: _avatarSize + 20,
          height: _avatarSize + 8,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                width: _avatarSize,
                height: _avatarSize,
                padding: const EdgeInsets.all(_ringWidth),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      Color(0xFFE8622A),
                      Color(0xFFF2A05A),
                      Color(0xFFDA87FD),
                      Color(0xFFE8622A),
                    ],
                  ),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white,
                  ),
                  child: ClipOval(
                    child: Image.asset(friend.avatarPath, fit: BoxFit.cover),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: -80,
                bottom: 3,
                child: Center(child: _StreakBadge(streak: friend.streak)),
              ),
            ],
          ),
        ),
        Text(
          friend.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1,
            color: AppColors.black,
          ),
        ),
      ],
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8),
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
          Text(
            '$streak',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 14 / 12,
              color: AppColors.black,
            ),
          ),
          const SizedBox(width: 4),
          const AppIcon(AssetPaths.iconStreak, size: 20),
        ],
      ),
    );
  }
}
