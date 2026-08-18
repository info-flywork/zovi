import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:zovi/core/theme/app_colors.dart';

enum UserProfileAction { restrict, block, report }

const _actionRed = Color(0xFFE50048);

Future<UserProfileAction?> showUserProfileActionsSheet(
  BuildContext context, {
  bool isBlocked = false,
  bool isRestricted = false,
  bool isReported = false,
}) {
  return showModalBottomSheet<UserProfileAction>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (context) => UserProfileActionsSheet(
      isBlocked: isBlocked,
      isRestricted: isRestricted,
      isReported: isReported,
    ),
  );
}

@immutable
final class UserProfileActionsSheet extends StatelessWidget {
  const UserProfileActionsSheet({
    this.isBlocked = false,
    this.isRestricted = false,
    this.isReported = false,
    super.key,
  });

  final bool isBlocked;
  final bool isRestricted;
  final bool isReported;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _ActionItem(
                    label: isRestricted
                        ? 'user_profile_unrestrict'.tr()
                        : 'user_profile_restrict'.tr(),
                    onTap: () =>
                        Navigator.of(context).pop(UserProfileAction.restrict),
                  ),
                  const SizedBox(height: 10),
                  _ActionItem(
                    label: isBlocked
                        ? 'user_profile_unblock'.tr()
                        : 'user_profile_block'.tr(),
                    onTap: () =>
                        Navigator.of(context).pop(UserProfileAction.block),
                  ),
                  const SizedBox(height: 10),
                  _ActionItem(
                    label: isReported
                        ? 'user_profile_already_reported'.tr()
                        : 'user_profile_report'.tr(),
                    enabled: !isReported,
                    onTap: isReported
                        ? null
                        : () => Navigator.of(context)
                            .pop(UserProfileAction.report),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: double.infinity,
                height: 56,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  'cancel'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1,
                    letterSpacing: -0.32,
                    color: AppColors.deepRoast,
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
final class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.label,
    this.onTap,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: double.infinity,
        height: 44,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1,
              letterSpacing: -0.32,
              color: enabled ? _actionRed : AppColors.mutedGray,
            ),
          ),
        ),
      ),
    );
  }
}
