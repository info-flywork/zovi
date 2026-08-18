part of '../intro_view.dart';

@immutable
final class IntroLoadedBody extends StatelessWidget {
  const IntroLoadedBody({
    required this.pageController,
    required this.pageIndex,
    required this.onPageChanged,
    required this.onContinue,
    required this.onGetStarted,
    super.key,
  });

  final PageController pageController;
  final int pageIndex;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onContinue;
  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    final isLast = pageIndex >= IntroBloc.pageCount - 1;

    return Column(
      children: [
        Expanded(
          child: PageView(
            physics: ClampingScrollPhysics(),
            controller: pageController,
            onPageChanged: onPageChanged,
            clipBehavior: Clip.hardEdge,
            children: [
              _IntroPageClip(child: IntroAroundPage()),
              _IntroPageClip(child: IntroPulsePage(isActive: pageIndex == 1)),
              _IntroPageClip(child: IntroStampsPage(isActive: pageIndex == 2)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: AppButton(
            label: isLast ? 'get_started'.tr() : 'continue'.tr(),
            onPressed: isLast ? onGetStarted : onContinue,
          ),
        ),
      ],
    );
  }
}

/// Clips each intro page so overflowing content cannot paint on adjacent pages.
@immutable
final class _IntroPageClip extends StatelessWidget {
  const _IntroPageClip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(child: child);
  }
}
