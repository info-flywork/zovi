part of '../profile_view.dart';

@immutable
final class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    required this.user,
    required this.onShareTap,
    this.hasActiveStory = false,
    this.storyIsViewed = false,
    this.onAvatarTap,
    super.key,
  });

  final UserProfile user;
  final VoidCallback onShareTap;
  final bool hasActiveStory;
  final bool storyIsViewed;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        children: [
          Row(
            children: [
              _ProfileCoinBalance(coins: user.coins),
              Spacer(),
              GestureDetector(
                onTap: () => context.push(RoutePaths.stickers.path),
                child: const AppIcon(AssetPaths.iconProfileClip, size: 32),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: onShareTap,
                child: const AppIcon(AssetPaths.iconExportCircle, size: 32),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () => context.push(RoutePaths.settings.path),
                child: const AppIcon(AssetPaths.iconSetting, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: hasActiveStory ? onAvatarTap : null,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 120,
              height: 120,
              child: ProfileAvatar(
                path: user.avatarPath,
                size: 120,
                showGradientRing: hasActiveStory && !storyIsViewed,
                showSeenRing: hasActiveStory && storyIsViewed,
                ringWidth: 3,
                ringOpacity: hasActiveStory && storyIsViewed ? 0.45 : 1,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1,
              letterSpacing: -0.4,
              color: AppColors.deepRoast,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.username,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1,
              letterSpacing: -0.28,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

@immutable
final class _ProfileCoinBalance extends StatelessWidget {
  const _ProfileCoinBalance({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openZoviCoinPaywall(context),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$coins',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1,
              letterSpacing: -0.32,
              color: AppColors.deepRoast,
            ),
          ),
          const SizedBox(width: 4),
          Image.asset(
            AssetPaths.zoviCoin,
            width: 34,
            height: 34,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}
