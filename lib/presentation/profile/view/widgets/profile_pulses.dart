part of '../profile_view.dart';

class ProfilePulses extends StatelessWidget {
  const ProfilePulses({required this.pulses, super.key});

  final List<PulseItem> pulses;

  @override
  Widget build(BuildContext context) {
    if (pulses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        child: _EmptyTabState(
          icon: AssetPaths.iconStory,
          text: 'empty_pulses'.tr(),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 10.0;
          final itemWidth = (constraints.maxWidth - spacing * 2) / 3;
          final itemHeight = itemWidth * (200 / 126);

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final pulse in pulses)
                SizedBox(
                  width: itemWidth,
                  height: itemHeight,
                  child: _PulseCard(imagePath: pulse.imagePath),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyTabState extends StatelessWidget {
  const _EmptyTabState({
    required this.icon,
    required this.text,
  });

  final String icon;
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
          AppIcon(icon, size: 26, color: AppColors.mutedGray),
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

class _PulseCard extends StatelessWidget {
  const _PulseCard({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(imagePath, fit: BoxFit.cover),
    );
  }
}
