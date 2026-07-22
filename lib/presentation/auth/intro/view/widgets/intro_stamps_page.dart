part of '../intro_view.dart';

class IntroStampsPage extends StatelessWidget {
  const IntroStampsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        children: [
          Text(
            'intro_stamps_title'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.6,
              color: AppColors.deepRoast,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'intro_stamps_subtitle'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              height: 1.35,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 40),
          _StampCard(
            title: 'intro_stamp_night_flame_title'.tr(),
            subtitle: 'intro_stamp_night_flame_subtitle'.tr(),
            progress: 0.72,
            sticker: AssetPaths.stickerNightFlame,
            rotation: -1.26,
          ),
          const SizedBox(height: 16),
          _StampCard(
            title: 'intro_stamp_explorer_title'.tr(),
            subtitle: 'intro_stamp_explorer_subtitle'.tr(),
            progress: 0.45,
            sticker: AssetPaths.stickerExplorer,
            rotation: 1.41,
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.zoviOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'intro_stamps_waiting'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.zoviOrange,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StampCard extends StatelessWidget {
  const _StampCard({
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.sticker,
    required this.rotation,
  });

  final String title;
  final String subtitle;
  final double progress;
  final String sticker;
  final double rotation;

  static const _cardGradient = [Color(0xFFFF5C1A), Color(0xFFFF4D6D)];

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation * math.pi / 180,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: _cardGradient),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Color(0xFFC54980), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Image.asset(
                sticker,
                width: 64,
                height: 64,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(999),
                      backgroundColor: Colors.black.withValues(alpha: 0.2),
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
