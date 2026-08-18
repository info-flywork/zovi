import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/widgets/profile_avatar.dart';
import 'package:zovi/presentation/profile/bloc/profile_bloc.dart';

@immutable
final class AddPlanSuccessView extends StatelessWidget {
  const AddPlanSuccessView({
    this.friendAvatars = const [],
    this.friendsLabel = '0',
    this.showToFriends = true,
    this.showToNearby = true,
    super.key,
  });

  final List<String> friendAvatars;
  final String friendsLabel;
  final bool showToFriends;
  final bool showToNearby;

  bool get _hasJoiningFriends {
    if (!showToFriends) return false;
    final count =
        int.tryParse(
          RegExp(r'\d+').firstMatch(friendsLabel.trim())?.group(0) ?? '',
        ) ??
        0;
    return count > 0 || friendAvatars.isNotEmpty;
  }

  String get _subtitleKey {
    if (showToFriends && showToNearby) {
      return 'plan_added_subtitle_friends_and_nearby';
    }
    if (showToFriends) return 'plan_added_subtitle_friends_only';
    if (showToNearby) return 'plan_added_subtitle_nearby_only';
    return 'plan_added_subtitle_private';
  }

  void _onContinue(BuildContext context) {
    if (getIt.isRegistered<ProfileBloc>()) {
      getIt<ProfileBloc>().add(const ProfilePlansRefreshRequested());
    }
    context.go(RoutePaths.profile.path);
  }

  @override
  Widget build(BuildContext context) {
    final hasFriends = _hasJoiningFriends;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Image.asset(
                AssetPaths.greenTick,
                width: 210,
                height: 140,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              Text(
                'plan_added_title'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w500,
                  height: 40 / 36,
                  letterSpacing: -0.72,
                  color: AppColors.deepRoast,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _subtitleKey.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 20 / 16,
                  letterSpacing: -0.32,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              if (hasFriends)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OverlappingProfileAvatars(avatars: friendAvatars),
                    const SizedBox(width: 8),
                    Text(
                      'friends_are_joining'.tr(
                        namedArgs: {'count': friendsLabel},
                      ),
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.15,
                        letterSpacing: -0.24,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  'no_friends_joining'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.15,
                    letterSpacing: -0.24,
                    color: AppColors.textSecondary,
                  ),
                ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: GestureDetector(
                  onTap: () => _onContinue(context),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.deepRoast,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Center(
                      child: Text(
                        'continue'.tr(),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          height: 1,
                          letterSpacing: -0.34,
                          color: AppColors.white,
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
}
