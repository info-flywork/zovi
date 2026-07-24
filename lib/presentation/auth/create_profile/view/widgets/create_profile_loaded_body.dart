part of '../create_profile_view.dart';

class CreateProfileLoadedBody extends StatelessWidget {
  const CreateProfileLoadedBody({
    required this.fullName,
    required this.username,
    required this.stepCount,
    required this.activeStepIndex,
    required this.isLoading,
    required this.onFullNameChanged,
    required this.onUsernameChanged,
    required this.onContinue,
    super.key,
  });

  final String fullName;
  final String username;
  final int stepCount;
  final int activeStepIndex;
  final bool isLoading;
  final ValueChanged<String> onFullNameChanged;
  final ValueChanged<String> onUsernameChanged;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final canContinue =
        fullName.trim().isNotEmpty && username.trim().isNotEmpty && !isLoading;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthProgressBar(
            activeIndex: activeStepIndex,
            stepCount: stepCount,
          ),
          const SizedBox(height: 20),
          Text(
            'create_profile_title'.tr(),
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
            'create_profile_subtitle'.tr(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 20 / 16,
              letterSpacing: -0.32,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          ProfileTextField(
            label: 'full_name'.tr(),
            hint: 'full_name_hint'.tr(),
            iconPath: AssetPaths.iconUser,
            iconBackgroundColor: const Color(0x337B2FFF),
            value: fullName,
            onChanged: onFullNameChanged,
            textCapitalization: TextCapitalization.words,
            inputFormatters: const [FullNameLengthLimitingFormatter()],
          ),
          const SizedBox(height: 20),
          ProfileTextField(
            label: 'username'.tr(),
            hint: 'username_hint'.tr(),
            iconPath: AssetPaths.iconAt,
            iconBackgroundColor: const Color(0x3300C896),
            value: username,
            onChanged: onUsernameChanged,
            inputFormatters: [
              LengthLimitingTextInputFormatter(
                FullNameLengthLimitingFormatter.usernameMax,
              ),
            ],
          ),
          const Spacer(),
          AppButton(
            label: isLoading ? 'continuing'.tr() : 'continue'.tr(),
            onPressed: canContinue ? onContinue : null,
          ),
        ],
      ),
    );
  }
}
