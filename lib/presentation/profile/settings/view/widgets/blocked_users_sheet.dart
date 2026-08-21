import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/navigation/open_user_profile.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/core/widgets/app_search_field.dart';
import 'package:zovi/core/widgets/profile_avatar.dart';
import 'package:zovi/domain/user/user_repository.dart';

@immutable
final class BlockedUser {
  const BlockedUser({
    this.userId = '',
    required this.username,
    required this.avatarPath,
  });

  final String userId;
  final String username;
  final String avatarPath;
}

Future<List<BlockedUser>> showBlockedUsersSheet(
  BuildContext context, {
  required List<BlockedUser> users,
}) async {
  var current = List<BlockedUser>.from(users);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => BlockedUsersSheet(
      users: current,
      onUsersChanged: (updated) => current = updated,
    ),
  );

  return current;
}

@immutable
final class BlockedUsersSheet extends StatefulWidget {
  const BlockedUsersSheet({
    required this.users,
    required this.onUsersChanged,
    super.key,
  });

  final List<BlockedUser> users;
  final ValueChanged<List<BlockedUser>> onUsersChanged;

  @override
  State<BlockedUsersSheet> createState() => _BlockedUsersSheetState();
}

final class _BlockedUsersSheetState extends State<BlockedUsersSheet> {
  static const _removeDuration = Duration(milliseconds: 280);

  GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  late List<BlockedUser> _users;
  late List<BlockedUser> _visibleUsers;
  String _query = '';

  List<BlockedUser> _filter(List<BlockedUser> source, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return List<BlockedUser>.from(source);
    return source
        .where((user) => user.username.toLowerCase().contains(normalized))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _users = List<BlockedUser>.from(widget.users);
    _visibleUsers = _filter(_users, _query);
  }

  void _onSearchChanged(String value) {
    setState(() {
      _query = value;
      _visibleUsers = _filter(_users, _query);
      _listKey = GlobalKey<AnimatedListState>();
    });
  }

  void _unblock(BlockedUser user) {
    final index = _visibleUsers.indexOf(user);
    if (index < 0) return;

    final removed = _visibleUsers.removeAt(index);
    _users.remove(removed);
    widget.onUsersChanged(List<BlockedUser>.from(_users));

    _listKey.currentState?.removeItem(
      index,
      (context, animation) =>
          _BlockedUserRemoveTile(user: removed, animation: animation),
      duration: _removeDuration,
    );

    if (_visibleUsers.isEmpty) {
      Future<void>.delayed(_removeDuration, () {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = _visibleUsers.isEmpty;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.4,
        maxChildSize: 0.75,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
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
                        'blocked_sheet_title'.tr(),
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
                        'blocked_sheet_subtitle'.tr(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 20 / 16,
                          letterSpacing: -0.32,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      AppSearchField(
                        hintText: 'search_hint'.tr(),
                        onDebouncedChanged: _onSearchChanged,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                Expanded(
                  child: isEmpty
                      ? ListView(
                          controller: scrollController,
                          physics: const ClampingScrollPhysics(),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          children: [
                            SizedBox(
                              height: MediaQuery.sizeOf(context).height * 0.2,
                              child: _BlockedEmptyState(
                                hasUsers: _users.isNotEmpty,
                              ),
                            ),
                          ],
                        )
                      : AnimatedList(
                          key: _listKey,
                          controller: scrollController,
                          physics: const ClampingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            16,
                            8,
                            16,
                            24 + MediaQuery.paddingOf(context).bottom,
                          ),
                          initialItemCount: _visibleUsers.length,
                          itemBuilder: (context, index, animation) {
                            final user = _visibleUsers[index];
                            return _BlockedUserRemoveTile(
                              user: user,
                              animation: animation,
                              onUnblock: () => _unblock(user),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

@immutable
final class _BlockedUserRemoveTile extends StatelessWidget {
  const _BlockedUserRemoveTile({
    required this.user,
    required this.animation,
    this.onUnblock,
  });

  final BlockedUser user;
  final Animation<double> animation;
  final VoidCallback? onUnblock;

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: animation,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0.08, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _BlockedUserRow(user: user, onUnblock: onUnblock ?? () {}),
          ),
        ),
      ),
    );
  }
}

@immutable
final class _BlockedEmptyState extends StatelessWidget {
  const _BlockedEmptyState({required this.hasUsers});

  final bool hasUsers;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            hasUsers ? AssetPaths.iconSearch : AssetPaths.iconForbidden,
            size: 40,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            hasUsers ? 'blocked_empty_search'.tr() : 'blocked_empty'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1,
              letterSpacing: -0.32,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

@immutable
final class _BlockedUserRow extends StatelessWidget {
  const _BlockedUserRow({required this.user, required this.onUnblock});

  final BlockedUser user;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              final handle = user.username.trim();
              if (handle.isEmpty) return;
              openUserProfile(
                context,
                handle,
                seed: PublicUserProfile.skeleton(
                  username: handle,
                  avatarPath: user.avatarPath,
                  userId: user.userId,
                ),
              );
            },
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                ProfileAvatar(
                  path: user.avatarPath,
                  size: 48,
                  showGradientRing: true,
                  ringGap: 1.5,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    user.username,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 20 / 16,
                      letterSpacing: -0.32,
                      color: AppColors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: onUnblock,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.zoviOrange,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(
              'blocked_unblock'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1,
                letterSpacing: -0.32,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
