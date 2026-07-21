part of '../intro_view.dart';

class IntroPulsePage extends StatelessWidget {
  const IntroPulsePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: Text(
            textAlign: TextAlign.center,
            'Capture the moment, keep it alive for 24 hours',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w600,
              height: 1.2,
              letterSpacing: -0.6,
              color: AppColors.deepRoast,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            textAlign: TextAlign.center,
            'Take a Pulse from wherever you are. Keep it temporary or pin it to a location—the choice is yours.',
            style: TextStyle(
              fontSize: 16,
              height: 1.35,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenW = MediaQuery.sizeOf(context).width;
              final h = constraints.maxHeight;
              final cardW = screenW * 0.62;
              final cardH = math.min(h * 0.95, cardW * 1.55);

              return SizedBox(
                width: screenW,
                height: h,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Jhon — overflows left
                    Positioned(
                      left: -screenW * 0.04,
                      top: h * 0.04,
                      child: Transform.rotate(
                        angle: -0.10,
                        child: _PulseCard(
                          image: AssetPaths.pulseJhon,
                          name: 'Jhon',
                          place: 'Babylon, Istanbul',
                          width: cardW,
                          height: cardH * 1.05,
                        ),
                      ),
                    ),
                    // Jessica — overflows right
                    Positioned(
                      right: -screenW * 0.07,
                      top: h * 0.16,
                      child: Transform.rotate(
                        angle: 0.24,
                        child: _PulseCard(
                          image: AssetPaths.pulseJessica,
                          name: 'Jessica',
                          place: 'Beyoglu, Istanbul',
                          width: cardW,
                          height: cardH * 1.05,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PulseCard extends StatelessWidget {
  const _PulseCard({
    required this.image,
    required this.name,
    required this.place,
    required this.width,
    required this.height,
  });

  final String image;
  final String name;
  final String place;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(image, fit: BoxFit.cover, alignment: Alignment.topCenter),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Color(0xCC000000),
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const AppIcon(
                      "assets/icons/location.svg",
                      size: 18,
                      color: AppColors.zoviOrange,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        place,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
