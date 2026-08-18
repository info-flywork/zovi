part of '../intro_view.dart';

@immutable
final class IntroAroundPage extends StatefulWidget {
  const IntroAroundPage({super.key});

  static const _creamBorder = Color(0xFFF5E6D8);
  static const _orange = Color(0xFFFF5C1A);
  static const _green = Color(0xFF00C896);
  static const _pink = Color(0xFFFF4D6D);
  static const _purple = Color(0xFF7B2FFF);
  static const _black = Color(0xFF141414);
  static const _whiteFill = Color(0xFFF5F5F0);
  static const _whiteGlow = Color(0xFFD2D2D2);

  /// Figma: outer 199, middle 130, inner 56.
  static const _outerR = 1.0;
  static const _middleR = 130 / 199;
  static const _innerR = 56 / 199;

  @override
  State<IntroAroundPage> createState() => _IntroAroundPageState();
}

final class _IntroAroundPageState extends State<IntroAroundPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _orbit;

  @override
  void initState() {
    super.initState();
    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _orbit.dispose();
    super.dispose();
  }

  static double _angleOf(double dx, double dy) => math.atan2(dy, dx);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'intro_around_title'.tr(),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.6,
                color: AppColors.deepRoast,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              textAlign: TextAlign.center,
              'intro_around_subtitle'.tr(),
              style: const TextStyle(
                fontSize: 16,
                height: 1.35,
                color: AppColors.textSecondary,
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final side = math.min(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                final avatarSize = side * (78 / 398);

                Offset onRing(double radius, double angle) {
                  final ringPx = radius * (side / 2);
                  return Offset(
                    side / 2 + math.cos(angle) * ringPx,
                    side / 2 + math.sin(angle) * ringPx,
                  );
                }

                return Center(
                  child: SizedBox(
                    width: side,
                    height: side,
                    child: AnimatedBuilder(
                      animation: _orbit,
                      builder: (context, _) {
                        final turn = _orbit.value * 2 * math.pi;
                        // Outer CW, middle CCW, inner faster CW.
                        final outerSpin = turn;
                        final middleSpin = -turn * 1.25;
                        final innerSpin = turn * 1.6;

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Center(
                              child: _RadarRing(
                                diameter: side * IntroAroundPage._outerR,
                                color: Colors.black.withValues(alpha: 0.08),
                              ),
                            ),
                            Center(
                              child: _RadarRing(
                                diameter: side * IntroAroundPage._middleR,
                                color: Colors.black.withValues(alpha: 0.1),
                              ),
                            ),
                            Center(
                              child: _RadarRing(
                                diameter: side * IntroAroundPage._innerR,
                                color: Colors.black.withValues(alpha: 0.12),
                              ),
                            ),

                            // Outer
                            _RadarAvatar(
                              center: onRing(
                                IntroAroundPage._outerR,
                                _angleOf(-0.08, -1.0) + outerSpin,
                              ),
                              asset:
                                  'assets/images/a4f406ee73abc4abe914ad3664a18b1316f07725.png',
                              fill: IntroAroundPage._orange,
                              glow: IntroAroundPage._orange,
                              glowBlur: 16,
                              size: avatarSize,
                              imageScale: 0.8,
                              imageRotation: -0.12,
                            ),
                            _RadarAvatar(
                              center: onRing(
                                IntroAroundPage._outerR,
                                _angleOf(0.78, -0.62) + outerSpin,
                              ),
                              asset: AssetPaths.introAvatarBlack,
                              fill: IntroAroundPage._black,
                              glow: Colors.black,
                              glowBlur: 10,
                              size: avatarSize,
                            ),
                            _RadarAvatar(
                              center: onRing(
                                IntroAroundPage._outerR,
                                _angleOf(0.48, 0.88) + outerSpin,
                              ),
                              asset: 'assets/images/greeeennn.png',
                              fill: IntroAroundPage._green,
                              glow: IntroAroundPage._green,
                              glowBlur: 16,
                              size: avatarSize,
                              imageScale: 0.75,
                              imageRotation: 0.22,
                            ),
                            _RadarAvatar(
                              center: onRing(
                                IntroAroundPage._outerR,
                                _angleOf(-0.78, 0.62) + outerSpin,
                              ),
                              asset:
                                  'assets/images/c14fd05db29ff97f4e72cdad306f0356d4970522.png',
                              fill: IntroAroundPage._purple,
                              glow: IntroAroundPage._purple,
                              glowBlur: 10,
                              size: avatarSize,
                              imageScale: 0.8,
                              imageRotation: 0.22,
                            ),

                            // Middle
                            _RadarAvatar(
                              center: onRing(
                                IntroAroundPage._middleR,
                                _angleOf(-0.90, -0.44) + middleSpin,
                              ),
                              asset:
                                  'assets/images/facca6043be33c13f3205fe5c7645ee4b44cf962.png',
                              fill: IntroAroundPage._purple,
                              glow: IntroAroundPage._purple,
                              glowBlur: 16,
                              size: avatarSize,
                              imageScale: 0.7,
                            ),
                            _RadarAvatar(
                              center: onRing(
                                IntroAroundPage._middleR,
                                _angleOf(0.95, 0.30) + middleSpin,
                              ),
                              asset: AssetPaths.introAvatarPink,
                              fill: IntroAroundPage._pink,
                              glow: IntroAroundPage._pink,
                              glowBlur: 10,
                              size: avatarSize,
                              imageScale: 0.78,
                            ),

                            // Inner
                            _RadarAvatar(
                              center: onRing(
                                IntroAroundPage._innerR,
                                _angleOf(0.78, -0.62) + innerSpin,
                              ),
                              asset:
                                  'assets/images/74e80b53333c7c2914626772eefd93deb49d68bd.png',
                              fill: IntroAroundPage._green,
                              glow: IntroAroundPage._green,
                              glowBlur: 10,
                              size: avatarSize,
                              imageScale: 0.78,
                            ),
                            _RadarAvatar(
                              center: onRing(
                                IntroAroundPage._innerR,
                                _angleOf(-0.55, 0.84) + innerSpin,
                              ),
                              asset:
                                  'assets/images/7eb500c6299afa01c0ebf5231ca77770b611bde5.png',
                              fill: IntroAroundPage._whiteFill,
                              glow: IntroAroundPage._whiteGlow,
                              glowBlur: 10,
                              glowOpacity: 1,
                              size: avatarSize,
                              imageScale: 0.78,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

@immutable
final class _RadarRing extends StatelessWidget {
  const _RadarRing({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.2),
      ),
    );
  }
}

@immutable
final class _RadarAvatar extends StatelessWidget {
  const _RadarAvatar({
    required this.center,
    required this.asset,
    required this.fill,
    required this.glow,
    required this.glowBlur,
    required this.size,
    this.glowOpacity = 0.5,
    this.imageScale = 1,
    this.imageRotation = 0,
  });

  final Offset center;
  final String asset;
  final Color fill;
  final Color glow;
  final double glowBlur;
  final double glowOpacity;
  final double size;
  final double imageScale;
  final double imageRotation;

  @override
  Widget build(BuildContext context) {
    Widget image = imageScale >= 1
        ? Image.asset(
            asset,
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.12),
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
          )
        : Center(
            child: SizedBox(
              width: size * imageScale,
              height: size * imageScale,
              child: Image.asset(
                asset,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
                isAntiAlias: true,
              ),
            ),
          );

    if (imageRotation != 0) {
      image = Transform.rotate(angle: imageRotation, child: image);
    }

    return Positioned(
      left: center.dx - size / 2,
      top: center.dy - size / 2,
      width: size,
      height: size,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fill,
          border: Border.all(color: IntroAroundPage._creamBorder, width: 2),
          boxShadow: [
            BoxShadow(
              color: glow.withValues(alpha: glowOpacity),
              blurRadius: glowBlur,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: image,
      ),
    );
  }
}
