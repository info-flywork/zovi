part of '../profile_view.dart';

class ProfileStamps extends StatelessWidget {
  const ProfileStamps({required this.stamps, super.key});

  final List<StampItem> stamps;

  @override
  Widget build(BuildContext context) {
    if (stamps.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        child: _EmptyStampsState(text: 'empty_stamps'.tr()),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 10.0;
          final itemWidth = (constraints.maxWidth - spacing * 2) / 3;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final stamp in stamps)
                SizedBox(
                  width: itemWidth,
                  child: _StampCard(stamp: stamp),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyStampsState extends StatelessWidget {
  const _EmptyStampsState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surfaceGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(AssetPaths.iconAward, size: 26, color: AppColors.mutedGray),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StampCard extends StatelessWidget {
  const _StampCard({required this.stamp});

  final StampItem stamp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: stamp.isNetwork
                ? StampImage(
                    path: stamp.imagePath,
                    stampId: stamp.id,
                    fit: BoxFit.contain,
                  )
                : Image.asset(
                    stamp.imagePath,
                    fit: BoxFit.contain,
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            stamp.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1,
              letterSpacing: -0.28,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
