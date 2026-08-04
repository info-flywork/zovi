import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/snackbar/app_snackbar.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/home/model/check_in_success_route_args.dart';
import 'package:zovi/presentation/home/view/widgets/check_in_unlock_stamp_sheet.dart';

class CheckInSuccessView extends StatelessWidget {
  const CheckInSuccessView({required this.args, super.key});

  final CheckInSuccessRouteArgs args;

  static const _bg = Color(0xFF7B2FFF);

  @override
  Widget build(BuildContext context) {
    final rewards = _buildRewards();

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            kBottomNavigationBarHeight / 2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => _onShare(context),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'check_in_success_share'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 20 / 16,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const AppIcon(
                        AssetPaths.iconExportArrow,
                        size: 22,
                        color: AppColors.white,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'check_in_success_title'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 20 / 16,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                args.placeName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 55),
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      _GlassCard(
                        child: Column(
                          children: [
                            for (var i = 0; i < rewards.length; i++) ...[
                              if (i > 0) const SizedBox(height: 20),
                              _RewardRow(reward: rewards[i]),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      _GlassCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'check_in_success_coins_earned'.tr(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  height: 20 / 16,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: Transform.scale(
                                scale: 1.2,
                                child: Image.asset(
                                  AssetPaths.zoviCoin,
                                  width: 28,
                                  height: 28,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${args.totalCoins}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                height: 20 / 16,
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: Material(
                  color: AppColors.white,
                  shape: const StadiumBorder(),
                  child: InkWell(
                    onTap: () => _onDone(context),
                    customBorder: const StadiumBorder(),
                    child: Center(
                      child: Text(
                        'done'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 20 / 16,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onShare(BuildContext context) async {
    final text = 'check_in_share_checin_text'.tr(
      namedArgs: {'place': args.placeName},
    );
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    AppSnackbar.instance.show(
      context,
      'check_in_share_checin_copied'.tr(),
    );
  }

  Future<void> _onDone(BuildContext context) async {
    CheckInUnlockResult? reward;
    final founder = args.founderOffer;
    if (founder != null) {
      reward = await showCheckInFounderUnlockSheet(
        context,
        placeName: args.placeName,
        offer: founder,
      );
      final checkInId = args.checkInId?.trim();
      if (reward != null && checkInId != null && checkInId.isNotEmpty) {
        try {
          await getIt<UserRepository>().acceptFounderReward(checkInId);
        } catch (_) {
          // Local map marker still updates even if accept call fails.
        }
      }
    }

    if (!context.mounted) return;
    if (reward != null) {
      getIt<UserRepository>().setActiveMapCheckIn(
        ActiveMapCheckIn(
          stampImagePath:
              reward.stamp?.imagePath ??
              reward.titleImagePath ??
              AssetPaths.stamp16,
          photoPaths: args.photoPaths.isNotEmpty
              ? args.photoPaths
              : const [AssetPaths.mapSecondAvatar],
          placeName: args.placeName,
          checkedAt: DateTime.now(),
          titleLabel: reward.titleLabel,
          avatarPath: getIt<UserRepository>()
                      .currentUserListenable
                      .value
                      ?.hasPhoto ==
                  true
              ? getIt<UserRepository>()
                    .currentUserListenable
                    .value!
                    .avatarPath
              : '',
        ),
      );
    } else {
      getIt<UserRepository>().recordCheckInCompleted();
      getIt<UserRepository>().setActiveMapCheckIn(
        ActiveMapCheckIn(
          stampImagePath: AssetPaths.stamp16,
          photoPaths: args.photoPaths.isNotEmpty
              ? args.photoPaths
              : const [AssetPaths.mapSecondAvatar],
          placeName: args.placeName,
          checkedAt: DateTime.now(),
          avatarPath: getIt<UserRepository>()
                      .currentUserListenable
                      .value
                      ?.hasPhoto ==
                  true
              ? getIt<UserRepository>()
                    .currentUserListenable
                    .value!
                    .avatarPath
              : '',
        ),
      );
    }
    context.go(RoutePaths.home.path);
  }

  List<_RewardItem> _buildRewards() {
    if (args.rewards.isNotEmpty) {
      return [
        for (final reward in args.rewards)
          _RewardItem(
            icon: _iconForKey(reward.iconKey),
            text: _rewardText(reward),
            points: reward.coins,
            isPng: _isPngIcon(reward.iconKey),
          ),
      ];
    }

    // Fallback if API rewards are missing (offline / older builds).
    final friendLabel =
        args.friendNames.isEmpty ? 'friend' : args.friendNames.first;
    return [
      if (args.isFirstEver)
        _RewardItem(
          icon: AssetPaths.iconBalloon,
          text: 'check_in_success_congrats'.tr(),
          points: 100,
          isPng: true,
        ),
      _RewardItem(
        icon: AssetPaths.iconLocation,
        text: 'check_in_success_first_at_place'.tr(
          namedArgs: {'place': args.placeName},
        ),
        points: 5,
      ),
      _RewardItem(
        icon: AssetPaths.iconAward,
        text: 'check_in_success_first_friend'.tr(),
        points: 5,
      ),
      if (args.hasPhoto)
        _RewardItem(
          icon: AssetPaths.iconChatCamera,
          text: 'check_in_success_great_photo'.tr(),
          points: 5,
        ),
      _RewardItem(
        icon: AssetPaths.iconFlameAqua,
        text: 'check_in_success_explore'.tr(),
        points: 2,
        isPng: true,
      ),
      if (args.friendNames.isNotEmpty)
        _RewardItem(
          icon: AssetPaths.iconAddUser,
          text: 'check_in_success_with_friend'.tr(
            namedArgs: {'name': friendLabel},
          ),
          points: 2,
        ),
    ];
  }

  String _rewardText(CheckInRewardItem reward) {
    final key = reward.messageKey.trim();
    if (key.isEmpty) return reward.code;
    final argsMap = <String, String>{
      ...reward.namedArgs,
      if (!reward.namedArgs.containsKey('place')) 'place': args.placeName,
      if (!reward.namedArgs.containsKey('name') &&
          args.friendNames.isNotEmpty)
        'name': args.friendNames.first,
    };
    return key.tr(namedArgs: argsMap);
  }

  static String _iconForKey(String key) {
    switch (key) {
      case 'balloon':
        return AssetPaths.iconBalloon;
      case 'location':
        return AssetPaths.iconLocation;
      case 'award':
        return AssetPaths.iconAward;
      case 'camera':
        return AssetPaths.iconChatCamera;
      case 'flame':
        return AssetPaths.iconFlameAqua;
      case 'friends':
        return AssetPaths.iconAddUser;
      default:
        return AssetPaths.zoviCoin;
    }
  }

  static bool _isPngIcon(String key) {
    return key == 'balloon' || key == 'flame' || key == 'coin';
  }
}

class _RewardItem {
  const _RewardItem({
    required this.icon,
    required this.text,
    required this.points,
    this.isPng = false,
  });

  final String icon;
  final String text;
  final int points;
  final bool isPng;
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.white),
            gradient: LinearGradient(
              end: Alignment.bottomLeft,
              begin: Alignment.topRight,
              colors: [
                AppColors.white.withValues(alpha: 0.02),
                AppColors.white.withValues(alpha: 0.14),
                AppColors.white.withValues(alpha: 0.02),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({required this.reward});

  final _RewardItem reward;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: reward.isPng
              ? Transform.scale(
                  scale: reward.icon == AssetPaths.iconBalloon ? 1.2 : 1.0,
                  child: Image.asset(
                    reward.icon,
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  ),
                )
              : AppIcon(reward.icon, size: 24, color: AppColors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            reward.text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 20 / 16,
              color: AppColors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '+${reward.points}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 20 / 16,
            color: AppColors.white,
          ),
        ),
      ],
    );
  }
}
