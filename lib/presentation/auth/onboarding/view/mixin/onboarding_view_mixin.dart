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

  Future<void> _goAfterAuth(AuthSession session) async {
    if (session.nextStep == 'home') {
      try {
        await getIt<UserRepository>().getCurrentUser();
      } catch (_) {}
    }
    if (!mounted) return;
    final dest = session.destination;
    if (dest.extra != null) {
      context.go(dest.path, extra: dest.extra);
    } else {
      context.go(dest.path);
    }
  }

  Future<void> onGoogle() async {
    try {
      final session = await context
          .read<OnboardingBloc>()
          .signInWithGoogle()
          .withLoading(context);
      if (!mounted) return;
      _goAfterAuth(session);
    } on GoogleSignInException catch (e) {
      // ignore: avoid_print
      print('google_sign_in_failed code=${e.code} desc=${e.description}');
      if (!mounted) return;
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return;
      }
      showErrorSnackbar('error_google_sign_in'.tr());
    } catch (e) {
      // ignore: avoid_print
      print('google_sign_in_failed error=$e');
      if (!mounted) return;
      showErrorSnackbar('error_google_sign_in'.tr());
    }
  }

  Future<void> onApple() async {
    try {
      final session = await context
          .read<OnboardingBloc>()
          .signInWithApple()
          .withLoading(context);
      if (!mounted) return;
      _goAfterAuth(session);
    } catch (_) {
      if (!mounted) return;
      showErrorSnackbar('error_apple_sign_in'.tr());
    }
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
