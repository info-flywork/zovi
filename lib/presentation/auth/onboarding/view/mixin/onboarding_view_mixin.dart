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

  void onGoogle() {
    context.read<OnboardingBloc>().add(const OnboardingGoogleTapped());
  }

  void onApple() {
    context.read<OnboardingBloc>().add(const OnboardingAppleTapped());
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
