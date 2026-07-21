part of '../birthday_view.dart';

class BirthdayLoadedBody extends StatelessWidget {
  const BirthdayLoadedBody({
    required this.birthDate,
    required this.stepCount,
    required this.activeStepIndex,
    required this.isLoading,
    required this.onDateChanged,
    required this.onContinue,
    super.key,
  });

  final DateTime birthDate;
  final int stepCount;
  final int activeStepIndex;
  final bool isLoading;
  final ValueChanged<DateTime> onDateChanged;
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
          const Text(
            'When\'s your birthday?',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w500,
              height: 48 / 36,
              letterSpacing: -0.72,
              color: AppColors.deepRoast,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'We require your birthday to keep Zovi a safe place. This won\'t be shown publicly.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 20 / 16,
              letterSpacing: -0.32,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Date of birth',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 20 / 16,
              letterSpacing: -0.32,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 64,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0x0D000000)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.zoviOrange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const AppIcon(AssetPaths.iconBirth, size: 24),
                ),
                const SizedBox(width: 10),
                Text(
                  formatBirthDate(birthDate),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 20 / 16,
                    letterSpacing: -0.32,
                    color: AppColors.black.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          BirthdayDatePicker(
            birthDate: birthDate,
            onDateChanged: onDateChanged,
          ),
          const Spacer(),
          AppButton(
            label: isLoading ? 'Continuing...' : 'Continue',
            onPressed: isLoading ? null : onContinue,
          ),
        ],
      ),
    );
  }
}
