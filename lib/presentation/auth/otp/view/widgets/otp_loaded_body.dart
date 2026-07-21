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
          const Text(
            'Kodu gir',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w500,
              height: 48 / 36,
              letterSpacing: -0.72,
              color: AppColors.deepRoast,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$formattedPhone numarasına 6 haneli doğrulama kodu gönderdik.',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 20 / 16,
              color: AppColors.textSecondary,
              letterSpacing: -0.32,
            ),
          ),
          const SizedBox(height: 20),
          OtpInputField(
            code: code,
            onChanged: onCodeChanged,
          ),
          const SizedBox(height: 16),
          _ResendRow(
            canResend: canResend,
            resendSeconds: resendSeconds,
            isResending: isResending,
            onResend: onResend,
          ),
          const Spacer(),
          AppButton(
            label: isLoading ? 'Doğrulanıyor...' : 'Doğrula',
            onPressed: isVerifyEnabled ? onVerify : null,
          ),
        ],
      ),
    );
  }
}

class _ResendRow extends StatelessWidget {
  const _ResendRow({
    required this.canResend,
    required this.resendSeconds,
    required this.isResending,
    required this.onResend,
  });

  final bool canResend;
  final int resendSeconds;
  final bool isResending;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 20 / 16,
          letterSpacing: -0.32,
        ),
        children: [
          const TextSpan(
            text: 'Kodu almadın mı? ',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: canResend && !isResending ? onResend : null,
              child: Text(
                isResending
                    ? 'Gönderiliyor...'
                    : canResend
                        ? 'Tekrar gönder'
                        : 'Tekrar gönder (${resendSeconds}s)',
                style: TextStyle(
                  color: canResend && !isResending
                      ? AppColors.zoviOrange
                      : AppColors.zoviOrange.withValues(alpha: 0.65),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 20 / 16,
                  letterSpacing: -0.32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
