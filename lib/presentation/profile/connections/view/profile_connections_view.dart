import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/in_app_notification/app_in_app_notification.dart';
import 'package:zovi/core/in_app_notification/in_app_notification_data.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/utils/navigation/open_user_profile.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/core/widgets/app_loading.dart';
import 'package:zovi/core/widgets/profile_avatar.dart';
import 'package:zovi/domain/auth/auth_repository.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/chat/model/chat_detail_route_args.dart';
import 'package:zovi/presentation/profile/connections/model/profile_connection_user.dart';
import 'package:zovi/presentation/profile/connections/model/profile_connections_route_args.dart';
import 'package:zovi/presentation/profile/connections/view/widgets/profile_connection_confirm_sheet.dart';

@immutable
final class ProfileConnectionsView extends StatefulWidget {
  const ProfileConnectionsView({required this.args, super.key});

  final ProfileConnectionsRouteArgs args;

  @override
  State<ProfileConnectionsView> createState() => _ProfileConnectionsViewState();
}

final class _ProfileConnectionsViewState extends State<ProfileConnectionsView>
    with SingleTickerProviderStateMixin {
  static const _removeDuration = Duration(milliseconds: 280);

  late final TabController _tabController;
  var _loading = true;
  var _followersCount = 0;
  var _followingCount = 0;
  List<ProfileConnectionUser> _followers = const [];
  List<ProfileConnectionUser> _friends = const [];
  final _followersListKey = GlobalKey<AnimatedListState>();
  final _friendsListKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _followersCount = widget.args.followersCount;
    _followingCount = widget.args.friendsCount;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.args.initialTab == ProfileConnectionsTab.friends
          ? 1
          : 0,
    );
    unawaited(_load());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = getIt<AuthRepository>();
    var userId = widget.args.userId.trim();
    if (userId.isEmpty && widget.args.isOwnProfile) {
      userId = auth.backendUserId?.trim() ?? '';
    }
    if (userId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _followers = const [];
        _friends = const [];
        _loading = false;
      });
      return;
    }

    try {
      final results = await Future.wait([
        auth.fetchFollowers(userId),
        auth.fetchFollowing(userId),
      ]);
      if (!mounted) return;
      setState(() {
        _followers = [
          for (final u in results[0]) ProfileConnectionUser.fromConnection(u),
        ];
        _friends = [
          for (final u in results[1]) ProfileConnectionUser.fromConnection(u),
        ];
        _followersCount = _followers.length;
        _followingCount = _friends.length;
        _loading = false;
      });
      // The stored counters can drift when the other side unfollows us, so
      // treat the freshly fetched lists as the source of truth.
      _syncOwnCounts();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _followers = const [];
        _friends = const [];
        _loading = false;
      });
    }
  }

  Future<void> _confirmRemoveFollower(ProfileConnectionUser user) async {
    if (!widget.args.isOwnProfile) return;
    final confirmed = await showProfileConnectionConfirmSheet(
      context,
      action: ProfileConnectionConfirmAction.removeFollower,
      username: user.username,
    );
    if (!confirmed || !mounted) return;

    _animateRemove(
      users: _followers,
      listKey: _followersListKey,
      user: user,
      mode: _ConnectionListMode.followers,
    );
    setState(() => _followersCount = _followers.length);

    try {
      await getIt<AuthRepository>().removeFollower(user.userId);
      if (!mounted) return;
      _syncOwnCounts();
      AppInAppNotification.instance.show(
        InAppNotificationData(
          username: user.username,
          displayName: user.displayName,
          messageKey: 'in_app_removed_from_followers',
          avatarPath: user.avatarPath,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      unawaited(_load());
    }
  }

  Future<void> _confirmUnfollow(ProfileConnectionUser user) async {
    if (!widget.args.isOwnProfile) return;
    final confirmed = await showProfileConnectionConfirmSheet(
      context,
      action: ProfileConnectionConfirmAction.unfollow,
      username: user.username,
    );
    if (!confirmed || !mounted) return;

    _animateRemove(
      users: _friends,
      listKey: _friendsListKey,
      user: user,
      mode: _ConnectionListMode.friends,
    );
    setState(() => _followingCount = _friends.length);

    try {
      await getIt<AuthRepository>().unfollowUser(user.userId);
      if (!mounted) return;
      _syncOwnCounts();
      AppInAppNotification.instance.show(
        InAppNotificationData(
          username: user.username,
          displayName: user.displayName,
          messageKey: 'in_app_unfollowed',
          avatarPath: user.avatarPath,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      unawaited(_load());
    }
  }

  void _syncOwnCounts() {
    if (!widget.args.isOwnProfile) return;
    final repo = getIt<UserRepository>();
    final current = repo.cachedCurrentUser;
    if (current == null) return;
    unawaited(
      repo.updateCurrentUser(
        current.copyWith(followers: _followersCount, friends: _followingCount),
      ),
    );
  }

  void _animateRemove({
    required List<ProfileConnectionUser> users,
    required GlobalKey<AnimatedListState> listKey,
    required ProfileConnectionUser user,
    required _ConnectionListMode mode,
  }) {
    final index = users.indexWhere(
      (u) => u.userId == user.userId || u.username == user.username,
    );
    if (index < 0) return;

    final removed = users.removeAt(index);
    listKey.currentState?.removeItem(
      index,
      (context, animation) => _ConnectionRemoveTile(
        user: removed,
        mode: mode,
        animation: animation,
        showOwnerActions: widget.args.isOwnProfile,
      ),
      duration: _removeDuration,
    );

    if (users.isEmpty) {
      Future<void>.delayed(_removeDuration, () {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  void _openChat(ProfileConnectionUser user) {
    context.push(
      RoutePaths.chatDetail.path,
      extra: ChatDetailRouteArgs(
        name: user.displayName,
        username: user.username,
        avatarPath: user.avatarPath,
        userId: user.userId,
      ),
    );
  }

  Future<void> _openProfile(ProfileConnectionUser user) async {
    await openUserProfile(
      context,
      user.username,
      userId: user.userId,
      seed: PublicUserProfile.skeleton(
        username: user.username,
        name: user.displayName,
        avatarPath: user.avatarPath,
        userId: user.userId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final followersLabel = 'profile_connections_followers'.tr(
      namedArgs: {'count': '$_followersCount'},
    );
    final friendsLabel = 'profile_connections_friends'.tr(
      namedArgs: {'count': '$_followingCount'},
    );

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          SizedBox(height: top),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
            child: SizedBox(
              height: 44,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    icon: const AppIcon(AssetPaths.iconArrowLeft, size: 24),
                  ),
                  Expanded(
                    child: Text(
                      widget.args.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        height: 1,
                        letterSpacing: -0.5,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AnimatedBuilder(
              animation: _tabController.animation!,
              builder: (context, _) {
                final progress = _tabController.animation!.value.clamp(
                  0.0,
                  1.0,
                );
                return _ConnectionsTabBar(
                  followersLabel: followersLabel,
                  friendsLabel: friendsLabel,
                  progress: progress,
                  onSelect: (index) => _tabController.animateTo(index),
                );
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const AppLoading()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _ConnectionsList(
                        listKey: _followersListKey,
                        users: _followers,
                        mode: _ConnectionListMode.followers,
                        showOwnerActions: widget.args.isOwnProfile,
                        onSendMessage: _openChat,
                        onRemove: _confirmRemoveFollower,
                        onProfileTap: _openProfile,
                      ),
                      _ConnectionsList(
                        listKey: _friendsListKey,
                        users: _friends,
                        mode: _ConnectionListMode.friends,
                        showOwnerActions: widget.args.isOwnProfile,
                        onSendMessage: _openChat,
                        onRemove: _confirmUnfollow,
                        onProfileTap: _openProfile,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

enum _ConnectionListMode { followers, friends }

@immutable
final class _ConnectionsTabBar extends StatelessWidget {
  const _ConnectionsTabBar({
    required this.followersLabel,
    required this.friendsLabel,
    required this.progress,
    required this.onSelect,
  });

  final String followersLabel;
  final String friendsLabel;
  final double progress;
  final ValueChanged<int> onSelect;

  static const _gap = 10.0;
  static const _inactive = Color(0x801A1714);

  @override
  Widget build(BuildContext context) {
    final followersColor = Color.lerp(
      AppColors.zoviOrange,
      _inactive,
      progress,
    )!;
    final friendsColor = Color.lerp(_inactive, AppColors.zoviOrange, progress)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tabWidth = (constraints.maxWidth - _gap) / 2;
        return Stack(
          children: [
            Row(
              children: [
                Expanded(
                  child: _ConnectionsTab(
                    label: followersLabel,
                    color: followersColor,
                    onTap: () => onSelect(0),
                  ),
                ),
                const SizedBox(width: _gap),
                Expanded(
                  child: _ConnectionsTab(
                    label: friendsLabel,
                    color: friendsColor,
                    onTap: () => onSelect(1),
                  ),
                ),
              ],
            ),
            Positioned(
              left: progress * (tabWidth + _gap),
              bottom: 0,
              width: tabWidth,
              child: const ColoredBox(
                color: AppColors.zoviOrange,
                child: SizedBox(height: 1),
              ),
            ),
          ],
        );
      },
    );
  }
}

@immutable
final class _ConnectionsTab extends StatelessWidget {
  const _ConnectionsTab({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
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
final class _ConnectionsList extends StatelessWidget {
  const _ConnectionsList({
    required this.listKey,
    required this.users,
    required this.mode,
    required this.showOwnerActions,
    required this.onSendMessage,
    required this.onRemove,
    required this.onProfileTap,
  });

  final GlobalKey<AnimatedListState> listKey;
  final List<ProfileConnectionUser> users;
  final _ConnectionListMode mode;
  final bool showOwnerActions;
  final ValueChanged<ProfileConnectionUser> onSendMessage;
  final ValueChanged<ProfileConnectionUser> onRemove;
  final ValueChanged<ProfileConnectionUser> onProfileTap;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(
        child: Text(
          mode == _ConnectionListMode.followers
              ? 'profile_connections_followers_empty'.tr()
              : 'profile_connections_friends_empty'.tr(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.deepRoast.withValues(alpha: 0.45),
          ),
        ),
      );
    }

    return AnimatedList(
      key: listKey,
      initialItemCount: users.length,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemBuilder: (context, index, animation) {
        final user = users[index];
        return Padding(
          padding: EdgeInsets.only(bottom: index == users.length - 1 ? 0 : 16),
          child: SizeTransition(
            sizeFactor: animation,
            child: FadeTransition(
              opacity: animation,
              child: _ConnectionTile(
                user: user,
                mode: mode,
                showOwnerActions: showOwnerActions,
                onSendMessage: () => onSendMessage(user),
                onRemove: () => onRemove(user),
                onProfileTap: () => onProfileTap(user),
              ),
            ),
          ),
        );
      },
    );
  }
}

@immutable
final class _ConnectionRemoveTile extends StatelessWidget {
  const _ConnectionRemoveTile({
    required this.user,
    required this.mode,
    required this.animation,
    required this.showOwnerActions,
  });

  final ProfileConnectionUser user;
  final _ConnectionListMode mode;
  final Animation<double> animation;
  final bool showOwnerActions;

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _ConnectionTile(
            user: user,
            mode: mode,
            showOwnerActions: showOwnerActions,
            onSendMessage: () {},
            onRemove: () {},
            onProfileTap: () {},
          ),
        ),
      ),
    );
  }
}

@immutable
final class _ConnectionTile extends StatelessWidget {
  const _ConnectionTile({
    required this.user,
    required this.mode,
    required this.showOwnerActions,
    required this.onSendMessage,
    required this.onRemove,
    required this.onProfileTap,
  });

  final ProfileConnectionUser user;
  final _ConnectionListMode mode;
  final bool showOwnerActions;
  final VoidCallback onSendMessage;
  final VoidCallback onRemove;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onProfileTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                ProfileAvatar(path: user.avatarPath, size: 60),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
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
                        user.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1,
                          letterSpacing: -0.28,
                          color: AppColors.black.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showOwnerActions) ...[
          const SizedBox(width: 10),
          if (mode == _ConnectionListMode.followers) ...[
            _PillButton(
              label: 'profile_connections_send_message'.tr(),
              filled: false,
              onTap: onSendMessage,
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: AppIcon(AssetPaths.iconClosee, size: 24),
              ),
            ),
          ] else
            _PillButton(
              label: 'profile_connections_unfollow'.tr(),
              filled: true,
              onTap: onRemove,
            ),
        ],
      ],
    );
  }
}

@immutable
final class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: filled
              ? AppColors.zoviOrange
              : AppColors.zoviOrange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1,
            letterSpacing: -0.28,
            color: filled ? AppColors.white : AppColors.zoviOrange,
          ),
        ),
      ),
    );
  }
}
