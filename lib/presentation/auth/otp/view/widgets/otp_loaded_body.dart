part of '../otp_view.dart';

class OtpLoadedBody extends StatelessWidget {
  const OtpLoadedBody({
    required this.formattedPhone,
    required this.code,
    required this.resendSeconds,
    required this.canResend,
    required this.isLoading,
    required this.isResending,
    required this.onCodeChanged,
    required this.onVerify,
    required this.onResend,
    super.key,
  });

  final String formattedPhone;
  final String code;
  final int resendSeconds;
  final bool canResend;
  final bool isLoading;
  final bool isResending;
  final ValueChanged<String> onCodeChanged;
  final VoidCallback onVerify;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final isVerifyEnabled = code.length == 6 && !isLoading && !isResending;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthProgressBar(activeIndex: 1, stepCount: 4),
          const SizedBox(height: 20),
          Text(
            'otp_title'.tr(),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w500,
              height: 48 / 36,
              letterSpacing: -0.72,
              color: AppColors.deepRoast,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'otp_subtitle'.tr(namedArgs: {'phone': formattedPhone}),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 20 / 16,
              color: AppColors.textSecondary,
              letterSpacing: -0.32,
            ),
          ),
          const SizedBox(height: 20),
          OtpCodeField(
            code: code,
            onChanged: onCodeChanged,
            canResend: canResend,
            resendSeconds: resendSeconds,
            isResending: isResending,
            onResend: onResend,
          ),
          const Spacer(),
          AppButton(
            label: isLoading ? 'verifying'.tr() : 'verify'.tr(),
            onPressed: isVerifyEnabled ? onVerify : null,
          ),
        ],
      ),
    );
  }
}
