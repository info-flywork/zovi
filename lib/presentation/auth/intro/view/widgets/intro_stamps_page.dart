part of '../intro_view.dart';

@immutable
final class IntroStampsPage extends StatefulWidget {
  const IntroStampsPage({super.key, this.isActive = false});

  final bool isActive;

  @override
  State<IntroStampsPage> createState() => _IntroStampsPageState();
}

final class _IntroStampsPageState extends State<IntroStampsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _card1Slide;
  late final Animation<double> _card2Slide;
  late final Animation<double> _cardsFade;
  late final Animation<double> _badgeFade;
  late final Animation<Offset> _badgeSlide;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _textFade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0, 0.4, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0, 0.4, curve: Curves.easeOutCubic),
      ),
    );

    _card1Slide = Tween<double>(begin: -1, end: 0).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.15, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    _card2Slide = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.28, 0.82, curve: Curves.easeOutCubic),
      ),
    );
    _cardsFade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.15, 0.5, curve: Curves.easeOut),
    );

    _badgeFade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.55, 1, curve: Curves.easeOut),
    );
    _badgeSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.55, 1, curve: Curves.easeOutCubic),
      ),
    );

    if (widget.isActive) {
      _enter.forward();
    }
  }

  @override
  void didUpdateWidget(covariant IntroStampsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _enter.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slideDistance = MediaQuery.sizeOf(context).width * 0.7;

    return AnimatedBuilder(
      animation: _enter,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: Column(
            children: [
              FadeTransition(
                opacity: _textFade,
                child: SlideTransition(
                  position: _textSlide,
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Opacity(
                opacity: _cardsFade.value,
                child: Transform.translate(
                  offset: Offset(_card1Slide.value * slideDistance, 0),
                  child: _StampCard(
                    title: 'intro_stamp_night_flame_title'.tr(),
                    subtitle: 'intro_stamp_night_flame_subtitle'.tr(),
                    progress: 0.72,
                    sticker: AssetPaths.stickerNightFlame,
                    rotation: -1.26,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Opacity(
                opacity: _cardsFade.value,
                child: Transform.translate(
                  offset: Offset(_card2Slide.value * slideDistance, 0),
                  child: _StampCard(
                    title: 'intro_stamp_explorer_title'.tr(),
                    subtitle: 'intro_stamp_explorer_subtitle'.tr(),
                    progress: 0.45,
                    sticker: AssetPaths.stickerExplorer,
                    rotation: 1.41,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FadeTransition(
                opacity: _badgeFade,
                child: SlideTransition(
                  position: _badgeSlide,
                  child: Container(
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
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

@immutable
final class _StampCard extends StatelessWidget {
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
