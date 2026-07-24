import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/in_app_notification/app_in_app_notification.dart';
import 'package:zovi/core/in_app_notification/in_app_notification_data.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/core/widgets/app_loading.dart';
import 'package:zovi/core/widgets/profile_avatar.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/chat/model/chat_detail_route_args.dart';
import 'package:zovi/presentation/profile/connections/model/profile_connections_route_args.dart';
import 'package:zovi/presentation/profile/user_profile/model/user_profile_route_args.dart';
import 'package:zovi/presentation/profile/user_profile/view/widgets/user_profile_action_feedback.dart';
import 'package:zovi/presentation/profile/user_profile/view/widgets/user_profile_actions_sheet.dart';
import 'package:zovi/presentation/profile/user_profile/view/widgets/user_profile_confirm_sheet.dart';
import 'package:zovi/presentation/profile/view/widgets/profile_share_sheet.dart';

enum _UserProfileTab { pulse, stamps, checkIn }

const _streakPink = Color(0xFFFF4D6D);

class UserProfileView extends StatefulWidget {
  const UserProfileView({required this.args, super.key});

  final UserProfileRouteArgs args;

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView>
    with SingleTickerProviderStateMixin {
  late PublicUserProfile _user = widget.args.user;
  late final TabController _tabController;
  var _loading = true;
  var _isBlocked = false;
  var _isRestricted = false;
  var _isReported = false;
  List<PulseItem> _pulses = const [];
  List<StampItem> _stamps = const [];
  List<CheckInItem> _checkIns = const [];
  List<PlanItem> _plans = const [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    unawaited(_load());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = getIt<UserRepository>();
    final username = _user.usernameHandle;
    final results = await Future.wait([
      repo.getPulses(forUsername: username),
      repo.getStamps(forUsername: username),
      repo.getCheckIns(forUsername: username),
      repo.getTodayPlans(forUsername: username),
    ]);
    if (!mounted) return;
    setState(() {
      _pulses = results[0] as List<PulseItem>;
      _stamps = results[1] as List<StampItem>;
      _checkIns = results[2] as List<CheckInItem>;
      _plans = results[3] as List<PlanItem>;
      _loading = false;
    });
  }

  bool get _actionsDisabled =>
      _isBlocked || _isRestricted || _isReported;

  void _toggleFollow() {
    if (_actionsDisabled) return;
    setState(() => _user = _user.copyWith(isFollowing: !_user.isFollowing));
  }

  Future<void> _openSettingsSheet() async {
    final action = await showUserProfileActionsSheet(
      context,
      isBlocked: _isBlocked,
      isRestricted: _isRestricted,
      isReported: _isReported,
    );
    if (!mounted || action == null) return;

    final isUndo = switch (action) {
      UserProfileAction.block => _isBlocked,
      UserProfileAction.restrict => _isRestricted,
      UserProfileAction.report => false,
    };

    if (!isUndo) {
      final result = await showUserProfileConfirmSheet(
        context,
        action: action,
        username: _user.usernameWithAt,
        avatarPath: _user.avatarPath,
      );
      if (!mounted || result == null) return;

      final alsoReport = result == UserProfileConfirmResult.secondary &&
          (action == UserProfileAction.block ||
              action == UserProfileAction.restrict);
      final alsoBlock = result == UserProfileConfirmResult.secondary &&
          action == UserProfileAction.report;

      setState(() {
        switch (action) {
          case UserProfileAction.block:
            _isBlocked = true;
            if (alsoReport) _isReported = true;
          case UserProfileAction.restrict:
            _isRestricted = true;
            if (alsoReport) _isReported = true;
          case UserProfileAction.report:
            _isReported = true;
            if (alsoBlock) _isBlocked = true;
        }
      });

      final effectiveAction =
          alsoBlock ? UserProfileAction.block : action;

      await _showActionFeedback(effectiveAction, isUndo: false);
      return;
    }

    setState(() {
      switch (action) {
        case UserProfileAction.block:
          _isBlocked = false;
        case UserProfileAction.restrict:
          _isRestricted = false;
        case UserProfileAction.report:
          break;
      }
    });

    await _showActionFeedback(action, isUndo: true);
  }

  Future<void> _showActionFeedback(
    UserProfileAction action, {
    required bool isUndo,
  }) async {
    final statusKey = switch ((action, isUndo)) {
      (UserProfileAction.block, false) => 'user_profile_status_blocking',
      (UserProfileAction.block, true) => 'user_profile_status_unblocking',
      (UserProfileAction.restrict, false) => 'user_profile_status_restricting',
      (UserProfileAction.restrict, true) => 'user_profile_status_unrestricting',
      (UserProfileAction.report, _) => 'user_profile_status_reporting',
    };
    final titleKey = switch ((action, isUndo)) {
      (UserProfileAction.block, false) => 'user_profile_blocked_title',
      (UserProfileAction.block, true) => 'user_profile_unblocked_title',
      (UserProfileAction.restrict, false) => 'user_profile_restricted_title',
      (UserProfileAction.restrict, true) => 'user_profile_unrestricted_title',
      (UserProfileAction.report, _) => 'user_profile_reported_title',
    };
    final subtitleKey = switch ((action, isUndo)) {
      (UserProfileAction.block, false) => 'user_profile_blocked_subtitle',
      (UserProfileAction.block, true) => 'user_profile_unblocked_subtitle',
      (UserProfileAction.restrict, false) => 'user_profile_restricted_subtitle',
      (UserProfileAction.restrict, true) => 'user_profile_unrestricted_subtitle',
      (UserProfileAction.report, _) => 'user_profile_reported_subtitle',
    };

    await showUserProfileActionStatusOverlay(
      context,
      label: statusKey.tr(),
    );
    if (!mounted) return;

    AppInAppNotification.instance.show(
      InAppNotificationData(
        username: _user.usernameHandle,
        displayName: _user.name,
        avatarPath: _user.avatarPath,
        messageKey: titleKey,
        messageNamedArgs: {'username': _user.usernameHandle},
        subtitleKey: subtitleKey,
        leadingIconPath: AssetPaths.iconForbidden,
        useFullTitle: true,
      ),
      alignment: Alignment.bottomCenter,
    );
  }

  void _openChat() {
    if (_actionsDisabled) return;
    context.push(
      RoutePaths.chatDetail.path,
      extra: ChatDetailRouteArgs(
        name: _user.name,
        username: _user.usernameHandle,
        avatarPath: _user.avatarPath,
      ),
    );
  }

  void _openConnections(ProfileConnectionsTab tab) {
    context.push(
      RoutePaths.profileConnections.path,
      extra: ProfileConnectionsRouteArgs(
        username: _user.usernameHandle,
        followersCount: _user.followers,
        friendsCount: _user.friends,
        initialTab: tab,
      ),
    );
  }

  static double _tabHeight({
    required int index,
    required double width,
    required int pulseCount,
    required int stampCount,
    required int checkInCount,
  }) {
    switch (index) {
      case 0:
        const spacing = 10.0;
        final itemWidth = (width - 32 - spacing * 2) / 3;
        final cardHeight = itemWidth * (200 / 126);
        final rows = (pulseCount / 3).ceil().clamp(1, 100);
        return 16 + rows * cardHeight + (rows - 1) * spacing;
      case 1:
        const spacing = 10.0;
        final itemWidth = (width - 32 - spacing * 2) / 3;
        final cardHeight = itemWidth + 20;
        final rows = (stampCount / 3).ceil().clamp(1, 100);
        return 16 + rows * cardHeight + (rows - 1) * spacing;
      case 2:
      default:
        return 16 + checkInCount * 80.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const AppLoading()
            : ListView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.only(bottom: bottom + 24),
                children: [
                  _TopBar(
                    streak: _user.streak,
                    onBack: () => context.pop(),
                    onShare: () => ProfileShareSheet.show(
                      context,
                      username: _user.username,
                    ),
                    onSettings: _openSettingsSheet,
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: ProfileAvatar(
                      path: _user.avatarPath,
                      size: 120,
                      showGradientRing: true,
                      ringWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _user.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1,
                          letterSpacing: -0.4,
                          color: AppColors.deepRoast,
                        ),
                      ),
                      if (_user.isVerified) ...[
                        const SizedBox(width: 6),
                        const AppIcon(AssetPaths.iconVerify, size: 20),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _user.usernameWithAt,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1,
                      letterSpacing: -0.28,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _StatsRow(
                    checkIns: _user.checkIns,
                    followers: _user.followers,
                    friends: _user.friends,
                    onFollowersTap: () =>
                        _openConnections(ProfileConnectionsTab.followers),
                    onFriendsTap: () =>
                        _openConnections(ProfileConnectionsTab.friends),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const AppIcon(
                              AssetPaths.iconLocationDark,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _user.explorerTitle.isEmpty
                                    ? _user.location
                                    : '${_user.location} · ${_user.explorerTitle}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  height: 1,
                                  letterSpacing: -0.28,
                                  color: AppColors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '“${_user.bio}”',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.32,
                            color: AppColors.deepRoast,
                          ),
                        ),
                        if (_user.mutualFriendAvatars.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _MutualFriendsRow(
                            avatars: _user.mutualFriendAvatars,
                            count: _user.mutualFriendsCount,
                          ),
                        ],
                        const SizedBox(height: 16),
                        _ActionRow(
                          isFollowing: _user.isFollowing,
                          isDisabled: _actionsDisabled,
                          onFollow: _toggleFollow,
                          onMessage: _openChat,
                          onAddUser: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _UserMapCard(
                    placeName: _user.mapPlaceName.isEmpty
                        ? _user.location
                        : _user.mapPlaceName,
                    distance: _user.mapDistanceKm.isEmpty
                        ? 'distance_km'.tr()
                        : _user.mapDistanceKm,
                  ),
                  const SizedBox(height: 16),
                  _UserPlans(plans: _plans),
                  const SizedBox(height: 16),
                  _UserTabs(
                    controller: _tabController,
                    onSelect: (tab) => _tabController.animateTo(tab.index),
                  ),
                  AnimatedBuilder(
                    animation: _tabController.animation!,
                    builder: (context, child) {
                      final value = _tabController.animation!.value.clamp(
                        0.0,
                        2.0,
                      );
                      final lower = value.floor().clamp(0, 2);
                      final upper = value.ceil().clamp(0, 2);
                      final t = value - lower;
                      final height = lerpDouble(
                        _tabHeight(
                          index: lower,
                          width: width,
                          pulseCount: _pulses.length,
                          stampCount: _stamps.length,
                          checkInCount: _checkIns.length,
                        ),
                        _tabHeight(
                          index: upper,
                          width: width,
                          pulseCount: _pulses.length,
                          stampCount: _stamps.length,
                          checkInCount: _checkIns.length,
                        ),
                        t,
                      )!;
                      return SizedBox(height: height, child: child);
                    },
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: _PulseStrip(pulses: _pulses),
                        ),
                        Align(
                          alignment: Alignment.topCenter,
                          child: _StampGrid(stamps: _stamps),
                        ),
                        Align(
                          alignment: Alignment.topCenter,
                          child: _CheckInList(checkIns: _checkIns),
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

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.streak,
    required this.onBack,
    required this.onShare,
    required this.onSettings,
  });

  final int streak;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: const AppIcon(AssetPaths.iconBack, size: 24),
          ),
          const Spacer(),
          if (streak > 0)
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _streakPink.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppIcon(AssetPaths.iconStreak, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '$streak',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1,
                      color: _streakPink,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onShare,
            child: const AppIcon(AssetPaths.iconExportCircle, size: 32),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onSettings,
            child: const AppIcon(AssetPaths.iconSetting, size: 32),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.checkIns,
    required this.followers,
    required this.friends,
    required this.onFollowersTap,
    required this.onFriendsTap,
  });

  final int checkIns;
  final int followers;
  final int friends;
  final VoidCallback onFollowersTap;
  final VoidCallback onFriendsTap;

  @override
  Widget build(BuildContext context) {
    Widget card({
      required String value,
      required String label,
      VoidCallback? onTap,
    }) {
      final child = Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                height: 1,
                letterSpacing: -0.48,
                color: AppColors.deepRoast,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1,
                letterSpacing: -0.28,
                color: Color(0x73000000),
              ),
            ),
          ],
        ),
      );
      return Expanded(
        child: onTap == null
            ? child
            : GestureDetector(
                onTap: onTap,
                behavior: HitTestBehavior.opaque,
                child: child,
              ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          card(value: '$checkIns', label: 'stat_check_in'.tr()),
          const SizedBox(width: 10),
          card(
            value: '$followers',
            label: 'stat_follower'.tr(),
            onTap: onFollowersTap,
          ),
          const SizedBox(width: 10),
          card(
            value: '$friends',
            label: 'stat_friends'.tr(),
            onTap: onFriendsTap,
          ),
        ],
      ),
    );
  }
}

class _MutualFriendsRow extends StatelessWidget {
  const _MutualFriendsRow({required this.avatars, required this.count});

  final List<String> avatars;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 20.0 + (avatars.take(3).length - 1) * 14,
          height: 24,
          child: Stack(
            children: [
              for (var i = 0; i < avatars.take(3).length; i++)
                Positioned(
                  left: i * 14.0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 1.5),
                    ),
                    child: ClipOval(
                      child: Image.asset(avatars[i], fit: BoxFit.cover),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'user_profile_friends_in_common'.tr(namedArgs: {'count': '$count'}),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1,
            letterSpacing: -0.28,
            color: AppColors.deepRoast.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

const _disabledActionBg = Color(0xFFD8D8D8);

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.isFollowing,
    required this.isDisabled,
    required this.onFollow,
    required this.onMessage,
    required this.onAddUser,
  });

  final bool isFollowing;
  final bool isDisabled;
  final VoidCallback onFollow;
  final VoidCallback onMessage;
  final VoidCallback onAddUser;

  @override
  Widget build(BuildContext context) {
    final followBg = isDisabled
        ? _disabledActionBg
        : (isFollowing ? AppColors.mintGreen : AppColors.zoviOrange);
    final followFg = isDisabled ? AppColors.mutedGray : AppColors.white;
    final messageBg = isDisabled ? _disabledActionBg : AppColors.surfaceGray;
    final messageFg = AppColors.mutedGray;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: isDisabled ? null : onFollow,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 44,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: followBg,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(
                    isFollowing && !isDisabled
                        ? AssetPaths.iconWhiteTick
                        : AssetPaths.iconAdd2,
                    size: 24,
                    color: isDisabled ? followFg : null,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isFollowing && !isDisabled
                        ? 'user_profile_following'.tr()
                        : 'user_profile_follow'.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1,
                      letterSpacing: -0.32,
                      color: followFg,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: isDisabled ? null : onMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: messageBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(AssetPaths.iconSend, color: messageFg),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'user_profile_send_message'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1,
                        letterSpacing: -0.32,
                        color: messageFg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UserMapCard extends StatelessWidget {
  const _UserMapCard({required this.placeName, required this.distance});

  final String placeName;
  final String distance;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 398 / 180,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(AssetPaths.mapLa, fit: BoxFit.cover),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      const AppIcon(AssetPaths.iconLocationDark, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          placeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1,
                            letterSpacing: -0.28,
                            color: AppColors.deepRoast,
                          ),
                        ),
                      ),
                      Text(
                        distance,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1,
                          letterSpacing: -0.28,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
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

class _UserPlans extends StatelessWidget {
  const _UserPlans({required this.plans});

  final List<PlanItem> plans;

  static String _localizedFriendsLabel(String friendsLabel) {
    final match = RegExp(r'^(\d+)').firstMatch(friendsLabel.trim());
    if (match != null) {
      return 'friends_are_joining'.tr(namedArgs: {'count': match.group(1)!});
    }
    return friendsLabel;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              const AppIcon(AssetPaths.iconCalendarDate, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'today_plans'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1,
                    letterSpacing: -0.32,
                    color: AppColors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...plans.map(
            (plan) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _UserPlanCard(plan: plan),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserPlanCard extends StatelessWidget {
  const _UserPlanCard({required this.plan});

  final PlanItem plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Row(
        children: [
          Text(
            plan.time,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1,
              letterSpacing: -0.32,
              color: AppColors.zoviOrange,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  plan.placeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1,
                    letterSpacing: -0.32,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  plan.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1,
                    letterSpacing: -0.28,
                    color: AppColors.deepRoast.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _UserPlanOverlappingAvatars(avatars: plan.friendAvatars),
          const SizedBox(width: 6),
          Text(
            _UserPlans._localizedFriendsLabel(plan.friendsLabel),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.15,
              letterSpacing: -0.24,
              color: AppColors.deepRoast.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserPlanOverlappingAvatars extends StatelessWidget {
  const _UserPlanOverlappingAvatars({required this.avatars});

  final List<String> avatars;

  @override
  Widget build(BuildContext context) {
    const size = 34.0;
    const overlap = 12.0;
    final shown = avatars.take(3).toList();
    final width = size + (shown.length - 1) * (size - overlap);

    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * (size - overlap),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 3),
                ),
                child: ClipOval(
                  child: Image.asset(shown[i], fit: BoxFit.cover),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UserTabs extends StatelessWidget {
  const _UserTabs({required this.controller, required this.onSelect});

  final TabController controller;
  final ValueChanged<_UserProfileTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedBuilder(
        animation: controller.animation!,
        builder: (context, _) {
          final progress = controller.animation!.value.clamp(0.0, 2.0);
          return LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / 3;
              return Stack(
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < 3; i++)
                        Expanded(
                          child: _UserTabItem(
                            label: switch (_UserProfileTab.values[i]) {
                              _UserProfileTab.pulse => 'tab_pulse'.tr(),
                              _UserProfileTab.stamps => 'tab_stamps'.tr(),
                              _UserProfileTab.checkIn => 'tab_check_in'.tr(),
                            },
                            selectedAmount: (1.0 - (progress - i).abs()).clamp(
                              0.0,
                              1.0,
                            ),
                            onTap: () => onSelect(_UserProfileTab.values[i]),
                          ),
                        ),
                    ],
                  ),
                  Positioned(
                    left: progress * tabWidth,
                    bottom: 0,
                    width: tabWidth,
                    child: const ColoredBox(
                      color: AppColors.zoviOrange,
                      child: SizedBox(height: 2),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _UserTabItem extends StatelessWidget {
  const _UserTabItem({
    required this.label,
    required this.selectedAmount,
    required this.onTap,
  });

  final String label;
  final double selectedAmount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color.lerp(
      AppColors.textTertiary,
      AppColors.zoviOrange,
      selectedAmount,
    )!;
    final weight = FontWeight.lerp(
      FontWeight.w400,
      FontWeight.w500,
      selectedAmount,
    )!;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: weight,
            height: 1,
            letterSpacing: -0.32,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _PulseStrip extends StatelessWidget {
  const _PulseStrip({required this.pulses});

  final List<PulseItem> pulses;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 10.0;
          final itemWidth = (constraints.maxWidth - spacing * 2) / 3;
          final itemHeight = itemWidth * (200 / 126);

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final pulse in pulses)
                SizedBox(
                  width: itemWidth,
                  height: itemHeight,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(pulse.imagePath, fit: BoxFit.cover),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StampGrid extends StatelessWidget {
  const _StampGrid({required this.stamps});

  final List<StampItem> stamps;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 10.0;
          final itemWidth = (constraints.maxWidth - spacing * 2) / 3;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final stamp in stamps.take(9))
                SizedBox(
                  width: itemWidth,
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: Image.asset(
                          stamp.imagePath,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        stamp.title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CheckInList extends StatelessWidget {
  const _CheckInList({required this.checkIns});

  final List<CheckInItem> checkIns;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          for (final item in checkIns)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderGray),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      item.imagePath,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.placeName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1,
                            letterSpacing: -0.32,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.when,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.deepRoast.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
