part of '../onboarding_view.dart';

mixin OnboardingViewMixin on State<OnboardingView> {
  void showErrorSnackbar(String message) {
    AppSnackbar.instance.show(context, message, isError: true);
  }

  void onPhoneChanged(String value) {
    context.read<OnboardingBloc>().add(OnboardingPhoneChanged(value));
  }

  void onSendCode() {
    context.read<OnboardingBloc>().add(const OnboardingSendCodeTapped());
  }

  Future<void> onGoogle() async {
    await context.read<OnboardingBloc>().signInWithGoogle().withLoading(context);
    if (!mounted) return;
    context.go(
      RoutePaths.createProfile.path,
      extra: const CreateProfileRouteArgs(signupFlow: SignupFlow.social),
    );
  }

  Future<void> onApple() async {
    await context.read<OnboardingBloc>().signInWithApple().withLoading(context);
    if (!mounted) return;
    context.go(
      RoutePaths.createProfile.path,
      extra: const CreateProfileRouteArgs(signupFlow: SignupFlow.social),
    );
  }

  Future<void> onCountryTap(Country selectedCountry) async {
    final country = await CountryPickerSheet.show(
      context,
      selectedCountry: selectedCountry,
    );
    if (country == null || !mounted) return;
    context.read<OnboardingBloc>().add(OnboardingCountryChanged(country));
  }
}
