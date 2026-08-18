import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/core/widgets/app_loading.dart';
import 'package:zovi/core/widgets/app_search_field.dart';
import 'package:zovi/core/widgets/profile_avatar.dart';
import 'package:zovi/domain/auth/auth_repository.dart';

@immutable
final class CheckInFriend {
  const CheckInFriend({
    required this.id,
    required this.name,
    required this.avatarPath,
  });

  factory CheckInFriend.fromConnection(ConnectionUser user) {
    final name = user.fullName.trim().isNotEmpty
        ? user.fullName.trim()
        : (user.username.trim().isNotEmpty ? user.username.trim() : 'user');
    return CheckInFriend(
      id: user.userId,
      name: name,
      avatarPath: user.avatarUrl,
    );
  }

  final String id;
  final String name;
  final String avatarPath;
}

Future<List<CheckInFriend>?> showCheckInAddFriendsSheet(
  BuildContext context, {
  List<CheckInFriend> initiallySelected = const [],
}) {
  return showModalBottomSheet<List<CheckInFriend>>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) =>
        CheckInAddFriendsSheet(initiallySelected: initiallySelected),
  );
}

@immutable
final class CheckInAddFriendsSheet extends StatefulWidget {
  const CheckInAddFriendsSheet({this.initiallySelected = const [], super.key});

  final List<CheckInFriend> initiallySelected;

  @override
  State<CheckInAddFriendsSheet> createState() => _CheckInAddFriendsSheetState();
}

final class _CheckInAddFriendsSheetState extends State<CheckInAddFriendsSheet> {
  late final Set<String> _selectedIds;
  String _query = '';
  List<CheckInFriend> _friends = const [];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedIds = {for (final friend in widget.initiallySelected) friend.id};
    final auth = getIt<AuthRepository>();
    final userId = auth.backendUserId?.trim() ?? '';
    final cached = userId.isEmpty ? null : auth.peekFollowing(userId);
    if (cached != null) {
      _friends = [
        for (final user in cached)
          if (user.userId.isNotEmpty) CheckInFriend.fromConnection(user),
      ];
      _loading = false;
    }
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      final auth = getIt<AuthRepository>();
      final userId = auth.backendUserId?.trim() ?? '';
      if (userId.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final users = await auth.fetchFollowing(userId);
      if (!mounted) return;
      setState(() {
        _friends = [
          for (final user in users)
            if (user.userId.isNotEmpty) CheckInFriend.fromConnection(user),
        ];
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (_friends.isEmpty) _friends = const [];
        _loading = false;
      });
    }
  }

  List<CheckInFriend> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _friends;
    return _friends
        .where((f) => f.name.toLowerCase().contains(q))
        .toList();
  }

  List<CheckInFriend> get _selectedFriends {
    final byId = <String, CheckInFriend>{
      for (final f in _friends) f.id: f,
      for (final f in widget.initiallySelected) f.id: f,
    };
    return [
      for (final id in _selectedIds)
        if (byId[id] != null) byId[id]!,
    ];
  }

  void _toggle(CheckInFriend friend) {
    setState(() {
      if (_selectedIds.contains(friend.id)) {
        _selectedIds.remove(friend.id);
      } else {
        _selectedIds.add(friend.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final selectedCount = _selectedIds.length;
    final canSubmit = selectedCount > 0;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Column(
              children: [
                Container(
                  width: 46,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: const AppIcon(AssetPaths.iconCloseCircle),
                  ),
                ),
                const SizedBox(height: 10),
                AppSearchField(
                  hintText: 'check_in_search_friends'.tr(),
                  onDebouncedChanged: (value) {
                    setState(() => _query = value);
                  },
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _loading
                      ? const AppLoading(size: 28)
                      : filtered.isEmpty
                          ? const _FriendsEmptyState()
                          : GridView.builder(
                              padding: const EdgeInsets.only(bottom: 12),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 1,
                                  ),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final friend = filtered[index];
                                final selected =
                                    _selectedIds.contains(friend.id);
                                return _FriendSelectTile(
                                  friend: friend,
                                  selected: selected,
                                  onTap: () => _toggle(friend),
                                );
                              },
                            ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Material(
                    color: canSubmit
                        ? AppColors.zoviOrange
                        : AppColors.zoviOrange.withValues(alpha: 0.35),
                    shape: const StadiumBorder(),
                    child: InkWell(
                      onTap: canSubmit
                          ? () => Navigator.of(context).pop(_selectedFriends)
                          : null,
                      customBorder: const StadiumBorder(),
                      child: Center(
                        child: Text(
                          'check_in_add_friends_count'.tr(
                            namedArgs: {'count': '$selectedCount'},
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 20 / 16,
                            color: AppColors.white.withValues(
                              alpha: canSubmit ? 1 : 0.7,
                            ),
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
      ),
    );
  }
}

@immutable
final class _FriendSelectTile extends StatelessWidget {
  const _FriendSelectTile({
    required this.friend,
    required this.selected,
    required this.onTap,
  });

  final CheckInFriend friend;
  final bool selected;
  final VoidCallback onTap;

  static const _avatarSize = 79.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: _avatarSize,
            height: _avatarSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: _avatarSize,
                  height: _avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? AppColors.zoviOrange
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: ProfileAvatar(
                    path: friend.avatarPath,
                    size: _avatarSize - 6,
                  ),
                ),
                if (selected)
                  const Positioned(
                    right: -2,
                    bottom: -2,
                    child: AppIcon(AssetPaths.iconTickCircleOrange, size: 24),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            friend.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              height: 1,
              letterSpacing: -0.4,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}

@immutable
final class _FriendsEmptyState extends StatelessWidget {
  const _FriendsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            AssetPaths.iconSearch,
            size: 40,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            'check_in_friends_empty'.tr(),
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
