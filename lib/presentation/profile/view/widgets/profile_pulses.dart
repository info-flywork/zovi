part of '../profile_view.dart';

class ProfilePulses extends StatelessWidget {
  const ProfilePulses({required this.pulses, super.key});

  final List<PulseItem> pulses;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 216,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        scrollDirection: Axis.horizontal,
        itemCount: pulses.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return _PulseCard(imagePath: pulses[index].imagePath);
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
      child: SizedBox(
        width: 126,
        height: 200,
        child: Image.asset(imagePath, fit: BoxFit.cover),
      ),
    );
  }
}
