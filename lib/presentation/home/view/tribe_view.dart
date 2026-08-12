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

  static const _featuredTribes = [
    _FeaturedTribeItem(
      titleKey: 'tribe_featured_title',
      descriptionKey: 'tribe_featured_description',
      membersKey: 'tribe_featured_members',
      memberCount: 8,
      avatarPath: AssetPaths.avatarJulia,
      avatars: [
        AssetPaths.avatarJessica,
        AssetPaths.avatarSona,
        AssetPaths.avatarLyra,
      ],
      background: Color(0xFFF3EDFF),
    ),
    _FeaturedTribeItem(
      titleKey: 'tribe_featured_title_2',
      descriptionKey: 'tribe_featured_description_2',
      membersKey: 'tribe_featured_members_2',
      memberCount: 11,
      avatarPath: AssetPaths.avatarNova,
      avatars: [
        AssetPaths.avatarNova,
        AssetPaths.avatarJessica,
        AssetPaths.avatarJulia,
      ],
      background: Color(0xFFFFF1E8),
    ),
    _FeaturedTribeItem(
      titleKey: 'tribe_featured_title_3',
      descriptionKey: 'tribe_featured_description_3',
      membersKey: 'tribe_featured_members_3',
      memberCount: 9,
      avatarPath: AssetPaths.checkinPlace,
      avatars: [
        AssetPaths.avatarLyra,
        AssetPaths.avatarSona,
        AssetPaths.avatarNova,
      ],
      background: Color(0xFFEAF7F2),
    ),
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
          physics: const ClampingScrollPhysics(),
          clipBehavior: Clip.none,
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 24),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                ],
              ),
            ),
            const SizedBox(height: 20),
            _FeaturedTribeCarousel(
              items: _featuredTribes,
              onJoin: (item) => _openGroupChat(
                context,
                name: item.titleKey.tr(),
                avatarPath: item.avatarPath,
                memberCount: item.memberCount,
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
          ],
        ),
      ),
    );
  }
}

class _FeaturedTribeItem {
  const _FeaturedTribeItem({
    required this.titleKey,
    required this.descriptionKey,
    required this.membersKey,
    required this.memberCount,
    required this.avatarPath,
    required this.avatars,
    required this.background,
  });

  final String titleKey;
  final String descriptionKey;
  final String membersKey;
  final int memberCount;
  final String avatarPath;
  final List<String> avatars;
  final Color background;
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

class _FeaturedTribeCarousel extends StatefulWidget {
  const _FeaturedTribeCarousel({required this.items, required this.onJoin});

  final List<_FeaturedTribeItem> items;
  final ValueChanged<_FeaturedTribeItem> onJoin;

  @override
  State<_FeaturedTribeCarousel> createState() => _FeaturedTribeCarouselState();
}

class _FeaturedTribeCarouselState extends State<_FeaturedTribeCarousel> {
  late final PageController _controller = PageController(
    viewportFraction: 0.86,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 256,
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.items.length,
        padEnds: true,
        clipBehavior: Clip.none,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final page = _controller.hasClients
                  ? (_controller.page ?? _controller.initialPage.toDouble())
                  : 0.0;
              final delta = (page - index).abs().clamp(0.0, 1.0);
              final scale = 1 - (delta * 0.08);
              return Transform.scale(
                scale: scale,
                alignment: Alignment.center,
                child: child,
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _FeaturedTribeCard(
                item: widget.items[index],
                onJoin: () => widget.onJoin(widget.items[index]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FeaturedTribeCard extends StatelessWidget {
  const _FeaturedTribeCard({required this.item, required this.onJoin});

  final _FeaturedTribeItem item;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: item.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            item.titleKey.tr(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
            item.descriptionKey.tr(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
              _AvatarPile(avatars: item.avatars),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  item.membersKey.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
            onTap: onJoin,
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
