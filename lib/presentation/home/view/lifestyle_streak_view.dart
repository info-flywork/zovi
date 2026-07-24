import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/utils/navigation/open_user_profile.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/core/widgets/profile_avatar.dart';

const _streakPink = Color(0xFFFF4D6D);
const _categoryFill = Color(0xFFF4F4F9);

class LifestyleStreakView extends StatelessWidget {
  const LifestyleStreakView({super.key});

  static const _categories = [
    (emoji: '🎨', labelKey: 'lifestyle_category_culture'),
    (emoji: '🍕', labelKey: 'lifestyle_category_food'),
    (emoji: '☕', labelKey: 'lifestyle_category_coffee'),
    (emoji: '🏋️', labelKey: 'lifestyle_category_gym'),
    (emoji: '🎵', labelKey: 'lifestyle_category_music'),
    (emoji: '🌿', labelKey: 'lifestyle_category_park'),
  ];

  static const _users = [
    _StreakUser(
      nameKey: 'lifestyle_streak_you',
      avatarPath: AssetPaths.avatarYou,
      interests: '☕ Coffee · 🎵 Music · 🏋️ Gym',
      streak: 12,
      isYou: true,
    ),
    _StreakUser(
      name: 'Lyra',
      avatarPath: AssetPaths.avatarLyra,
      interests: '☕ Coffee · 🎵 Music · 🏋️ Gym',
      streak: 7,
    ),
    _StreakUser(
      name: 'Jessica',
      avatarPath: AssetPaths.avatarJessica,
      interests: '☕ Coffee · 🎵 Music · 🏋️ Gym',
      streak: 5,
    ),
    _StreakUser(
      name: 'Sona',
      avatarPath: AssetPaths.avatarSona,
      interests: '🍕 Food · 🎨 Culture · 🌿 Park',
      streak: 5,
    ),
    _StreakUser(
      name: 'Nova',
      avatarPath: AssetPaths.avatarNova,
      interests: '🎵 Music · 🏋️ Gym · ☕ Coffee',
      streak: 3,
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
              child: ListView(
                physics: const ClampingScrollPhysics(),
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
                                color: AppColors.black.withValues(alpha: 0.65),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _streakPink.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const AppIcon(
                                      AssetPaths.iconStreak,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'lifestyle_streak_total_points'.tr(
                                        namedArgs: {'count': '12'},
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
                  for (final user in _users)
                    _StreakUserRow(
                      user: user,
                      onTap: () {
                        if (user.isYou) {
                          context.go(RoutePaths.profile.path);
                          return;
                        }
                        openUserProfile(context, user.name ?? '');
                      },
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

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.emoji, required this.label});

  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _categoryFill,
        borderRadius: BorderRadius.circular(12),
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1,
              letterSpacing: -0.32,
              color: AppColors.deepRoast,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakUser {
  const _StreakUser({
    required this.avatarPath,
    required this.interests,
    required this.streak,
    this.name,
    this.nameKey,
    this.isYou = false,
  });

  final String? name;
  final String? nameKey;
  final String avatarPath;
  final String interests;
  final int streak;
  final bool isYou;

  String get displayName => nameKey?.tr() ?? name ?? '';
}

class _StreakUserRow extends StatelessWidget {
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
              ringWidth: 2,
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
                    user.interests,
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
