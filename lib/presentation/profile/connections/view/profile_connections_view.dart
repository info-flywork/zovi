import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/in_app_notification/app_in_app_notification.dart';
import 'package:zovi/core/in_app_notification/in_app_notification_data.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/core/widgets/profile_avatar.dart';
import 'package:zovi/presentation/chat/model/chat_detail_route_args.dart';
import 'package:zovi/presentation/profile/connections/model/profile_connection_user.dart';
import 'package:zovi/presentation/profile/connections/model/profile_connections_route_args.dart';
import 'package:zovi/presentation/profile/connections/view/widgets/profile_connection_confirm_sheet.dart';

class ProfileConnectionsView extends StatefulWidget {
  const ProfileConnectionsView({required this.args, super.key});

  final ProfileConnectionsRouteArgs args;

  @override
  State<ProfileConnectionsView> createState() => _ProfileConnectionsViewState();
}

class _ProfileConnectionsViewState extends State<ProfileConnectionsView>
    with SingleTickerProviderStateMixin {
  static const _removeDuration = Duration(milliseconds: 280);

  late final TabController _tabController;
  late List<ProfileConnectionUser> _followers;
  late List<ProfileConnectionUser> _friends;
  final _followersListKey = GlobalKey<AnimatedListState>();
  final _friendsListKey = GlobalKey<AnimatedListState>();

  static const _demoUsers = [
    ProfileConnectionUser(
      username: 'jessica.3712',
      displayName: 'Jessica Black',
      avatarPath: AssetPaths.avatarJessica,
    ),
    ProfileConnectionUser(
      username: 'jonathanjnt',
      displayName: 'Jonathan Sam',
      avatarPath: AssetPaths.avatarAlex,
    ),
    ProfileConnectionUser(
      username: 'hannahfood',
      displayName: 'Just Hannah',
      avatarPath: AssetPaths.avatarSona,
    ),
    ProfileConnectionUser(
      username: 'clara.smith',
      displayName: 'Make With Clara',
      avatarPath: AssetPaths.avatarNova,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _followers = List<ProfileConnectionUser>.from(_demoUsers);
    _friends = List<ProfileConnectionUser>.from(_demoUsers);
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.args.initialTab == ProfileConnectionsTab.friends
          ? 1
          : 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _confirmRemoveFollower(ProfileConnectionUser user) async {
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
    AppInAppNotification.instance.show(
      InAppNotificationData(
        username: user.username,
        displayName: user.displayName,
        messageKey: 'in_app_removed_from_followers',
        avatarPath: user.avatarPath,
      ),
    );
  }

  Future<void> _confirmUnfollow(ProfileConnectionUser user) async {
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
    AppInAppNotification.instance.show(
      InAppNotificationData(
        username: user.username,
        displayName: user.displayName,
        messageKey: 'in_app_unfollowed',
        avatarPath: user.avatarPath,
      ),
    );
  }

  void _animateRemove({
    required List<ProfileConnectionUser> users,
    required GlobalKey<AnimatedListState> listKey,
    required ProfileConnectionUser user,
    required _ConnectionListMode mode,
  }) {
    final index = users.indexWhere((u) => u.username == user.username);
    if (index < 0) return;

    final removed = users.removeAt(index);
    listKey.currentState?.removeItem(
      index,
      (context, animation) => _ConnectionRemoveTile(
        user: removed,
        mode: mode,
        animation: animation,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final followersLabel = 'profile_connections_followers'.tr(
      namedArgs: {'count': '${widget.args.followersCount}'},
    );
    final friendsLabel = 'profile_connections_friends'.tr(
      namedArgs: {'count': '${widget.args.friendsCount}'},
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
                    icon: const AppIcon(AssetPaths.iconBack, size: 24),
                  ),
                  Expanded(
                    child: Text(
                      widget.args.username,
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
            child: TabBarView(
              controller: _tabController,
              children: [
                _ConnectionsList(
                  listKey: _followersListKey,
                  users: _followers,
                  mode: _ConnectionListMode.followers,
                  onSendMessage: _openChat,
                  onRemove: _confirmRemoveFollower,
                ),
                _ConnectionsList(
                  listKey: _friendsListKey,
                  users: _friends,
                  mode: _ConnectionListMode.friends,
                  onSendMessage: _openChat,
                  onRemove: _confirmUnfollow,
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

class _ConnectionsTabBar extends StatelessWidget {
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

class _ConnectionsTab extends StatelessWidget {
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

class _ConnectionsList extends StatelessWidget {
  const _ConnectionsList({
    required this.listKey,
    required this.users,
    required this.mode,
    required this.onSendMessage,
    required this.onRemove,
  });

  final GlobalKey<AnimatedListState> listKey;
  final List<ProfileConnectionUser> users;
  final _ConnectionListMode mode;
  final ValueChanged<ProfileConnectionUser> onSendMessage;
  final ValueChanged<ProfileConnectionUser> onRemove;

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
                onSendMessage: () => onSendMessage(user),
                onRemove: () => onRemove(user),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ConnectionRemoveTile extends StatelessWidget {
  const _ConnectionRemoveTile({
    required this.user,
    required this.mode,
    required this.animation,
  });

  final ProfileConnectionUser user;
  final _ConnectionListMode mode;
  final Animation<double> animation;

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
            onSendMessage: () {},
            onRemove: () {},
          ),
        ),
      ),
    );
  }
}

class _ConnectionTile extends StatelessWidget {
  const _ConnectionTile({
    required this.user,
    required this.mode,
    required this.onSendMessage,
    required this.onRemove,
  });

  final ProfileConnectionUser user;
  final _ConnectionListMode mode;
  final VoidCallback onSendMessage;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}

class _PillButton extends StatelessWidget {
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
