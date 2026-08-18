import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/widgets/app_button.dart';

const _destructiveRed = Color(0xFFEC1C24);

enum ProfileConnectionConfirmAction { removeFollower, unfollow }

Future<bool> showProfileConnectionConfirmSheet(
  BuildContext context, {
  required ProfileConnectionConfirmAction action,
  required String username,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => ProfileConnectionConfirmSheet(
      action: action,
      username: username,
    ),
  );
  return result ?? false;
}

@immutable
final class ProfileConnectionConfirmSheet extends StatelessWidget {
  const ProfileConnectionConfirmSheet({
    required this.action,
    required this.username,
    super.key,
  });

  final ProfileConnectionConfirmAction action;
  final String username;

  @override
  Widget build(BuildContext context) {
    final isRemoveFollower =
        action == ProfileConnectionConfirmAction.removeFollower;
    final title = isRemoveFollower
        ? 'profile_connections_remove_follower_title'.tr()
        : 'profile_connections_unfollow_title'.tr();
    final subtitleTemplate = isRemoveFollower
        ? 'profile_connections_remove_follower_subtitle'.tr()
        : 'profile_connections_unfollow_subtitle'.tr();
    final confirmLabel = isRemoveFollower
        ? 'profile_connections_remove_follower_confirm'.tr()
        : 'profile_connections_unfollow_confirm'.tr();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.progressInactive,
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
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
            _UsernameSubtitle(
              template: subtitleTemplate,
              username: username,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'cancel'.tr(),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(true),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  confirmLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 20 / 16,
                    color: _destructiveRed,
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

@immutable
final class _UsernameSubtitle extends StatelessWidget {
  const _UsernameSubtitle({
    required this.template,
    required this.username,
  });

  final String template;
  final String username;

  static const _baseStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 20 / 16,
    letterSpacing: -0.32,
    color: AppColors.textSecondary,
  );

  static const _usernameStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 20 / 16,
    letterSpacing: -0.32,
    color: AppColors.black,
  );

  @override
  Widget build(BuildContext context) {
    final parts = template.split('{username}');
    return Text.rich(
      TextSpan(
        style: _baseStyle,
        children: [
          TextSpan(text: parts.first),
          TextSpan(text: username, style: _usernameStyle),
          if (parts.length > 1) TextSpan(text: parts.sublist(1).join('{username}')),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
