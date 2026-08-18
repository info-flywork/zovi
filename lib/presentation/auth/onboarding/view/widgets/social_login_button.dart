part of '../onboarding_view.dart';

@immutable
final class SocialLoginButton extends StatelessWidget {
  const SocialLoginButton({
    required this.label,
    required this.iconPath,
    required this.onTap,
    super.key,
  });

  final String label;
  final String iconPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      onPressed: onTap,
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.deepRoast,
      borderColor: AppColors.borderLight,
      height: 56,
      leading: AppIcon(iconPath, size: 22),
    );
  }
}
