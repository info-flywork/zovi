import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/widgets/app_button.dart';
import 'package:zovi/core/widgets/app_icon.dart';

enum CheckInPhotoSource { camera, gallery }

Future<CheckInPhotoSource?> showCheckInAddPhotoSheet(
  BuildContext context, {
  CheckInPhotoSource initial = CheckInPhotoSource.camera,
}) {
  return showModalBottomSheet<CheckInPhotoSource>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => CheckInAddPhotoSheet(initial: initial),
  );
}

class CheckInAddPhotoSheet extends StatefulWidget {
  const CheckInAddPhotoSheet({
    this.initial = CheckInPhotoSource.camera,
    super.key,
  });

  final CheckInPhotoSource initial;

  @override
  State<CheckInAddPhotoSheet> createState() => _CheckInAddPhotoSheetState();
}

class _CheckInAddPhotoSheetState extends State<CheckInAddPhotoSheet> {
  late CheckInPhotoSource _selected;

  static const _selectedBg = Color(0xFFF4F4F9);

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
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
              'check_in_add_photo'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1,
                letterSpacing: -0.4,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 20),
            _PhotoSourceOption(
              key: const ValueKey('photo_source_camera'),
              icon: AssetPaths.iconChatCamera,
              title: 'check_in_photo_camera'.tr(),
              subtitle: 'check_in_photo_camera_subtitle'.tr(),
              selected: _selected == CheckInPhotoSource.camera,
              selectedBg: _selectedBg,
              onTap: () =>
                  setState(() => _selected = CheckInPhotoSource.camera),
            ),
            const SizedBox(height: 10),
            _PhotoSourceOption(
              key: const ValueKey('photo_source_gallery'),
              icon: AssetPaths.iconPhotoGallery,
              title: 'check_in_photo_gallery'.tr(),
              subtitle: 'check_in_photo_gallery_subtitle'.tr(),
              selected: _selected == CheckInPhotoSource.gallery,
              selectedBg: _selectedBg,
              onTap: () =>
                  setState(() => _selected = CheckInPhotoSource.gallery),
            ),
            const SizedBox(height: 30),
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

class _PhotoSourceOption extends StatelessWidget {
  const _PhotoSourceOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.selectedBg,
    required this.onTap,
    super.key,
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
              child: AppIcon(icon, size: 24, color: AppColors.deepRoast),
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
