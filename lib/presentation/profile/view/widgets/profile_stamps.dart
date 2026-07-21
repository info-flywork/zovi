part of '../profile_view.dart';

class ProfileStamps extends StatelessWidget {
  const ProfileStamps({required this.stamps, super.key});

  final List<StampItem> stamps;

  @override
  Widget build(BuildContext context) {
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
            child: Image.asset(
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
