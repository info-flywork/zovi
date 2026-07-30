part of '../create_profile_view.dart';

class CreateProfileLoadedBody extends StatelessWidget {
  const CreateProfileLoadedBody({
    required this.fullName,
    required this.username,
    required this.stepCount,
    required this.activeStepIndex,
    required this.isLoading,
    required this.usernameStatus,
    required this.usernameSuggestions,
    required this.canContinue,
    required this.onFullNameChanged,
    required this.onUsernameChanged,
    required this.onSuggestionSelected,
    required this.onContinue,
    super.key,
  });

  final String fullName;
  final String username;
  final int stepCount;
  final int activeStepIndex;
  final bool isLoading;
  final UsernameAvailabilityStatus usernameStatus;
  final List<String> usernameSuggestions;
  final bool canContinue;
  final ValueChanged<String> onFullNameChanged;
  final ValueChanged<String> onUsernameChanged;
  final ValueChanged<String> onSuggestionSelected;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthProgressBar(activeIndex: activeStepIndex, stepCount: stepCount),
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
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
              LengthLimitingTextInputFormatter(
                FullNameLengthLimitingFormatter.usernameMax,
              ),
            ],
          ),
          if (usernameStatus != UsernameAvailabilityStatus.idle) ...[
            const SizedBox(height: 10),
            _UsernameStatusRow(status: usernameStatus),
          ],
          if (usernameStatus == UsernameAvailabilityStatus.taken &&
              usernameSuggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'username_suggestions_title'.tr(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final suggestion in usernameSuggestions)
                  GestureDetector(
                    onTap: () => onSuggestionSelected(suggestion),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceGray,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.borderGray),
                      ),
                      child: Text(
                        suggestion,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.deepRoast,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const Spacer(),
          AppButton(
            label: isLoading ? 'continuing'.tr() : 'continue'.tr(),
            onPressed: canContinue && !isLoading ? onContinue : null,
          ),
        ],
      ),
    );
  }
}

class _UsernameStatusRow extends StatelessWidget {
  const _UsernameStatusRow({required this.status});

  final UsernameAvailabilityStatus status;

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (status) {
      UsernameAvailabilityStatus.checking => (
        'username_checking'.tr(),
        AppColors.textSecondary,
      ),
      UsernameAvailabilityStatus.available => (
        'username_available'.tr(),
        AppColors.mintGreen,
      ),
      UsernameAvailabilityStatus.taken => (
        'username_taken'.tr(),
        AppColors.logoutRed,
      ),
      UsernameAvailabilityStatus.invalid => (
        'username_invalid'.tr(),
        AppColors.logoutRed,
      ),
      UsernameAvailabilityStatus.idle => ('', AppColors.textSecondary),
    };

    if (text.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        if (status == UsernameAvailabilityStatus.checking)
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator.adaptive(),
          )
        else
          Icon(
            status == UsernameAvailabilityStatus.available
                ? Icons.check_circle_outline
                : Icons.error_outline,
            size: 16,
            color: color,
          ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
