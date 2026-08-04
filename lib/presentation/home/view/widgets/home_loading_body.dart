part of '../home_view.dart';

class HomeLoadingBody extends StatelessWidget {
  const HomeLoadingBody({super.key});

  static const _base = Color(0xFFE8E8E8);
  static const _highlight = Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Real header — no need to shimmer brand chrome.
          const HomeHeaderSection(hasUnreadMessages: false),
          Expanded(
            child: Shimmer.fromColors(
              baseColor: _base,
              highlightColor: _highlight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 105,
                    child: ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 6,
                      separatorBuilder: (_, _) => const SizedBox(width: 20),
                      itemBuilder: (_, _) => const SizedBox(
                        width: 68,
                        child: Column(
                          children: [
                            _ShimmerCircle(size: 68),
                            SizedBox(height: 8),
                            _ShimmerBox(width: 48, height: 10, radius: 4),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          const ColoredBox(color: AppColors.white),
                          // Soft map-area wash
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.offWhite.withValues(
                                  alpha: 0.85,
                                ),
                              ),
                            ),
                          ),
                          const Positioned(
                            left: 16,
                            top: 12,
                            child: _ShimmerBox(
                              width: 110,
                              height: 36,
                              radius: 999,
                            ),
                          ),
                          const Positioned(
                            right: 16,
                            top: 12,
                            child: _ShimmerCircle(size: 40),
                          ),
                          const Center(child: _ShimmerCircle(size: 64)),
                          Positioned(
                            left: 20,
                            bottom:
                                MainWrapper.navBarHeight +
                                MediaQuery.paddingOf(context).bottom +
                                8,
                            child: const _ShimmerCircle(size: 48),
                          ),
                          Positioned(
                            right: 20,
                            bottom:
                                MainWrapper.navBarHeight +
                                MediaQuery.paddingOf(context).bottom +
                                8,
                            child: const _ShimmerCircle(size: 56),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _ShimmerCircle extends StatelessWidget {
  const _ShimmerCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}
