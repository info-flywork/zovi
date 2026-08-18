import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/snackbar/app_snackbar.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/utils/navigation/open_user_profile.dart';
import 'package:zovi/core/widgets/app_button.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/core/widgets/profile_avatar.dart';
import 'package:zovi/domain/tribe/tribe_repository.dart';
import 'package:zovi/presentation/chat/model/chat_detail_route_args.dart';
import 'package:zovi/presentation/chat/model/group_info_route_args.dart';
import 'package:zovi/presentation/profile/settings/view/widgets/blocked_users_sheet.dart';

const _leaveRed = Color(0xFFE30A17);
const _streakPink = Color(0xFFFF4D6D);

@immutable
final class GroupInfoView extends StatefulWidget {
  const GroupInfoView({required this.args, super.key});

  final GroupInfoRouteArgs args;

  @override
  State<GroupInfoView> createState() => _GroupInfoViewState();
}

final class _GroupInfoViewState extends State<GroupInfoView> {
  final TribeRepository _tribes = getIt<TribeRepository>();
  var _notificationsOn = true;
  var _leaving = false;
  var _loadingMembers = true;
  late int _memberCount = widget.args.memberCount;
  List<BlockedUser> _blockedUsers = const [];
  List<_GroupMember> _members = const [];

  @override
  void initState() {
    super.initState();
    _hydrateFromCache();
    unawaited(_loadMembers());
  }

  void _hydrateFromCache() {
    final tribeId = widget.args.tribeId.trim();
    if (tribeId.isEmpty) return;
    final cached = _tribes.peekTribeDetail(tribeId);
    if (cached == null) return;
    if (cached.memberCount > 0) _memberCount = cached.memberCount;
    if (cached.members.isNotEmpty) {
      _members = _mapMembers(cached);
      _loadingMembers = false;
    }
  }

  List<_GroupMember> _mapMembers(Tribe detail) => [
        for (final m in detail.members)
          _GroupMember(
            userId: m.userId,
            name: m.isMe ? null : (m.name.isNotEmpty ? m.name : m.username),
            nameKey: m.isMe ? 'group_info_you' : null,
            fullName: m.name.isNotEmpty ? m.name : m.username,
            username: m.username,
            avatarPath: m.avatarUrl,
            streak: m.streakCount,
            isMe: m.isMe,
          ),
      ];

  Future<void> _loadMembers() async {
    final tribeId = widget.args.tribeId.trim();
    if (tribeId.isEmpty) {
      if (mounted) setState(() => _loadingMembers = false);
      return;
    }
    try {
      final detail = await _tribes.refreshTribeDetail(tribeId);
      if (!mounted) return;
      if (detail == null) {
        setState(() => _loadingMembers = false);
        return;
      }
      setState(() {
        _memberCount = detail.memberCount;
        _members = _mapMembers(detail);
        _loadingMembers = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMembers = false);
    }
  }

  Future<void> _openBlockedUsers() async {
    final updated = await showBlockedUsersSheet(context, users: _blockedUsers);
    if (!mounted) return;
    setState(() => _blockedUsers = updated);
  }

  Future<void> _leaveGroup() async {
    if (_leaving) return;
    final confirmed = await showLeaveGroupSheet(context);
    if (!confirmed || !mounted) return;

    final tribeId = widget.args.tribeId.trim();
    if (tribeId.isEmpty) {
      context.go(RoutePaths.tribe.path);
      return;
    }

    setState(() => _leaving = true);
    try {
      await _tribes.leaveTribe(tribeId);
      if (!mounted) return;
      context.go(RoutePaths.tribe.path);
    } catch (_) {
      if (!mounted) return;
      setState(() => _leaving = false);
      AppSnackbar.instance.show(
        context,
        'group_info_leave_failed'.tr(),
        isError: true,
      );
    }
  }

  void _openMember(_GroupMember member) {
    if (member.isMe) return;
    _showMemberProfileSheet(context, member: member);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: ListView(
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [
                          AppColors.zoviOrange.withValues(alpha: 0.22),
                          AppColors.chatPurple.withValues(alpha: 0.16),
                          AppColors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: GestureDetector(
                                onTap: () => context.pop(),
                                behavior: HitTestBehavior.opaque,
                                child: const AppIcon(
                                  AssetPaths.iconArrowLeft,
                                  size: 32,
                                ),
                              ),
                            ),
                            const SizedBox(height: 68),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -60,
                    child: Container(
                      width: 120,
                      height: 120,
                      padding: const EdgeInsets.fromLTRB(5, 1, 5, 1),
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: ProfileAvatar(
                          path: widget.args.avatarPath,
                          size: 110,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 74),
              Text(
                widget.args.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1,
                  letterSpacing: -0.4,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: _StatChip(
                  label: 'group_info_members_count'.tr(
                    namedArgs: {'count': '$_memberCount'},
                  ),
                  icon: AssetPaths.iconMember,
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel('group_info_media'.tr()),
                const SizedBox(height: 10),
                _SettingsCard(
                  children: [
                    _SettingsRow(
                      icon: AssetPaths.iconUserSquare,
                      title: 'group_info_gallery'.tr(),
                      onTap: () {
                        context.push(
                          RoutePaths.groupGallery.path,
                          extra: widget.args,
                        );
                      },
                      trailing: const AppIcon(AssetPaths.iconRight, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SectionLabel('group_info_settings'.tr()),
                const SizedBox(height: 10),
                _SettingsCard(
                  children: [
                    _SettingsRow(
                      icon: AssetPaths.iconNotificationBing,
                      title: 'group_info_notifications'.tr(),
                      trailing: SizedBox(
                        height: 28,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: CupertinoSwitch(
                            value: _notificationsOn,
                            activeTrackColor: AppColors.switchActive,
                            onChanged: (value) {
                              setState(() => _notificationsOn = value);
                            },
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE8E8F0)),
                    _SettingsRow(
                      icon: AssetPaths.iconForbidden,
                      title: 'group_info_blocked'.tr(),
                      onTap: _openBlockedUsers,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_blockedUsers.length}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const AppIcon(AssetPaths.iconRight, size: 20),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'group_info_members_count'.tr(
                          namedArgs: {'count': '$_memberCount'},
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1,
                          letterSpacing: -0.24,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_loadingMembers && _members.isEmpty)
                        const _MembersListShimmer()
                      else
                        for (final member in _members)
                          _MemberRow(
                            member: member,
                            onTap: () => _openMember(member),
                          ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _SectionLabel('group_info_group_settings'.tr()),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _leaving ? null : _leaveGroup,
                  behavior: HitTestBehavior.opaque,
                  child: Opacity(
                    opacity: _leaving ? 0.45 : 1,
                    child: Text(
                      'group_info_leave'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 1,
                        letterSpacing: -0.32,
                        color: _leaveRed,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: kBottomNavigationBarHeight),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

@immutable
final class _GroupMember {
  const _GroupMember({
    required this.avatarPath,
    required this.streak,
    this.userId = '',
    this.name,
    this.nameKey,
    this.fullName,
    this.username = '',
    this.isMe = false,
  });

  final String userId;
  final String? name;
  final String? nameKey;
  final String? fullName;
  final String username;
  final String avatarPath;
  final int streak;
  final bool isMe;

  String get displayName => nameKey?.tr() ?? name ?? '';
  String get profileName => fullName ?? displayName;
  String get profileKey =>
      username.trim().isNotEmpty ? username.trim() : profileName;
}

@immutable
final class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.icon});

  final String label;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
      decoration: BoxDecoration(
        color: _streakPink.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1,
              color: _streakPink,
            ),
          ),
          const SizedBox(width: 4),
          AppIcon(icon, size: 24),
        ],
      ),
    );
  }
}

@immutable
final class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1,
        letterSpacing: -0.28,
        color: AppColors.textSecondary,
      ),
    );
  }
}

@immutable
final class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E2E2)),
      ),
      child: Column(children: children),
    );
  }
}

@immutable
final class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.trailing,
    this.onTap,
  });

  final String icon;
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            AppIcon(icon, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1,
                  letterSpacing: -0.32,
                  color: AppColors.black,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

@immutable
final class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.onTap});

  final _GroupMember member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipOval(
              child: ProfileAvatar(path: member.avatarPath, size: 40),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                member.displayName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1,
                  letterSpacing: -0.32,
                  color: AppColors.black,
                ),
              ),
            ),
            if (!member.isMe) const AppIcon(AssetPaths.iconRight, size: 20),
          ],
        ),
      ),
    );
  }
}

@immutable
final class _MembersListShimmer extends StatelessWidget {
  const _MembersListShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8E8E8),
      highlightColor: const Color(0xFFF5F5F5),
      child: Column(
        children: List.generate(
          4,
          (_) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 120,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool> showLeaveGroupSheet(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const _LeaveGroupSheet(),
  );
  return result ?? false;
}

@immutable
final class _LeaveGroupSheet extends StatelessWidget {
  const _LeaveGroupSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'group_info_leave'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1,
                letterSpacing: -0.4,
                color: _leaveRed,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'group_info_leave_subtitle'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 20 / 16,
                letterSpacing: -0.32,
                color: AppColors.deepRoast.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'cancel'.tr(),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(true),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'group_info_leave_confirm'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 20 / 16,
                    color: AppColors.deepRoast,
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

Future<void> _showMemberProfileSheet(
  BuildContext context, {
  required _GroupMember member,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => _MemberProfileSheet(
      member: member,
      parentContext: context,
    ),
  );
}

@immutable
final class _MemberProfileSheet extends StatelessWidget {
  const _MemberProfileSheet({
    required this.member,
    required this.parentContext,
  });

  final _GroupMember member;
  final BuildContext parentContext;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
            const SizedBox(height: 24),
            ClipOval(
              child: ProfileAvatar(path: member.avatarPath, size: 100),
            ),
            const SizedBox(height: 14),
            Text(
              member.profileName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1,
                letterSpacing: -0.4,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 12),
            _StatChip(
              label: 'group_info_streak_count'.tr(
                namedArgs: {'count': '${member.streak}'},
              ),
              icon: AssetPaths.iconStreak,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'group_info_send_message'.tr(),
              onPressed: () {
                Navigator.of(context).pop();
                parentContext.push(
                  RoutePaths.chatDetail.path,
                  extra: ChatDetailRouteArgs(
                    name: member.profileName,
                    username: member.profileKey,
                    avatarPath: member.avatarPath,
                    userId: member.userId,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                Navigator.of(context).pop();
                await openUserProfile(
                  parentContext,
                  member.profileKey,
                );
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'group_info_view_profile'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 20 / 16,
                    color: AppColors.deepRoast,
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
