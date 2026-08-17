part of '../onboarding_view.dart';

class OnboardingLoadedBody extends StatelessWidget {
  const OnboardingLoadedBody({
    required this.phone,
    required this.selectedCountry,
    required this.isLoading,
    required this.onPhoneChanged,
    required this.onCountryTap,
    required this.onSendCode,
    required this.onGoogle,
    required this.onApple,
    super.key,
  });

  final String phone;
  final Country selectedCountry;
  final bool isLoading;
  final ValueChanged<String> onPhoneChanged;
  final Future<void> Function(Country selectedCountry) onCountryTap;
  final VoidCallback onSendCode;
  final Future<void> Function() onGoogle;
  final Future<void> Function() onApple;

  @override
  Widget build(BuildContext context) {
    final phoneFormat = PhoneFormats.forCountry(selectedCountry.isoCode);
    final canSendCode =
        phoneFormat.isComplete(phone) && !isLoading;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AuthProgressBar(activeIndex: 0, stepCount: 4),
                  const SizedBox(height: 20),
                  Text(
                    'onboarding_title'.tr(),
                    style: const TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.w500,
                      height: 1.33,
                      letterSpacing: -0.72,
                      color: AppColors.deepRoast,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'onboarding_subtitle'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      letterSpacing: -0.32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  OnboardingPhoneField(
                    phone: phone,
                    selectedCountry: selectedCountry,
                    onChanged: onPhoneChanged,
                    onCountryTap: () => onCountryTap(selectedCountry),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 65,
                        height: 1,
                        color: AppColors.textSecondary,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'or'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            height: 20 / 16,
                            letterSpacing: -0.32,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Container(
                        width: 65,
                        height: 1,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SocialLoginButton(
                    label: 'continue_with_google'.tr(),
                    iconPath: AssetPaths.iconGoogle,
                    onTap: () {
                      onGoogle();
                    },
                  ),
                  const SizedBox(height: 10),
                  SocialLoginButton(
                    label: 'continue_with_apple'.tr(),
                    iconPath: AssetPaths.iconApple,
                    onTap: () {
                      onApple();
                    },
                  ),
                ],
              ),
            ),
          ),
          Text.rich(
            TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.black,
                height: 1.4,
              ),
              children: [
                TextSpan(text: 'terms_prefix'.tr()),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse(StringConstants.termsUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    child: Text(
                      'terms_link'.tr(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.zoviOrange,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                TextSpan(text: 'terms_suffix'.tr()),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          AppButton(
            label: isLoading ? 'sending'.tr() : 'send_code'.tr(),
            onPressed: canSendCode ? onSendCode : null,
          ),
        ],
      ),
    );
  }
}
