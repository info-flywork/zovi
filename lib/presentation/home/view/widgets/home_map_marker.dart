part of '../home_view.dart';

class HomeMapMarker extends StatelessWidget {
  const HomeMapMarker({required this.friend, super.key});

  final MapFriend friend;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 49,
          height: 49,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.zoviOrange, width: 3),
          ),
          child: ClipOval(
            child: Image.asset(friend.avatarPath, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          friend.name,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${friend.streak}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              const AppIcon(AssetPaths.iconStreakFlame, size: 24),
            ],
          ),
        ),
      ],
    );
  }
}
