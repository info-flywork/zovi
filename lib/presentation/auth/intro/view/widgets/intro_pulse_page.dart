part of '../intro_view.dart';

class IntroPulsePage extends StatefulWidget {
  const IntroPulsePage({super.key, this.isActive = false});

  final bool isActive;

  @override
  State<IntroPulsePage> createState() => _IntroPulsePageState();
}

class _IntroPulsePageState extends State<IntroPulsePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _jhonSlide;
  late final Animation<double> _jessicaSlide;
  late final Animation<double> _cardsFade;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _textFade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0, 0.45, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0, 0.45, curve: Curves.easeOutCubic),
      ),
    );

    _jhonSlide = Tween<double>(begin: -1, end: 0).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.12, 0.72, curve: Curves.easeOutCubic),
      ),
    );
    _jessicaSlide = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.22, 0.85, curve: Curves.easeOutCubic),
      ),
    );
    _cardsFade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.12, 0.55, curve: Curves.easeOut),
    );

    if (widget.isActive) {
      _enter.forward();
    }
  }

  @override
  void didUpdateWidget(covariant IntroPulsePage oldWidget) {
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
    return AnimatedBuilder(
      animation: _enter,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeTransition(
              opacity: _textFade,
              child: SlideTransition(
                position: _textSlide,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                      child: Text(
                        textAlign: TextAlign.center,
                        'intro_pulse_title'.tr(),
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          letterSpacing: -0.6,
                          color: AppColors.deepRoast,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        textAlign: TextAlign.center,
                        'intro_pulse_subtitle'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.35,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
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
                  final slideDistance = screenW * 0.85;

                  return SizedBox(
                    width: screenW,
                    height: h,
                    child: Opacity(
                      opacity: _cardsFade.value,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Jhon — from left
                          Positioned(
                            left: -screenW * 0.04,
                            top: h * 0.04,
                            child: Transform.translate(
                              offset: Offset(
                                _jhonSlide.value * slideDistance,
                                0,
                              ),
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
                          ),
                          // Jessica — from right
                          Positioned(
                            right: -screenW * 0.07,
                            top: h * 0.16,
                            child: Transform.translate(
                              offset: Offset(
                                _jessicaSlide.value * slideDistance,
                                0,
                              ),
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
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
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
                      'assets/icons/location.svg',
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
