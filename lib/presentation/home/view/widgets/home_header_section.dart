part of '../home_view.dart';

class HomeHeaderSection extends StatelessWidget {
  const HomeHeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const AppIcon(AssetPaths.iconHeart, size: 32),
          const SizedBox(width: 10),
          const AppIcon(AssetPaths.iconFormatCircle, size: 32),
          const Spacer(),
          Text('zovi', style: AppTheme.brandWordmarkSmall),
          const Spacer(),
          const AppIcon(AssetPaths.iconFlame, size: 32),
          const SizedBox(width: 10),
          const AppIcon(AssetPaths.iconSend, size: 32),
        ],
      ),
    );
  }
}
