part of '../home_view.dart';

@immutable
final class HomeHeaderSection extends StatelessWidget {
  const HomeHeaderSection({required this.hasUnreadMessages, super.key});

  final bool hasUnreadMessages;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.push(RoutePaths.notifications.path),
            behavior: HitTestBehavior.opaque,
            child: const AppIcon(AssetPaths.iconHeart, size: 32),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => context.push(RoutePaths.tribe.path),
            behavior: HitTestBehavior.opaque,
            child: const AppIcon(AssetPaths.iconFormatCircle, size: 32),
          ),
          const Spacer(),
          Text('app_name'.tr(), style: AppTheme.brandWordmarkSmall),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push(RoutePaths.lifestyleStreak.path),
            behavior: HitTestBehavior.opaque,
            child: const AppIcon(AssetPaths.iconFlame, size: 32),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => context.go(RoutePaths.chat.path),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 32,
              height: 32,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const AppIcon(AssetPaths.iconSend, size: 32),
                  if (hasUnreadMessages)
                    Positioned(
                      top: 1.5,
                      left: 9,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.logoutRed,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.white, width: 1),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
