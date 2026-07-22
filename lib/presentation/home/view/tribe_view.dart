import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/presentation/chat/model/chat_detail_route_args.dart';

class TribeView extends StatelessWidget {
  const TribeView({super.key});

  static const _featuredAvatars = [
    AssetPaths.avatarJessica,
    AssetPaths.avatarSona,
    AssetPaths.avatarLyra,
  ];

  static const _tribes = [
    _TribeItem(
      emoji: '☕',
      titleKey: 'tribe_item_coffee_title',
      subtitleKey: 'tribe_item_coffee_subtitle',
      unlocked: true,
      memberCount: 12,
      avatarPath: AssetPaths.checkinPlace,
    ),
    _TribeItem(
      emoji: '🏃',
      titleKey: 'tribe_item_sport_title',
      subtitleKey: 'tribe_item_sport_subtitle',
      unlocked: true,
      memberCount: 7,
      avatarPath: AssetPaths.avatarNova,
    ),
    _TribeItem(
      emoji: '🍻',
      titleKey: 'tribe_item_nightlife_title',
      subtitleKey: 'tribe_item_nightlife_subtitle',
      unlocked: false,
      progress: '8/10',
      memberCount: 15,
      avatarPath: AssetPaths.avatarJessica,
    ),
    _TribeItem(
      emoji: '🏛️',
      titleKey: 'tribe_item_museum_title',
      subtitleKey: 'tribe_item_museum_subtitle',
      unlocked: false,
      progress: '4/10',
      memberCount: 9,
      avatarPath: AssetPaths.avatarLyra,
    ),
  ];

  void _openGroupChat(
    BuildContext context, {
    required String name,
    required String avatarPath,
    required int memberCount,
  }) {
    context.push(
      RoutePaths.chatDetail.path,
      extra: ChatDetailRouteArgs(
        name: name,
        username: name,
        avatarPath: avatarPath,
        isGroup: true,
        memberCount: memberCount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ListView(
          physics: ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            Text(
              'tribe_title'.tr(),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1,
                letterSpacing: -0.56,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'tribe_subtitle'.tr(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1,
                letterSpacing: -0.28,
                color: AppColors.black.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 20),
            const _FeaturedTribeCard(avatars: _featuredAvatars),
            const SizedBox(height: 28),
            Text(
              'tribe_list_title'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1,
                letterSpacing: -0.32,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < _tribes.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _TribeListTile(
                item: _tribes[i],
                onTap: _tribes[i].unlocked
                    ? () => _openGroupChat(
                        context,
                        name: _tribes[i].titleKey.tr(),
                        avatarPath: _tribes[i].avatarPath,
                        memberCount: _tribes[i].memberCount,
                      )
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TribeItem {
  const _TribeItem({
    required this.emoji,
    required this.titleKey,
    required this.subtitleKey,
    required this.unlocked,
    required this.memberCount,
    required this.avatarPath,
    this.progress,
  });

  final String emoji;
  final String titleKey;
  final String subtitleKey;
  final bool unlocked;
  final int memberCount;
  final String avatarPath;
  final String? progress;
}

class _FeaturedTribeCard extends StatelessWidget {
  const _FeaturedTribeCard({required this.avatars});

  final List<String> avatars;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EDFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.zoviOrange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'tribe_featured_badge'.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1,
                  letterSpacing: -0.28,
                  color: AppColors.zoviOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'tribe_featured_title'.tr(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1,
              letterSpacing: -0.48,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'tribe_featured_description'.tr(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.2,
              letterSpacing: -0.32,
              color: AppColors.black.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _AvatarPile(avatars: avatars),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'tribe_featured_members'.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1,
                    letterSpacing: -0.24,
                    color: AppColors.deepRoast.withValues(alpha: 0.65),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              context.push(
                RoutePaths.chatDetail.path,
                extra: ChatDetailRouteArgs(
                  name: 'tribe_featured_title'.tr(),
                  username: 'tribe_featured_title'.tr(),
                  avatarPath: AssetPaths.avatarJulia,
                  isGroup: true,
                  memberCount: 8,
                ),
              );
            },
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99999),
                  gradient: const LinearGradient(
                    colors: [AppColors.zoviOrange, AppColors.chatPurple],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AppIcon(AssetPaths.iconAi, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'tribe_join'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 20 / 16,
                        letterSpacing: 0,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarPile extends StatelessWidget {
  const _AvatarPile({required this.avatars});

  final List<String> avatars;

  @override
  Widget build(BuildContext context) {
    const size = 34.0;
    const overlap = 11.0;
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

class _TribeListTile extends StatelessWidget {
  const _TribeListTile({required this.item, this.onTap});

  final _TribeItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: item.unlocked ? 1 : 0.55,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E2E2)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(item.emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.titleKey.tr(),
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
                      item.subtitleKey.tr(),
                      style: const TextStyle(
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
              if (item.unlocked)
                const AppIcon(AssetPaths.iconRight, size: 20)
              else
                Text(
                  item.progress ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1,
                    letterSpacing: -0.28,
                    color: AppColors.deepRoast,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
