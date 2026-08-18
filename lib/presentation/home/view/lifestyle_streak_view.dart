import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/utils/navigation/open_user_profile.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/core/widgets/profile_avatar.dart';
import 'package:zovi/domain/user/user_repository.dart';

const _streakPink = Color(0xFFFF4D6D);
const _categoryFill = Color(0xFFF4F4F9);

@immutable
final class LifestyleStreakView extends StatefulWidget {
  const LifestyleStreakView({super.key});

  @override
  State<LifestyleStreakView> createState() => _LifestyleStreakViewState();
}

final class _LifestyleStreakViewState extends State<LifestyleStreakView> {
  static const _categories = <_StreakCategory>[
    _StreakCategory(
      key: 'culture',
      emoji: '🎨',
      labelKey: 'lifestyle_category_culture',
    ),
    _StreakCategory(
      key: 'restaurant',
      emoji: '🍕',
      labelKey: 'lifestyle_category_restaurant',
    ),
    _StreakCategory(
      key: 'cafe',
      emoji: '☕',
      labelKey: 'lifestyle_category_cafe',
    ),
    _StreakCategory(
      key: 'gym',
      emoji: '🏋️',
      labelKey: 'lifestyle_category_gym',
    ),
    _StreakCategory(
      key: 'music',
      emoji: '🎵',
      labelKey: 'lifestyle_category_music',
    ),
    _StreakCategory(
      key: 'park',
      emoji: '🌿',
      labelKey: 'lifestyle_category_park',
    ),
  ];

  var _loading = true;
  List<_StreakUser> _users = const [];
  var _totalPoints = 0;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    final cached = getIt<UserRepository>().peekFriendshipStreaks();
    if (cached != null) {
      _applyRows(cached, loading: false);
      return;
    }
    _load(showLoading: true);
  }

  static String? _normalizeCategory(String? raw) {
    final c = (raw ?? '').trim().toLowerCase();
    if (c == 'food' || c == 'restaurant') return 'restaurant';
    if (c == 'coffee' || c == 'cafe') return 'cafe';
    if (c == 'culture' ||
        c == 'gym' ||
        c == 'music' ||
        c == 'park' ||
        c == 'restaurant' ||
        c == 'cafe') {
      return c;
    }
    return null;
  }

  static List<String> _parseCategories(dynamic raw) {
    if (raw is! List) return const [];
    final out = <String>[];
    final seen = <String>{};
    for (final item in raw) {
      final key = _normalizeCategory('$item');
      if (key == null || seen.contains(key)) continue;
      seen.add(key);
      out.add(key);
    }
    // Stable order matching the category grid.
    return [
      for (final cat in _categories)
        if (out.contains(cat.key)) cat.key,
    ];
  }

  static String _interestsLabel(List<String> categories) {
    if (categories.isEmpty) return 'lifestyle_streak_shared_checin'.tr();
    return [
      for (final key in categories)
        for (final cat in _categories)
          if (cat.key == key) '${cat.emoji} ${cat.labelKey.tr()}',
    ].join(' · ');
  }

  List<_StreakUser> get _visibleUsers {
    final selected = _selectedCategory;
    if (selected == null) return _users;
    return [
      for (final user in _users)
        if (user.categories.contains(selected)) user,
    ];
  }

  void _applyRows(List<Map<String, dynamic>> rows, {required bool loading}) {
    final me = getIt<UserRepository>().currentUserListenable.value;
    final peers = <_StreakUser>[
      for (final row in rows)
        _StreakUser(
          name: (row['name'] as String?)?.trim().isNotEmpty == true
              ? (row['name'] as String).trim()
              : ((row['username'] as String?)?.trim() ?? 'user'),
          username: (row['username'] as String?)?.trim() ?? '',
          avatarPath: (row['avatarUrl'] as String?)?.trim() ?? '',
          categories: _parseCategories(row['categories']),
          streak: (row['streakCount'] as num?)?.toInt() ?? 0,
        ),
    ];
    final myCategories = <String>[
      for (final cat in _categories)
        if (peers.any((p) => p.categories.contains(cat.key))) cat.key,
    ];
    final total = peers.fold<int>(0, (sum, u) => sum + u.streak);
    _totalPoints = total;
    _users = [
      _StreakUser(
        nameKey: 'lifestyle_streak_you',
        avatarPath: me?.avatarPath ?? '',
        categories: myCategories,
        streak: total,
        isYou: true,
      ),
      ...peers,
    ];
    _loading = loading;
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() => _loading = true);
    }
    try {
      final rows = await getIt<UserRepository>().fetchFriendshipStreaks();
      if (!mounted) return;
      setState(() => _applyRows(rows, loading: false));
    } catch (_) {
      if (!mounted) return;
      if (_users.isEmpty) {
        setState(() {
          _users = const [];
          _totalPoints = 0;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    }
  }

  void _onCategoryTap(String key) {
    setState(() {
      _selectedCategory = _selectedCategory == key ? null : key;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleUsers;
    final hasPeers = _users.any((u) => !u.isYou);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => context.pop(),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppIcon(AssetPaths.iconBack, size: 24),
                        const SizedBox(width: 4),
                        Text(
                          'common_back'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            height: 1,
                            color: AppColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          AssetPaths.iconFlame3,
                          width: 96,
                          height: 96,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'lifestyle_streak_title'.tr(),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w600,
                                  height: 1,
                                  letterSpacing: -0.64,
                                  color: AppColors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'lifestyle_streak_subtitle'.tr(),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  height: 1,
                                  letterSpacing: -0.4,
                                  color: AppColors.black.withValues(
                                    alpha: 0.65,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: _loading
                                    ? const _PointsBadgeShimmer()
                                    : Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _streakPink.withValues(
                                            alpha: 0.10,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const AppIcon(
                                              AssetPaths.iconStreak,
                                              size: 28,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'lifestyle_streak_total_points'
                                                  .tr(
                                                    namedArgs: {
                                                      'count': '$_totalPoints',
                                                    },
                                                  ),
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
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'lifestyle_streak_category'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1,
                        letterSpacing: -0.32,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const spacing = 10.0;
                        final itemWidth =
                            (constraints.maxWidth - spacing * 2) / 3;
                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: [
                            for (final category in _categories)
                              SizedBox(
                                width: itemWidth,
                                height: 100,
                                child: _CategoryCard(
                                  emoji: category.emoji,
                                  label: category.labelKey.tr(),
                                  selected: _selectedCategory == category.key,
                                  onTap: () => _onCategoryTap(category.key),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'lifestyle_streak_users'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1,
                        letterSpacing: -0.32,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_loading)
                      const _StreakUsersShimmer()
                    else if (!hasPeers || visible.isEmpty)
                      const _StreakEmptyState()
                    else
                      for (final user in visible)
                        _StreakUserRow(
                          user: user,
                          onTap: () {
                            if (user.isYou) {
                              context.go(RoutePaths.profile.path);
                              return;
                            }
                            final key = user.username.trim().isNotEmpty
                                ? user.username.trim()
                                : (user.name ?? '');
                            openUserProfile(context, key);
                          },
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@immutable
final class _StreakEmptyState extends StatelessWidget {
  const _StreakEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppIcon(AssetPaths.iconStreak, size: 48),
            const SizedBox(height: 14),
            Text(
              'lifestyle_streak_empty'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.35,
                letterSpacing: -0.28,
                color: AppColors.black.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@immutable
final class _StreakCategory {
  const _StreakCategory({
    required this.key,
    required this.emoji,
    required this.labelKey,
  });

  final String key;
  final String emoji;
  final String labelKey;
}

@immutable
final class _PointsBadgeShimmer extends StatelessWidget {
  const _PointsBadgeShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8E8E8),
      highlightColor: const Color(0xFFF5F5F5),
      child: Container(
        width: 160,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

@immutable
final class _StreakUsersShimmer extends StatelessWidget {
  const _StreakUsersShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8E8E8),
      highlightColor: const Color(0xFFF5F5F5),
      child: const Column(
        children: [
          _StreakUserRowShimmer(),
          _StreakUserRowShimmer(),
          _StreakUserRowShimmer(),
        ],
      ),
    );
  }
}

@immutable
final class _StreakUserRowShimmer extends StatelessWidget {
  const _StreakUserRowShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E2E2), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 96,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 140,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 48,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

@immutable
final class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _streakPink.withValues(alpha: 0.10) : _categoryFill,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? _streakPink : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32, height: 1)),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1,
                  letterSpacing: -0.32,
                  color: selected ? _streakPink : AppColors.deepRoast,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@immutable
final class _StreakUser {
  const _StreakUser({
    required this.avatarPath,
    required this.categories,
    required this.streak,
    this.name,
    this.nameKey,
    this.username = '',
    this.isYou = false,
  });

  final String? name;
  final String? nameKey;
  final String username;
  final String avatarPath;
  final List<String> categories;
  final int streak;
  final bool isYou;

  String get displayName => nameKey?.tr() ?? name ?? '';

  String get interestsLabel =>
      _LifestyleStreakViewState._interestsLabel(categories);
}

@immutable
final class _StreakUserRow extends StatelessWidget {
  const _StreakUserRow({required this.user, required this.onTap});

  final _StreakUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: user.isYou
              ? _streakPink.withValues(alpha: 0.05)
              : AppColors.white,
          border: const Border(
            bottom: BorderSide(color: Color(0xFFE2E2E2), width: 0.5),
          ),
        ),
        child: Row(
          children: [
            ProfileAvatar(
              path: user.avatarPath,
              size: 50,
              showGradientRing: true,
              ringWidth: 3,
              ringGap: 0,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1,
                      letterSpacing: -0.32,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user.interestsLabel,
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
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 4, 8, 4),
              decoration: BoxDecoration(
                color: _streakPink.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${user.streak}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1,
                      color: _streakPink,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const AppIcon(AssetPaths.iconStreak, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
