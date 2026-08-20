part of '../onboarding_view.dart';

@immutable
final class SocialLoginButton extends StatelessWidget {
  const SocialLoginButton({
    required this.label,
    required this.iconPath,
    required this.onTap,
    this.backgroundColor = AppColors.white,
    this.foregroundColor = AppColors.deepRoast,
    this.borderColor = AppColors.borderLight,
    super.key,
  });

  final String label;
  final String iconPath;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      onPressed: onTap,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      borderColor: borderColor,
      height: 56,
      leading: AppIcon(iconPath, size: 22),
    );
  }
}
