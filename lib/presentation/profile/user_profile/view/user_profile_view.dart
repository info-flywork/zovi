import 'dart:async';
import 'dart:io';
import 'dart:ui' show lerpDouble;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/in_app_notification/app_in_app_notification.dart';
import 'package:zovi/core/in_app_notification/in_app_notification_data.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/bunny_image_url.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/core/widgets/profile_avatar.dart';
import 'package:zovi/core/widgets/stamp_image.dart';
import 'package:zovi/domain/auth/auth_repository.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/chat/model/chat_detail_route_args.dart';
import 'package:zovi/presentation/chat/view/widgets/chat_media_viewer.dart';
import 'package:zovi/presentation/profile/connections/model/profile_connections_route_args.dart';
import 'package:zovi/presentation/profile/connections/view/widgets/profile_connection_confirm_sheet.dart';
import 'package:zovi/presentation/profile/user_profile/model/user_profile_route_args.dart';
import 'package:zovi/presentation/profile/user_profile/view/widgets/user_profile_action_feedback.dart';
import 'package:zovi/presentation/profile/user_profile/view/widgets/user_profile_actions_sheet.dart';
import 'package:zovi/presentation/profile/user_profile/view/widgets/user_profile_confirm_sheet.dart';
import 'package:zovi/presentation/profile/view/widgets/profile_links_sheet.dart';
import 'package:zovi/presentation/profile/view/widgets/profile_share_sheet.dart';
import 'package:zovi/presentation/stories/model/story_detail_route_args.dart';

enum _UserProfileTab { pulse, stamps, checkIn }

const _streakPink = Color(0xFFFF4D6D);

@immutable
final class UserProfileView extends StatefulWidget {
  const UserProfileView({required this.args, super.key});

  final UserProfileRouteArgs args;

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

final class _UserProfileViewState extends State<UserProfileView>
    with SingleTickerProviderStateMixin {
  late PublicUserProfile _user;
  late final TabController _tabController;
  var _headerLoading = true;
  var _friendContentLoading = false;
  var _isBlocked = false;
  var _isRestricted = false;
  var _isReported = false;
  var _followBusy = false;
  var _followTouched = false;
  List<PulseItem> _pulses = const [];
  List<StampItem> _stamps = const [];
  List<CheckInItem> _checkIns = const [];
  List<PlanItem> _plans = const [];

  @override
  void initState() {
    super.initState();
    _user = widget.args.user;
    _headerLoading = !_user.isHydrated;
    _tabController = TabController(length: 3, vsync: this);

    // İlk frame'de cache varsa shimmer hiç görünmesin.
    if (_user.canSeeFriendContent) {
      final cached = getIt<UserRepository>().peekFriendSections(
        _user.usernameHandle,
      );
      if (cached != null) {
        _plans = cached.plans;
        _pulses = cached.pulses;
        _stamps = cached.stamps;
        _checkIns = cached.checkIns;
      }
    }

    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final repo = getIt<UserRepository>();
    final username = _user.usernameHandle;
    final userId = _user.userId.trim();
    final fetchByUserId = userId.isNotEmpty;

    // Cached/hydrated seed — load friend sections immediately in parallel.
    if (_user.isHydrated && _user.canSeeFriendContent) {
      unawaited(_loadFriendContent(username));
    }

    try {
      final fetched = fetchByUserId
          ? await repo.getPublicUserProfileByUserId(userId)
          : await repo.getPublicUserProfile(username);
      if (!mounted) return;
      // A tap that landed while this was in flight wins over the stale payload.
      final profile = _followTouched
          ? fetched.copyWith(
              relationship: _user.relationship,
              isFollowing: _user.relationship.following,
              areFriends: _user.relationship.following,
            )
          : fetched;
      final wasFriend = _user.canSeeFriendContent;
      setState(() {
        _user = profile;
        _headerLoading = false;
        _isBlocked = profile.blockedByMe;
        _isRestricted = profile.restrictedByMe;
      });
      if (profile.blockedByMe) {
        setState(() {
          _plans = const [];
          _pulses = const [];
          _stamps = const [];
          _checkIns = const [];
          _friendContentLoading = false;
        });
      } else if (profile.canSeeFriendContent && !wasFriend) {
        unawaited(_loadFriendContent(profile.usernameHandle));
      } else if (!profile.canSeeFriendContent) {
        setState(() {
          _plans = const [];
          _pulses = const [];
          _stamps = const [];
          _checkIns = const [];
          _friendContentLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _headerLoading = false);
    }
  }

  Future<void> _loadFriendContent(String username) async {
    if (!mounted) return;
    final repo = getIt<UserRepository>();
    final cached = repo.peekFriendSections(username);

    // Paint instantly from memory — shimmer sadece cold open'da.
    if (cached != null) {
      setState(() {
        _plans = cached.plans;
        _pulses = cached.pulses;
        _stamps = cached.stamps;
        _checkIns = cached.checkIns;
        _friendContentLoading = false;
      });
    } else {
      setState(() => _friendContentLoading = true);
    }

    var plans = cached?.plans ?? _plans;
    var stamps = cached?.stamps ?? _stamps;
    var pulses = cached?.pulses ?? _pulses;
    var checkIns = cached?.checkIns ?? _checkIns;

    Future<void> loadPlans() async {
      try {
        final value = await repo.getTodayPlans(forUsername: username);
        plans = value;
        if (mounted) setState(() => _plans = value);
      } catch (_) {}
    }

    Future<void> loadStamps() async {
      try {
        final value = await repo.getStamps(forUsername: username);
        stamps = value;
        if (mounted) setState(() => _stamps = value);
      } catch (_) {}
    }

    Future<void> loadPulses() async {
      try {
        final value = await repo.getPulses(forUsername: username);
        pulses = value;
        if (mounted) setState(() => _pulses = value);
      } catch (_) {}
    }

    Future<void> loadCheckIns() async {
      try {
        final value = await repo.getCheckIns(forUsername: username);
        checkIns = value;
        if (mounted) setState(() => _checkIns = value);
      } catch (_) {}
    }

    await Future.wait([
      loadPlans(),
      loadStamps(),
      loadPulses(),
      loadCheckIns(),
    ]);

    repo.cacheFriendSections(
      username,
      plans: plans,
      pulses: pulses,
      stamps: stamps,
      checkIns: checkIns,
    );

    if (!mounted) return;
    setState(() => _friendContentLoading = false);
  }

  Future<void> _openStory() async {
    if (!_user.hasActiveStory || _user.userId.isEmpty) return;
    final items = await getIt<UserRepository>().getStoryItemsForUser(
      _user.userId,
    );
    if (!mounted || items.isEmpty) return;
    await context.push(
      RoutePaths.storyDetail.path,
      extra: StoryDetailRouteArgs(items: items, initialIndex: 0),
    );
    if (!mounted) return;
    // Refresh ring viewed state after closing the viewer.
    try {
      final refreshed = await getIt<UserRepository>().getPublicUserProfile(
        _user.usernameHandle,
      );
      if (mounted) setState(() => _user = refreshed);
    } catch (_) {}
  }

  bool get _actionsDisabled => _isBlocked;

  void _toggleFollow() {
    if (_actionsDisabled) return;
    unawaited(_onFollowPressed());
  }

  /// Optimistic: paint the predicted state now, send the request in the
  /// background, then reconcile with the server (or roll back on failure).
  Future<void> _onFollowPressed() async {
    final userId = _user.userId.trim();
    if (userId.isEmpty || _followBusy) return;

    final previous = _user;
    final rel = previous.relationship;
    final auth = getIt<AuthRepository>();

    final isUnfollow = rel.following || rel.outgoingRequest;
    final isAccept =
        !isUnfollow &&
        rel.incomingRequest &&
        (rel.incomingRequestId?.isNotEmpty ?? false);

    if (isUnfollow) {
      final confirmed = await showProfileConnectionConfirmSheet(
        context,
        action: ProfileConnectionConfirmAction.unfollow,
        username: previous.usernameHandle,
      );
      if (!confirmed || !mounted) return;
    }

    final predicted = isUnfollow
        ? rel.copyWith(
            following: false,
            outgoingRequest: false,
            clearOutgoingRequestId: true,
          )
        : isAccept
        ? rel.copyWith(
            followedBy: true,
            incomingRequest: false,
            clearIncomingRequestId: true,
          )
        : previous.isPrivate
        ? rel.copyWith(outgoingRequest: true)
        : rel.copyWith(following: true);

    _followBusy = true;
    _followTouched = true;
    _applyRelationship(predicted);

    try {
      final result = isUnfollow
          ? await auth.unfollowUser(userId)
          : isAccept
          ? await auth.acceptFollowRequest(rel.incomingRequestId!)
          : await auth.followUser(userId);
      if (!mounted) return;
      _applyRelationship(result.relationship);
    } catch (_) {
      if (!mounted) return;
      setState(() => _user = previous);
    } finally {
      _followBusy = false;
    }
  }

  void _applyRelationship(FollowRelationship next) {
    final couldSeeFriendContent = _user.canSeeFriendContent;
    final wasFollowing = _user.relationship.following;
    final delta = next.following == wasFollowing
        ? 0
        : (next.following ? 1 : -1);

    setState(() {
      _user = _user.copyWith(
        isFollowing: next.following,
        areFriends: next.following,
        relationship: next,
        followers: (_user.followers + delta).clamp(0, 1 << 31),
      );
      if (!_user.canSeeFriendContent) {
        _plans = const [];
        _pulses = const [];
        _stamps = const [];
        _checkIns = const [];
        getIt<UserRepository>().forgetFriendSections(_user.usernameHandle);
      }
    });
    if (delta != 0) _bumpOwnFollowingCount(delta);
    if (_user.canSeeFriendContent && !couldSeeFriendContent) {
      unawaited(_loadFriendContent(_user.usernameHandle));
    }
  }

  /// Keep my own "following" counter in sync so the profile tab doesn't show
  /// a stale number after following someone from here.
  void _bumpOwnFollowingCount(int delta) {
    final repo = getIt<UserRepository>();
    final me = repo.cachedCurrentUser;
    if (me == null) return;
    unawaited(
      repo.updateCurrentUser(
        me.copyWith(friends: (me.friends + delta).clamp(0, 1 << 31)),
      ),
    );
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

      final alsoReport =
          result == UserProfileConfirmResult.secondary &&
          (action == UserProfileAction.block ||
              action == UserProfileAction.restrict);
      final alsoBlock =
          result == UserProfileConfirmResult.secondary &&
          action == UserProfileAction.report;

      final effectiveAction = alsoBlock ? UserProfileAction.block : action;

      final ok = await _persistProfileAction(
        effectiveAction,
        alsoReport: alsoReport || action == UserProfileAction.report,
      );
      if (!mounted || !ok) return;

      await _showActionFeedback(effectiveAction, isUndo: false);
      return;
    }

    final ok = await _persistProfileAction(action, undo: true);
    if (!mounted || !ok) return;

    await _showActionFeedback(action, isUndo: true);
  }

  Future<bool> _persistProfileAction(
    UserProfileAction action, {
    bool undo = false,
    bool alsoReport = false,
  }) async {
    final userId = _user.userId.trim();
    if (userId.isEmpty &&
        (action == UserProfileAction.block ||
            action == UserProfileAction.restrict)) {
      return false;
    }

    final auth = getIt<AuthRepository>();
    final repo = getIt<UserRepository>();

    try {
      switch (action) {
        case UserProfileAction.block:
          if (undo) {
            await auth.unblockUser(userId);
            if (!mounted) return false;
            setState(() {
              _isBlocked = false;
              _user = _user.copyWith(blockedByMe: false);
            });
          } else {
            await auth.blockUser(userId);
            repo.purgeUserFromSocialFeeds(userId);
            if (!mounted) return false;
            setState(() {
              _isBlocked = true;
              _isRestricted = false;
              if (alsoReport) _isReported = true;
              _user = _user.copyWith(
                blockedByMe: true,
                restrictedByMe: false,
                isFollowing: false,
                areFriends: false,
                relationship: const FollowRelationship(),
                hasActiveStory: false,
                links: const [],
              );
              _plans = const [];
              _pulses = const [];
              _stamps = const [];
              _checkIns = const [];
            });
          }
        case UserProfileAction.restrict:
          if (undo) {
            await auth.unrestrictUser(userId);
            if (!mounted) return false;
            setState(() {
              _isRestricted = false;
              _user = _user.copyWith(restrictedByMe: false);
            });
          } else {
            await auth.restrictUser(userId);
            unawaited(repo.getStories());
            if (!mounted) return false;
            setState(() {
              _isRestricted = true;
              if (alsoReport) _isReported = true;
              _user = _user.copyWith(restrictedByMe: true);
            });
          }
        case UserProfileAction.report:
          if (!mounted) return false;
          setState(() => _isReported = true);
      }
      return true;
    } catch (_) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('error_profile_save_failed'.tr())));
      return false;
    }
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
      (UserProfileAction.restrict, true) =>
        'user_profile_unrestricted_subtitle',
      (UserProfileAction.report, _) => 'user_profile_reported_subtitle',
    };

    await showUserProfileActionStatusOverlay(context, label: statusKey.tr());
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
        userId: _user.userId,
      ),
    );
  }

  void _openConnections(ProfileConnectionsTab tab) {
    context.push(
      RoutePaths.profileConnections.path,
      extra: ProfileConnectionsRouteArgs(
        name: _user.name,
        userId: _user.userId,
        followersCount: _user.followers,
        friendsCount: _user.friends,
        isOwnProfile: _user.isSelf,
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
        if (pulseCount == 0) return 150;
        const spacing = 10.0;
        final itemWidth = (width - 32 - spacing * 2) / 3;
        final cardHeight = itemWidth * (200 / 126);
        final rows = (pulseCount / 3).ceil().clamp(1, 100);
        return 16 + rows * cardHeight + (rows - 1) * spacing;
      case 1:
        if (stampCount == 0) return 150;
        const spacing = 10.0;
        final itemWidth = (width - 32 - spacing * 2) / 3;
        final cardHeight = itemWidth + 24;
        final rows = (stampCount / 3).ceil().clamp(1, 100);
        return 16 + rows * cardHeight + (rows - 1) * spacing;
      case 2:
      default:
        if (checkInCount == 0) return 150;
        // padding 16 + row(padding 20 + avatar 50 + border 2 + margin 10)
        return 16 + checkInCount * 82.0;
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
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.only(bottom: bottom + 24),
          children: [
            _TopBar(
              streak: _user.streak,
              onBack: () => context.pop(),
              onShare: () =>
                  ProfileShareSheet.show(context, username: _user.username),
              onSettings: _openSettingsSheet,
            ),
            const SizedBox(height: 10),
            Center(
              child: GestureDetector(
                onTap: _user.hasActiveStory ? _openStory : null,
                behavior: HitTestBehavior.opaque,
                child: ProfileAvatar(
                  path: _user.avatarPath,
                  size: 120,
                  showGradientRing:
                      _user.hasActiveStory && !_user.storyIsViewed,
                  showSeenRing: _user.hasActiveStory && _user.storyIsViewed,
                  ringWidth: 3,
                ),
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
            if (_headerLoading)
              const _StatsRowShimmer()
            else
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
                  if (_headerLoading &&
                      _user.location.trim().isEmpty &&
                      _user.explorerTitle.trim().isEmpty)
                    const _BioLineShimmer(width: 160)
                  else if (_user.location.trim().isNotEmpty ||
                      _user.explorerTitle.trim().isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AppIcon(AssetPaths.iconLocationDark, size: 18),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _user.explorerTitle.isEmpty
                                ? _user.location
                                : (_user.location.isEmpty
                                      ? _user.explorerTitle
                                      : '${_user.location} · ${_user.explorerTitle}'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1,
                              letterSpacing: -0.28,
                              color: Color(0xFF1A1714).withValues(alpha: 0.65),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_headerLoading && _user.bio.trim().isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: _BioLineShimmer(width: 220),
                    )
                  else if (_user.bio.trim().isNotEmpty)
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
                  if (_user.links.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _UserProfileLinksRow(links: _user.links),
                  ],
                  if (_user.canSeeFriendContent &&
                      _user.mutualFriendAvatars.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _MutualFriendsRow(
                      avatars: _user.mutualFriendAvatars,
                      count: _user.mutualFriendsCount,
                    ),
                  ],
                  const SizedBox(height: 16),
                  _ActionRow(
                    relationship: _user.relationship,
                    isDisabled: _actionsDisabled,
                    onFollow: _toggleFollow,
                    onMessage: _openChat,
                    onAddUser: () {},
                  ),
                ],
              ),
            ),
            if (_user.canSeeFriendContent) ...[
              if (_friendContentLoading && _plans.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: _PlansShimmer(),
                )
              else if (_plans.isNotEmpty) ...[
                const SizedBox(height: 16),
                _UserPlans(plans: _plans),
              ],
              const SizedBox(height: 16),
              _UserTabs(
                controller: _tabController,
                onSelect: (tab) => _tabController.animateTo(tab.index),
              ),
              if (_friendContentLoading &&
                  _pulses.isEmpty &&
                  _stamps.isEmpty &&
                  _checkIns.isEmpty)
                const _TabsBodyShimmer()
              else
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
                        alignment: Alignment.topLeft,
                        child: _PulseStrip(pulses: _pulses),
                      ),
                      Align(
                        alignment: Alignment.topLeft,
                        child: _StampGrid(stamps: _stamps),
                      ),
                      Align(
                        alignment: Alignment.topLeft,
                        child: _CheckInList(checkIns: _checkIns),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

@immutable
final class _ProfileShimmer extends StatelessWidget {
  const _ProfileShimmer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8E8E8),
      highlightColor: const Color(0xFFF5F5F5),
      child: child,
    );
  }
}

@immutable
final class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

@immutable
final class _BioLineShimmer extends StatelessWidget {
  const _BioLineShimmer({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return _ProfileShimmer(
      child: Center(child: _ShimmerBox(width: width, height: 14, radius: 6)),
    );
  }
}

@immutable
final class _StatsRowShimmer extends StatelessWidget {
  const _StatsRowShimmer();

  @override
  Widget build(BuildContext context) {
    return _ProfileShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              const Expanded(
                child: _ShimmerBox(
                  width: double.infinity,
                  height: 56,
                  radius: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

@immutable
final class _PlansShimmer extends StatelessWidget {
  const _PlansShimmer();

  @override
  Widget build(BuildContext context) {
    return _ProfileShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: _ShimmerBox(width: 140, height: 16, radius: 6),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < 2; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              const _ShimmerBox(width: double.infinity, height: 72, radius: 14),
            ],
          ],
        ),
      ),
    );
  }
}

@immutable
final class _TabsBodyShimmer extends StatelessWidget {
  const _TabsBodyShimmer();

  @override
  Widget build(BuildContext context) {
    return _ProfileShimmer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              const Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _ShimmerBox(
                    width: double.infinity,
                    height: double.infinity,
                    radius: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

@immutable
final class _TopBar extends StatelessWidget {
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

@immutable
final class _StatsRow extends StatelessWidget {
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

@immutable
final class _MutualFriendsRow extends StatelessWidget {
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

@immutable
final class _UserProfileLinksRow extends StatelessWidget {
  const _UserProfileLinksRow({required this.links});

  final List<ProfileLink> links;

  @override
  Widget build(BuildContext context) {
    final isSingle = links.length == 1;
    final label = isSingle ? links.first.displayUrl : 'my_links'.tr();

    return GestureDetector(
      onTap: () {
        if (isSingle) {
          openProfileLink(links.first.url);
          return;
        }
        showProfileLinksSheet(context, links: links);
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppIcon(AssetPaths.iconLink, size: 20),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
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
    );
  }
}

@immutable
final class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.relationship,
    required this.isDisabled,
    required this.onFollow,
    required this.onMessage,
    required this.onAddUser,
  });

  final FollowRelationship relationship;
  final bool isDisabled;
  final VoidCallback onFollow;
  final VoidCallback onMessage;
  final VoidCallback onAddUser;

  @override
  Widget build(BuildContext context) {
    final following = relationship.following;
    final pendingOut = relationship.outgoingRequest;
    final pendingIn = relationship.incomingRequest && !following;
    final followBack =
        relationship.followedBy && !following && !pendingOut && !pendingIn;

    final label = pendingOut
        ? 'user_profile_request_sent'.tr()
        : pendingIn
        ? 'notifications_accept_request'.tr()
        : following
        ? 'user_profile_following'.tr()
        : followBack
        ? 'notifications_follow_back'.tr()
        : 'user_profile_follow'.tr();

    final showTick = following && !isDisabled;
    final followBg = isDisabled
        ? _disabledActionBg
        : (following || pendingOut
              ? AppColors.mintGreen
              : AppColors.zoviOrange);
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
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: followBg,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(
                    showTick ? AssetPaths.iconWhiteTick : AssetPaths.iconAdd2,
                    size: 22,
                    color: isDisabled ? followFg : null,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 20 / 15,
                        letterSpacing: -0.3,
                        color: followFg,
                      ),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 20 / 15,
                        letterSpacing: -0.3,
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

@immutable
final class _UserPlans extends StatelessWidget {
  const _UserPlans({required this.plans});

  final List<PlanItem> plans;

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

@immutable
final class _UserPlanCard extends StatelessWidget {
  const _UserPlanCard({required this.plan});

  final PlanItem plan;

  @override
  Widget build(BuildContext context) {
    final hasFriends = plan.hasJoiningFriends;
    final friendsText = hasFriends
        ? 'friends_are_joining'.tr(namedArgs: {'count': plan.friendsLabel})
        : 'no_friends_joining'.tr();

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
          if (hasFriends) ...[
            OverlappingProfileAvatars(avatars: plan.friendAvatars, overlap: 12),
            const SizedBox(width: 6),
          ],
          Text(
            friendsText,
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

@immutable
final class _UserTabs extends StatelessWidget {
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

@immutable
final class _UserTabItem extends StatelessWidget {
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

@immutable
final class _PulseStrip extends StatelessWidget {
  const _PulseStrip({required this.pulses});

  final List<PulseItem> pulses;

  @override
  Widget build(BuildContext context) {
    if (pulses.isEmpty) {
      return const _EmptyUserTabState(
        icon: AssetPaths.iconStory,
        messageKey: 'empty_user_pulses',
      );
    }

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
                  child: GestureDetector(
                    onTap: () => showPulseMediaViewer(
                      context,
                      imagePath: pulse.imagePath,
                      heroTag:
                          'user_pulse_${pulse.id.isNotEmpty ? pulse.id : pulse.imagePath}',
                      isVideo: pulse.isVideo,
                    ),
                    child: Hero(
                      tag:
                          'user_pulse_${pulse.id.isNotEmpty ? pulse.id : pulse.imagePath}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _PulseNetworkImage(
                          path: pulse.imagePath,
                          isVideo: pulse.isVideo,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

@immutable
final class _PulseNetworkImage extends StatelessWidget {
  const _PulseNetworkImage({required this.path, this.isVideo = false});

  final String path;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    final Widget image;
    if (isVideo) {
      image = const ColoredBox(color: AppColors.black);
    } else if (path.startsWith('http://') || path.startsWith('https://')) {
      final pixelWidth =
          ((MediaQuery.sizeOf(context).width / 3) * MediaQuery.devicePixelRatioOf(context))
              .ceil()
              .clamp(160, 480);
      image = CachedNetworkImage(
        imageUrl: bunnySizedUrl(path, pixelWidth),
        fit: BoxFit.cover,
        memCacheWidth: pixelWidth,
        fadeInDuration: Duration.zero,
        errorWidget: (_, _, _) =>
            const ColoredBox(color: AppColors.surfaceGray),
      );
    } else if (path.startsWith('/') || path.startsWith('file:')) {
      image = Image.file(
        File(path.replaceFirst('file://', '')),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            const ColoredBox(color: AppColors.surfaceGray),
      );
    } else if (path.isEmpty) {
      image = const ColoredBox(color: AppColors.surfaceGray);
    } else {
      image = Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            const ColoredBox(color: AppColors.surfaceGray),
      );
    }

    if (!isVideo) return image;
    return Stack(
      fit: StackFit.expand,
      children: [
        image,
        const Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: EdgeInsets.all(8),
            child: AppIcon(AssetPaths.iconReelsSquare, size: 20),
          ),
        ),
      ],
    );
  }
}

@immutable
final class _StampGrid extends StatelessWidget {
  const _StampGrid({required this.stamps});

  final List<StampItem> stamps;

  @override
  Widget build(BuildContext context) {
    if (stamps.isEmpty) {
      return const _EmptyUserTabState(
        icon: AssetPaths.iconAward,
        messageKey: 'empty_user_stamps',
      );
    }

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
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceGray,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: stamp.isNetwork
                              ? StampImage(
                                  path: stamp.imagePath,
                                  stampId: stamp.id,
                                  fit: BoxFit.contain,
                                )
                              : Image.asset(
                                  stamp.imagePath,
                                  fit: BoxFit.contain,
                                ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          stamp.title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1,
                            letterSpacing: -0.28,
                            color: AppColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

@immutable
final class _CheckInList extends StatelessWidget {
  const _CheckInList({required this.checkIns});

  final List<CheckInItem> checkIns;

  @override
  Widget build(BuildContext context) {
    if (checkIns.isEmpty) {
      return const _EmptyUserTabState(
        icon: AssetPaths.iconLocationOutlined,
        messageKey: 'empty_user_checkins',
      );
    }

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
                    child: Container(
                      width: 50,
                      height: 50,
                      padding: const EdgeInsets.all(10),
                      color: item.accentColor,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: item.hasPhoto
                            ? (item.isNetwork
                                  ? CachedNetworkImage(
                                      imageUrl: bunnySizedUrl(item.imagePath, 60),
                                      fit: BoxFit.cover,
                                      memCacheWidth: 60,
                                      fadeInDuration: Duration.zero,
                                      errorWidget: (_, _, _) => Image.asset(
                                        AssetPaths.checkinPlace,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Image.asset(
                                      item.imagePath,
                                      fit: BoxFit.cover,
                                    ))
                            : Image.asset(
                                AssetPaths.checkinPlace,
                                fit: BoxFit.cover,
                              ),
                      ),
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
                          style: const TextStyle(
                            fontFamily: 'SF Pro',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 1,
                            letterSpacing: -0.28,
                            color: AppColors.zoviOrange,
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

@immutable
final class _EmptyUserTabState extends StatelessWidget {
  const _EmptyUserTabState({required this.icon, required this.messageKey});

  final String icon;
  final String messageKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
        decoration: BoxDecoration(
          color: AppColors.surfaceGray,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderGray),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(icon, size: 26, color: AppColors.mutedGray),
            const SizedBox(height: 8),
            Text(
              messageKey.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
