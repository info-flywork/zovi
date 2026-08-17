import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/widgets/app_button.dart';
import 'package:zovi/core/widgets/stamp_image.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/home/model/check_in_success_route_args.dart';

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

const _unlockTitles = [
  TitleUnlockItem(
    emoji: '👑',
    title: 'Kurucu Kral',
    imagePath: AssetPaths.stamp16,
  ),
  TitleUnlockItem(
    emoji: '👑',
    title: 'Gece Kralı',
    imagePath: AssetPaths.stickerNightFlame,
  ),
  TitleUnlockItem(
    emoji: '👑',
    title: 'Keşif Ustası',
    imagePath: AssetPaths.stickerExplorer,
  ),
  TitleUnlockItem(
    emoji: '👑',
    title: 'VIP Efsane',
    imagePath: AssetPaths.stamp2,
  ),
];

class TitleUnlockItem {
  const TitleUnlockItem({
    required this.emoji,
    required this.title,
    required this.imagePath,
    this.networkImageUrl,
  });

  final String emoji;
  final String title;
  final String imagePath;
  final String? networkImageUrl;

  String get label => '$emoji $title';
}

/// Stamp veya unvan; "kaydet" / "add" ile seçilirse dolu, aksi halde `null`.
class CheckInUnlockResult {
  const CheckInUnlockResult.stamp(this.stamp)
    : titleLabel = null,
      titleImagePath = null;

  const CheckInUnlockResult.title({
    required this.titleLabel,
    required this.titleImagePath,
  }) : stamp = null;

  final StampItem? stamp;
  final String? titleLabel;
  final String? titleImagePath;

  bool get isTitle => titleLabel != null;
}

/// Mekanın ilk checin’i için founder stamp + unvan sheet’i.
Future<CheckInUnlockResult?> showCheckInFounderUnlockSheet(
  BuildContext context, {
  required String placeName,
  required CheckInFounderOffer offer,
}) {
  final title = TitleUnlockItem(
    emoji: (offer.titleEmoji?.trim().isNotEmpty == true)
        ? offer.titleEmoji!.trim()
        : '👑',
    title: offer.titleLabel,
    imagePath: AssetPaths.stamp16,
    networkImageUrl: offer.stampImageUrl,
  );
  return showModalBottomSheet<CheckInUnlockResult>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) =>
        CheckInUnlockTitleSheet(title: title, placeName: placeName),
  );
}

/// Rastgele stamp veya unvan sheet'i açar.
@Deprecated('Use showCheckInFounderUnlockSheet for venue-first rewards')
Future<CheckInUnlockResult?> showCheckInUnlockRewardSheet(
  BuildContext context, {
  required String placeName,
}) {
  final isTitle = Random().nextBool();
  if (isTitle) {
    final title = _unlockTitles[Random().nextInt(_unlockTitles.length)];
    return showModalBottomSheet<CheckInUnlockResult>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          CheckInUnlockTitleSheet(title: title, placeName: placeName),
    );
  }

  return showCheckInUnlockStampSheet(
    context,
    stamp: _unlockStamps[Random().nextInt(_unlockStamps.length)],
  );
}

/// Sadece stamp unlock sheet'i açar.
Future<CheckInUnlockResult?> showCheckInUnlockStampSheet(
  BuildContext context, {
  required StampItem stamp,
}) {
  return showModalBottomSheet<CheckInUnlockResult>(
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
            StampImage(
              path: stamp.imagePath,
              stampId: stamp.id,
              width: 180,
              height: 180,
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'check_in_unlock_add'.tr(),
              height: 50,
              onPressed: () =>
                  Navigator.of(context).pop(CheckInUnlockResult.stamp(stamp)),
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

class CheckInUnlockTitleSheet extends StatelessWidget {
  const CheckInUnlockTitleSheet({
    required this.title,
    required this.placeName,
    super.key,
  });

  final TitleUnlockItem title;
  final String placeName;

  @override
  Widget build(BuildContext context) {
    final place = placeName.trim().isEmpty ? 'Babylon İstanbul' : placeName;

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
              'check_in_unlock_title_earned'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1,
                letterSpacing: -0.32,
                color: AppColors.zoviOrange,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title.label,
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
              'check_in_unlock_title_description'.tr(
                namedArgs: {'place': place},
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.35,
                color: AppColors.black.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 10),
            if (title.networkImageUrl != null &&
                title.networkImageUrl!.trim().isNotEmpty)
              Image.network(
                title.networkImageUrl!,
                width: 180,
                height: 180,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Image.asset(
                  title.imagePath,
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                ),
              )
            else
              Image.asset(
                title.imagePath,
                width: 180,
                height: 180,
                fit: BoxFit.contain,
              ),
            const SizedBox(height: 10),
            AppButton(
              label: 'check_in_unlock_save_and_use'.tr(),
              height: 50,
              onPressed: () => Navigator.of(context).pop(
                CheckInUnlockResult.title(
                  titleLabel: title.label,
                  titleImagePath: title.imagePath,
                ),
              ),
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
