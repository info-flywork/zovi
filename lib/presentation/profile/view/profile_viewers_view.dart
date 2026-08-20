import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/billing/open_coin_paywall.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/navigation/open_user_profile.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/core/widgets/app_loading.dart';
import 'package:zovi/core/widgets/profile_avatar.dart';
import 'package:zovi/domain/auth/auth_repository.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/profile/stickers/view/widgets/create_sticker_confirm_sheet.dart';

const _kRevealCoinCost = 5;

@immutable
final class ProfileViewersView extends StatefulWidget {
  const ProfileViewersView({super.key});

  @override
  State<ProfileViewersView> createState() => _ProfileViewersViewState();
}

final class _ProfileViewersViewState extends State<ProfileViewersView> {
  final _userRepo = getIt<UserRepository>();
  late bool _loading;
  late List<ProfileViewerUser> _users;

  @override
  void initState() {
    super.initState();
    final cached = _userRepo.peekProfileViewers();
    if (cached != null) {
      _users = cached;
      _loading = false;
    } else {
      _users = const [];
      _loading = true;
    }
    _load(forceRefresh: !_userRepo.isProfileViewersCacheFresh);
  }

  Future<void> _load({bool forceRefresh = false}) async {
    try {
      final users = await _userRepo.fetchProfileViewers(
        limit: 200,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  int get _unrevealedCount => _users.where((u) => !u.revealed).length;

  Future<bool> _confirmRevealSpend({
    required int coinCost,
    required bool revealAll,
  }) async {
    final coins = _userRepo.cachedCurrentUser?.coins ?? 0;
    final action = await showCreateStickerConfirmSheet(
      context,
      coinBalance: coins,
      coinCost: coinCost,
      titleText: revealAll
          ? 'profile_viewers_sheet_title_all'.tr()
          : 'profile_viewers_sheet_title_one'.tr(),
      subtitleText: revealAll
          ? 'profile_viewers_sheet_subtitle_all'.tr(
              namedArgs: {'count': '$coinCost'},
            )
          : 'profile_viewers_sheet_subtitle_one'.tr(
              namedArgs: {'count': '$coinCost'},
            ),
      costLabelText: 'profile_viewers_sheet_cost_label'.tr(),
      confirmLabelText: 'profile_viewers_sheet_confirm'.tr(
        namedArgs: {'count': '$coinCost'},
      ),
    );
    if (!mounted || action == null) return false;
    if (action == CreateStickerConfirmAction.buyCoins) {
      await openZoviCoinPaywall(context);
      return false;
    }
    return true;
  }

  Future<void> _revealOne(ProfileViewerUser user) async {
    final ok = await _confirmRevealSpend(
      coinCost: _kRevealCoinCost,
      revealAll: false,
    );
    if (!ok || !mounted) return;
    try {
      await _userRepo.revealProfileViewer(user.userId);
      if (!mounted) return;
      setState(() {
        _users = [
          for (final u in _users)
            if (u.userId == user.userId) u.copyWith(revealed: true) else u,
        ];
      });
    } catch (_) {}
  }

  Future<void> _revealAll() async {
    final count = _unrevealedCount;
    if (count == 0) return;
    final totalCost = count * _kRevealCoinCost;
    final ok = await _confirmRevealSpend(
      coinCost: totalCost,
      revealAll: true,
    );
    if (!ok || !mounted) return;
    try {
      await _userRepo.revealAllProfileViewers();
      if (!mounted) return;
      setState(() {
        _users = [for (final u in _users) u.copyWith(revealed: true)];
      });
    } catch (_) {}
  }

  Future<void> _openProfile(ProfileViewerUser user) {
    return openUserProfile(context, user.username);
  }

  String _timeAgoLabel(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'profile_viewers_just_now'.tr();
    if (diff.inMinutes < 60) {
      return 'profile_viewers_minutes_ago'.tr(args: ['${diff.inMinutes}']);
    }
    if (diff.inHours < 24) {
      return 'profile_viewers_hours_ago'.tr(args: ['${diff.inHours}']);
    }
    if (diff.inDays < 7) {
      return 'profile_viewers_days_ago'.tr(args: ['${diff.inDays}']);
    }
    return DateFormat('d MMM').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final groups = _buildGroups();
    final showRevealAll = !_loading && _unrevealedCount > 0;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          SizedBox(height: top),
          _buildAppBar(),
          Expanded(
            child: _loading
                ? const AppLoading()
                : _users.isEmpty
                    ? Center(
                        child: Text(
                          'profile_viewers_empty'.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.deepRoast.withValues(alpha: 0.45),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          8,
                          16,
                          showRevealAll ? 16 : 24,
                        ),
                        itemCount: groups.length,
                        itemBuilder: (context, index) =>
                            _buildGroupSection(groups[index]),
                      ),
          ),
          if (showRevealAll)
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, bottom + 16),
              child: _RevealAllButton(
                coinCost: _unrevealedCount * _kRevealCoinCost,
                onTap: _revealAll,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            IconButton(
              onPressed: () => context.pop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              icon: const AppIcon(AssetPaths.iconArrowLeft, size: 24),
            ),
            Expanded(
              child: Text(
                'profile_viewers_title'.tr(),
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
    );
  }

  List<_ViewerGroup> _buildGroups() {
    if (_users.isEmpty) return [];
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(const Duration(days: 7));
    final monthStart = DateTime(now.year, now.month - 1, now.day);

    final today = <ProfileViewerUser>[];
    final week = <ProfileViewerUser>[];
    final month = <ProfileViewerUser>[];
    final older = <ProfileViewerUser>[];

    for (final user in _users) {
      final dt = user.lastViewedAt;
      if (dt == null) {
        older.add(user);
      } else if (dt.isAfter(todayStart)) {
        today.add(user);
      } else if (dt.isAfter(weekStart)) {
        week.add(user);
      } else if (dt.isAfter(monthStart)) {
        month.add(user);
      } else {
        older.add(user);
      }
    }

    return [
      if (today.isNotEmpty)
        _ViewerGroup('profile_viewers_today'.tr(), today),
      if (week.isNotEmpty)
        _ViewerGroup('profile_viewers_last_7_days'.tr(), week),
      if (month.isNotEmpty)
        _ViewerGroup('profile_viewers_last_month'.tr(), month),
      if (older.isNotEmpty)
        _ViewerGroup('profile_viewers_older'.tr(), older),
    ];
  }

  Widget _buildGroupSection(_ViewerGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 10),
          child: Text(
            group.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.28,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ...group.users.map(_buildUserTile),
      ],
    );
  }

  Widget _buildUserTile(ProfileViewerUser user) {
    final revealed = user.revealed;
    final username =
        revealed ? (user.username.isNotEmpty ? user.username : '@user') : '???';
    final name = revealed
        ? (user.fullName.isNotEmpty ? user.fullName : username)
        : 'profile_viewers_anonymous'.tr();

    return GestureDetector(
      onTap: revealed ? () => _openProfile(user) : () => _revealOne(user),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            _BlurredAvatar(
              path: user.avatarUrl,
              revealed: revealed,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BlurredText(
                    text: username,
                    revealed: revealed,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1,
                      letterSpacing: -0.32,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _BlurredText(
                    text: name,
                    revealed: revealed,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1,
                      letterSpacing: -0.28,
                      color: AppColors.black.withValues(alpha: 0.65),
                    ),
                  ),
                  if (user.lastViewedAt != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      _timeAgoLabel(user.lastViewedAt!),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.mutedGray,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!revealed)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.zoviOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(AssetPaths.zoviCoin, width: 14, height: 14),
                    const SizedBox(width: 3),
                    Text(
                      '$_kRevealCoinCost',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.zoviOrange,
                      ),
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

class _ViewerGroup {
  const _ViewerGroup(this.title, this.users);
  final String title;
  final List<ProfileViewerUser> users;
}

@immutable
final class _RevealAllButton extends StatelessWidget {
  const _RevealAllButton({
    required this.coinCost,
    required this.onTap,
  });

  final int coinCost;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Material(
        color: AppColors.zoviOrange,
        borderRadius: BorderRadius.circular(27),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(27),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(AssetPaths.zoviCoin, width: 20, height: 20),
              const SizedBox(width: 8),
              Text(
                'profile_viewers_reveal_all'.tr(args: ['$coinCost']),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlurredAvatar extends StatelessWidget {
  const _BlurredAvatar({required this.path, required this.revealed});
  final String path;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    final avatar = ProfileAvatar(path: path, size: 52);
    if (revealed) return avatar;
    return ClipOval(
      child: SizedBox(
        width: 52,
        height: 52,
        child: Stack(
          children: [
            avatar,
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  color: AppColors.black.withValues(alpha: 0.08),
                  child: const Center(
                    child: Icon(Icons.lock_outline_rounded,
                        size: 20, color: AppColors.white),
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

class _BlurredText extends StatelessWidget {
  const _BlurredText({
    required this.text,
    required this.revealed,
    required this.style,
  });
  final String text;
  final bool revealed;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    if (revealed) {
      return Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: style);
    }
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
    );
  }
}
