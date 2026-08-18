import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/widgets/app_button.dart';
import 'package:zovi/core/widgets/app_icon.dart';

enum ShareContentType { pulse, checkIn, story }

Future<ShareContentType?> showShareContentSheet(BuildContext context) {
  return showModalBottomSheet<ShareContentType>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const ShareContentSheet(),
  );
}

@immutable
final class ShareContentSheet extends StatefulWidget {
  const ShareContentSheet({super.key});

  @override
  State<ShareContentSheet> createState() => _ShareContentSheetState();
}

final class _ShareContentSheetState extends State<ShareContentSheet> {
  ShareContentType _selected = ShareContentType.pulse;

  static const _selectedBg = Color(0xFFF4F4F9);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 46,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.progressInactive,
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'share_content_title'.tr(),
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
              'share_content_subtitle'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 20 / 16,
                letterSpacing: -0.32,
                color: AppColors.deepRoast.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 20),
            _ShareContentOption(
              icon: AssetPaths.iconEnergy,
              title: 'share_content_pulse'.tr(),
              subtitle: 'share_content_pulse_subtitle'.tr(),
              selected: _selected == ShareContentType.pulse,
              selectedBg: _selectedBg,
              onTap: () => setState(() => _selected = ShareContentType.pulse),
            ),
            const SizedBox(height: 10),
            _ShareContentOption(
              icon: AssetPaths.iconLocation,
              title: 'share_content_check_in'.tr(),
              subtitle: 'share_content_check_in_subtitle'.tr(),
              selected: _selected == ShareContentType.checkIn,
              selectedBg: _selectedBg,
              onTap: () => setState(() => _selected = ShareContentType.checkIn),
            ),
            const SizedBox(height: 10),
            _ShareContentOption(
              icon: AssetPaths.iconStory,
              title: 'share_content_story'.tr(),
              subtitle: 'share_content_story_subtitle'.tr(),
              selected: _selected == ShareContentType.story,
              selectedBg: _selectedBg,
              onTap: () => setState(() => _selected = ShareContentType.story),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'done'.tr(),
              onPressed: () => Navigator.of(context).pop(_selected),
            ),
          ],
        ),
      ),
    );
  }
}

@immutable
final class _ShareContentOption extends StatelessWidget {
  const _ShareContentOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.selectedBg,
    required this.onTap,
  });

  final String icon;
  final String title;
  final String subtitle;
  final bool selected;
  final Color selectedBg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? selectedBg : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected ? AppColors.white : const Color(0xFFF4F4F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: AppIcon(icon, size: 24, color: AppColors.black),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 20 / 16,
                      letterSpacing: -0.32,
                      color: AppColors.deepRoast,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 20 / 14,
                      letterSpacing: -0.28,
                      color: AppColors.textSecondary,
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
