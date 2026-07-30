import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/snackbar/app_snackbar.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/extensions/future_extensions.dart';
import 'package:zovi/core/utils/phone/phone_format.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/domain/auth/auth_repository.dart';
import 'package:zovi/presentation/profile/settings/view/widgets/delete_account_sheet.dart';

class PersonalInfoView extends StatelessWidget {
  const PersonalInfoView({super.key});

  static const _monthKeys = [
    'month_january',
    'month_february',
    'month_march',
    'month_april',
    'month_may',
    'month_june',
    'month_july',
    'month_august',
    'month_september',
    'month_october',
    'month_november',
    'month_december',
  ];

  String _formatBirthday(BuildContext context, DateTime birthday) {
    final month = _monthKeys[birthday.month - 1].tr();
    if (context.locale.languageCode == 'tr') {
      return '${birthday.day} $month ${birthday.year}';
    }
    return '$month ${birthday.day}, ${birthday.year}';
  }

  String _formatContact(CachedPersonalInfo? info) {
    if (info == null) return '-';
    if (info.isPhoneAuth) {
      final phone = info.phoneE164.trim();
      if (phone.isEmpty) return '-';
      return PhoneFormats.formatE164(phone);
    }
    final email = info.email.trim();
    return email.isEmpty ? '-' : email;
  }

  Future<void> _onDeleteAccount(BuildContext context) async {
    final reason = await showDeleteAccountSheet(context);
    if (reason == null || !context.mounted) return;

    try {
      await getIt<AuthRepository>()
          .requestAccountDeletion(reason: reason)
          .withLoading(context);
      if (!context.mounted) return;
      AppSnackbar.instance.show(
        context,
        'delete_account_request_received'.tr(),
      );
    } catch (_) {
      if (!context.mounted) return;
      AppSnackbar.instance.show(
        context,
        'delete_account_request_failed'.tr(),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = getIt<AuthRepository>().cachedPersonalInfo;
    final isPhone = info?.isPhoneAuth ?? true;
    final contactText = _formatContact(info);
    final birthday = info?.birthDate;
    final birthdayText = birthday == null
        ? '-'
        : _formatBirthday(context, birthday);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PersonalInfoHeader(),
            Expanded(
              child: ListView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Text(
                    'personal_info_subtitle'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 20 / 16,
                      letterSpacing: -0.32,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _InfoRow(
                    label: isPhone
                        ? 'personal_info_phone'.tr()
                        : 'personal_info_email'.tr(),
                    value: contactText,
                  ),
                  const _PersonalInfoDivider(),
                  _InfoRow(
                    label: 'personal_info_birthday'.tr(),
                    value: birthdayText,
                  ),
                  const _PersonalInfoDivider(),
                  GestureDetector(
                    onTap: () => _onDeleteAccount(context),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'personal_info_delete_account'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1,
                          letterSpacing: -0.32,
                          color: AppColors.logoutRed,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonalInfoHeader extends StatelessWidget {
  const _PersonalInfoHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            behavior: HitTestBehavior.opaque,
            child: const AppIcon(AssetPaths.iconBack, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            'personal_info_title'.tr(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1,
              letterSpacing: -0.32,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1,
              letterSpacing: -0.32,
              color: AppColors.deepRoast,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1,
              letterSpacing: -0.28,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalInfoDivider extends StatelessWidget {
  const _PersonalInfoDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: AppColors.borderLight);
  }
}
