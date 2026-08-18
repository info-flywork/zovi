import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/widgets/app_button.dart';
import 'package:zovi/core/widgets/profile_avatar.dart';
import 'package:zovi/presentation/profile/user_profile/view/widgets/user_profile_actions_sheet.dart';

enum UserProfileConfirmResult { primary, secondary }

Future<UserProfileConfirmResult?> showUserProfileConfirmSheet(
  BuildContext context, {
  required UserProfileAction action,
  required String username,
  required String avatarPath,
}) {
  return showModalBottomSheet<UserProfileConfirmResult>(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => UserProfileConfirmSheet(
      action: action,
      username: username,
      avatarPath: avatarPath,
    ),
  );
}

@immutable
final class UserProfileConfirmSheet extends StatelessWidget {
  const UserProfileConfirmSheet({
    required this.action,
    required this.username,
    required this.avatarPath,
    super.key,
  });

  final UserProfileAction action;
  final String username;
  final String avatarPath;

  @override
  Widget build(BuildContext context) {
    final (titleKey, subtitleKey, primaryKey, secondaryKey) = switch (action) {
      UserProfileAction.block => (
          'user_profile_block_title',
          'user_profile_block_subtitle',
          'user_profile_block_confirm',
          'user_profile_block_and_report',
        ),
      UserProfileAction.report => (
          'user_profile_report_title',
          'user_profile_report_subtitle',
          'user_profile_report_confirm',
          'user_profile_report_and_block',
        ),
      UserProfileAction.restrict => (
          'user_profile_restrict_title',
          'user_profile_restrict_subtitle',
          'user_profile_restrict_confirm',
          'user_profile_restrict_and_report',
        ),
    };

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProfileAvatar(
              path: avatarPath,
              size: 102,
              showGradientRing: true,
              ringWidth: 3,
            ),
            const SizedBox(height: 10),
            Text(
              titleKey.tr(namedArgs: {'username': username}),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1,
                letterSpacing: -0.4,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitleKey.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 20 / 16,
                letterSpacing: -0.32,
                color: AppColors.deepRoast.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 10),
            AppButton(
              label: primaryKey.tr(),
              height: 50,
              onPressed: () =>
                  Navigator.of(context).pop(UserProfileConfirmResult.primary),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () =>
                  Navigator.of(context).pop(UserProfileConfirmResult.secondary),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  secondaryKey.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 20 / 16,
                    color: AppColors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
