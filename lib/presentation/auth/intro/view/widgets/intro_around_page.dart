part of '../intro_view.dart';

class IntroAroundPage extends StatelessWidget {
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
                // Full width when height allows; otherwise fit available height.
                final side = math.min(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                // Renkli daire çapı — Figma ~75 on 398
                final avatarSize = side * (78 / 398);

                Offset onRing(double radius, double dx, double dy) {
                  final mag = math.sqrt(dx * dx + dy * dy);
                  final nx = dx / mag;
                  final ny = dy / mag;
                  final ringPx = radius * (side / 2);
                  return Offset(side / 2 + nx * ringPx, side / 2 + ny * ringPx);
                }

                return Center(
                  child: SizedBox(
                    width: side,
                    height: side,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Center(
                          child: _RadarRing(
                            diameter: side * _outerR,
                            color: Colors.black.withValues(alpha: 0.08),
                          ),
                        ),
                        Center(
                          child: _RadarRing(
                            diameter: side * _middleR,
                            color: Colors.black.withValues(alpha: 0.1),
                          ),
                        ),
                        Center(
                          child: _RadarRing(
                            diameter: side * _innerR,
                            color: Colors.black.withValues(alpha: 0.12),
                          ),
                        ),

                        // Outer
                        _RadarAvatar(
                          center: onRing(_outerR, -0.08, -1.0),
                          asset: AssetPaths.introAvatarOrange,
                          fill: _orange,
                          glow: _orange,
                          glowBlur: 16,
                          size: avatarSize,
                          imageScale: 0.78,
                        ),
                        _RadarAvatar(
                          center: onRing(_outerR, 0.78, -0.62),
                          asset: AssetPaths.introAvatarBlack,
                          fill: _black,
                          glow: Colors.black,
                          glowBlur: 10,
                          size: avatarSize,
                        ),
                        _RadarAvatar(
                          center: onRing(_outerR, 0.48, 0.88),
                          asset: AssetPaths.introAvatarGreen2,
                          fill: _green,
                          glow: _green,
                          glowBlur: 16,
                          size: avatarSize,
                          imageScale: 0.78,
                        ),
                        _RadarAvatar(
                          center: onRing(_outerR, -0.78, 0.62),
                          asset: AssetPaths.introAvatarPurple,
                          fill: _purple,
                          glow: _purple,
                          glowBlur: 10,
                          size: avatarSize,
                          imageScale: 0.78,
                        ),

                        // Middle
                        _RadarAvatar(
                          center: onRing(_middleR, -0.90, -0.44),
                          asset: AssetPaths.introAvatarGreen,
                          fill: _green,
                          glow: _green,
                          glowBlur: 16,
                          size: avatarSize,
                          imageScale: 0.78,
                        ),
                        _RadarAvatar(
                          center: onRing(_middleR, 0.95, 0.30),
                          asset: AssetPaths.introAvatarPink,
                          fill: _pink,
                          glow: _pink,
                          glowBlur: 10,
                          size: avatarSize,
                        ),

                        // Inner
                        _RadarAvatar(
                          center: onRing(_innerR, 0.78, -0.62),
                          asset: AssetPaths.introAvatarPurple2,
                          fill: _purple,
                          glow: _purple,
                          glowBlur: 10,
                          size: avatarSize,
                        ),
                        _RadarAvatar(
                          center: onRing(_innerR, -0.55, 0.84),
                          asset: AssetPaths.introAvatarWhite,
                          fill: _whiteFill,
                          glow: _whiteGlow,
                          glowBlur: 10,
                          glowOpacity: 1,
                          size: avatarSize,
                          imageScale: 0.78,
                        ),
                      ],
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

class _RadarRing extends StatelessWidget {
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

class _RadarAvatar extends StatelessWidget {
  const _RadarAvatar({
    required this.center,
    required this.asset,
    required this.fill,
    required this.glow,
    required this.glowBlur,
    required this.size,
    this.glowOpacity = 0.5,
    this.imageScale = 1,
  });

  final Offset center;
  final String asset;
  final Color fill;
  final Color glow;
  final double glowBlur;
  final double glowOpacity;
  final double size;
  final double imageScale;

  @override
  Widget build(BuildContext context) {
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
        child: imageScale >= 1
            ? Image.asset(
                asset,
                fit: BoxFit.cover,
                alignment: const Alignment(0, -0.12),
              )
            : Transform.scale(
                scale: imageScale,
                child: Image.asset(
                  asset,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                ),
              ),
      ),
    );
  }
}
