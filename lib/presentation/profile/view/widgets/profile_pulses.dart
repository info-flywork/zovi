part of '../profile_view.dart';

class ProfilePulses extends StatelessWidget {
  const ProfilePulses({required this.pulses, super.key});

  final List<PulseItem> pulses;

  @override
  Widget build(BuildContext context) {
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
