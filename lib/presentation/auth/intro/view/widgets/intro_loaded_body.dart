part of '../intro_view.dart';

class IntroLoadedBody extends StatelessWidget {
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
            children: const [
              _IntroPageClip(child: IntroAroundPage()),
              _IntroPageClip(child: IntroPulsePage()),
              _IntroPageClip(child: IntroStampsPage()),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: AppButton(
            label: isLast ? 'Get Started' : 'Continue',
            onPressed: isLast ? onGetStarted : onContinue,
          ),
        ),
      ],
    );
  }
}

/// Clips each intro page so overflowing content cannot paint on adjacent pages.
class _IntroPageClip extends StatelessWidget {
  const _IntroPageClip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(child: child);
  }
}
