part of '../profile_view.dart';

@immutable
final class ProfilePulses extends StatelessWidget {
  const ProfilePulses({
    required this.pulses,
    this.isLoading = false,
    super.key,
  });

  final List<PulseItem> pulses;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final visiblePulses = pulses.where((pulse) => !pulse.isVideo).toList();

    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: _PulseGridShimmer(),
      );
    }

    if (visiblePulses.isEmpty) {
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
              for (final pulse in visiblePulses)
                SizedBox(
                  width: itemWidth,
                  height: itemHeight,
                  child: GestureDetector(
                    onTap: () => showPulseMediaViewer(
                      context,
                      imagePath: pulse.imagePath,
                      heroTag:
                          'pulse_${pulse.id.isNotEmpty ? pulse.id : pulse.imagePath}',
                      isVideo: pulse.isVideo,
                    ),
                    child: Hero(
                      tag:
                          'pulse_${pulse.id.isNotEmpty ? pulse.id : pulse.imagePath}',
                      child: _PulseCard(
                        imagePath: pulse.imagePath,
                        isVideo: pulse.isVideo,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

@immutable
final class _PulseGridShimmer extends StatelessWidget {
  const _PulseGridShimmer();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final itemWidth = (constraints.maxWidth - spacing * 2) / 3;
        final itemHeight = itemWidth * (200 / 126);
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var i = 0; i < 3; i++)
              SizedBox(
                width: itemWidth,
                height: itemHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceGray,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

@immutable
final class _EmptyTabState extends StatelessWidget {
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

@immutable
final class _PulseCard extends StatelessWidget {
  const _PulseCard({required this.imagePath, this.isVideo = false});

  final String imagePath;
  final bool isVideo;

  bool get _isNetwork =>
      imagePath.startsWith('http://') || imagePath.startsWith('https://');

  bool get _isFile =>
      imagePath.startsWith('/') || imagePath.startsWith('file:');

  @override
  Widget build(BuildContext context) {
    final Widget image;
    if (_isNetwork) {
      image = Image.network(
        imagePath,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: FilterQuality.low,
        errorBuilder: (_, _, _) =>
            const ColoredBox(color: AppColors.surfaceGray),
      );
    } else if (_isFile) {
      image = Image.file(
        File(imagePath.replaceFirst('file://', '')),
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) =>
            const ColoredBox(color: AppColors.surfaceGray),
      );
    } else if (imagePath.isNotEmpty) {
      image = Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            const ColoredBox(color: AppColors.surfaceGray),
      );
    } else {
      image = const ColoredBox(color: AppColors.surfaceGray);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isVideo)
            const ColoredBox(color: AppColors.black)
          else
            image,
          if (isVideo)
            const Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: AppIcon(AssetPaths.iconReelsSquare, size: 20),
              ),
            ),
        ],
      ),
    );
  }
}
