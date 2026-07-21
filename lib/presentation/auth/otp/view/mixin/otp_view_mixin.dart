part of '../otp_view.dart';

mixin OtpViewMixin on State<OtpView> {
  void showErrorSnackbar(String message) {
    AppSnackbar.instance.show(context, message, isError: true);
  }

  String formattedPhone(OtpState state) {
    final format = PhoneFormats.forCountry(state.selectedCountry.isoCode);
    return '${state.selectedCountry.dialCode} ${format.formatDigits(state.phone)}';
  }

  void onCodeChanged(String value) {
    context.read<OtpBloc>().add(OtpCodeChanged(value));
  }

  void onVerify() {
    context.read<OtpBloc>().add(const OtpVerifyTapped());
  }

  void onResend() {
    context.read<OtpBloc>().add(const OtpResendTapped());
  }
}
