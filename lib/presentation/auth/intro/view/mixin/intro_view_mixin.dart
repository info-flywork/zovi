part of '../intro_view.dart';

mixin IntroViewMixin on State<IntroView> {
  late final PageController pageController;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void syncPage(int index) {
    if (!pageController.hasClients) return;
    if (pageController.page?.round() == index) return;
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void onPageChanged(int index) {
    context.read<IntroBloc>().add(IntroPageChanged(index));
  }

  void onContinue() {
    context.read<IntroBloc>().add(const IntroContinueTapped());
  }

  void onGetStarted() {
    context.read<IntroBloc>().add(const IntroGetStartedTapped());
  }
}
