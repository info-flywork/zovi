part of '../profile_view.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    required this.user,
    required this.onShareTap,
    super.key,
  });

  final UserProfile user;
  final VoidCallback onShareTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  }
                },
                child: const AppIcon(AssetPaths.iconArrowLeft, size: 32),
              ),
              const Spacer(),
              const AppIcon(AssetPaths.iconProfileClip, size: 32),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: onShareTap,
                child: const AppIcon(AssetPaths.iconExportCircle, size: 32),
              ),
              const SizedBox(width: 20),
              const AppIcon(AssetPaths.iconSetting, size: 32),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 120,
            height: 120,
            child: ProfileAvatar(
              path: user.avatarPath,
              size: 120,
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
