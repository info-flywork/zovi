import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/widgets/app_button.dart';
import 'package:zovi/domain/user/user_repository.dart';

const _unlockStamps = [
  StampItem(imagePath: AssetPaths.stickerNightFlame, title: 'Night Flame'),
  StampItem(imagePath: AssetPaths.stickerExplorer, title: 'Explorer'),
  StampItem(imagePath: AssetPaths.stamp1, title: 'After Hours'),
  StampItem(imagePath: AssetPaths.stamp2, title: 'VIP Pass'),
  StampItem(imagePath: AssetPaths.stamp3, title: 'DJ Booth'),
  StampItem(imagePath: AssetPaths.stamp4, title: 'Surf Mode'),
  StampItem(imagePath: AssetPaths.stamp5, title: 'Barista'),
  StampItem(imagePath: AssetPaths.stamp6, title: 'Brunch Club'),
  StampItem(imagePath: AssetPaths.stamp7, title: 'Globetrotter'),
  StampItem(imagePath: AssetPaths.stamp8, title: 'Need Coffee'),
  StampItem(imagePath: AssetPaths.stamp9, title: 'Power Duo'),
  StampItem(imagePath: AssetPaths.stamp10, title: 'On The Decks'),
  StampItem(imagePath: AssetPaths.stamp11, title: 'Soulmates'),
  StampItem(imagePath: AssetPaths.stamp12, title: 'Day & Night'),
  StampItem(imagePath: AssetPaths.stamp13, title: 'Music Fest'),
  StampItem(imagePath: AssetPaths.stamp14, title: 'Spark Pals'),
  StampItem(imagePath: AssetPaths.stamp15, title: 'Foodies'),
  StampItem(imagePath: AssetPaths.stamp16, title: 'Founder'),
  StampItem(imagePath: AssetPaths.stamp17, title: 'Peekaboo'),
];

/// Returns the unlocked stamp when user taps "Add to my check-in",
/// or `null` when they tap "Not now" / dismiss.
Future<StampItem?> showCheckInUnlockStampSheet(BuildContext context) {
  final stamp = _unlockStamps[Random().nextInt(_unlockStamps.length)];
  return showModalBottomSheet<StampItem>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => CheckInUnlockStampSheet(stamp: stamp),
  );
}

class CheckInUnlockStampSheet extends StatelessWidget {
  const CheckInUnlockStampSheet({required this.stamp, super.key});

  final StampItem stamp;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          kBottomNavigationBarHeight / 2,
        ),
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
              'check_in_unlock_you_unlocked'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1,
                letterSpacing: -0.32,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              stamp.title,
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
            Image.asset(
              stamp.imagePath,
              width: 180,
              height: 180,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'check_in_unlock_add'.tr(),
              height: 50,
              onPressed: () => Navigator.of(context).pop(stamp),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'check_in_unlock_not_now'.tr(),
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
