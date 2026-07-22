part of '../home_view.dart';

class HomeHeaderSection extends StatelessWidget {
  const HomeHeaderSection({super.key});

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
          const AppIcon(AssetPaths.iconFlame, size: 32),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => context.go(RoutePaths.chat.path),
            behavior: HitTestBehavior.opaque,
            child: const AppIcon(AssetPaths.iconSend, size: 32),
          ),
        ],
      ),
    );
  }
}
