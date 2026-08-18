import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/utils/extensions/future_extensions.dart';
import 'package:zovi/core/widgets/app_button.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/domain/tribe/tribe_repository.dart';
import 'package:zovi/presentation/chat/model/chat_detail_route_args.dart';

@immutable
final class TribeView extends StatefulWidget {
  const TribeView({super.key});

  @override
  State<TribeView> createState() => _TribeViewState();
}

final class _TribeViewState extends State<TribeView> {
  final TribeRepository _repository = getIt<TribeRepository>();

  // Group-chat placeholder avatar when a tribe has no member photos yet.
  static const _fallbackAvatar = AssetPaths.avatarJessica;

  late Future<TribeBoard> _future;
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    final cached = _repository.peekTribes();
    if (cached != null) {
      _future = Future.value(cached);
      unawaited(_refreshSilently());
    } else {
      _future = _repository.fetchTribes();
    }
  }

  Future<void> _reload() async {
    final future = _repository.fetchTribes(forceRefresh: true);
    setState(() {
      _future = future;
    });
    await future;
  }

  Future<void> _refreshSilently() async {
    try {
      final fresh = await _repository.fetchTribes(forceRefresh: true);
      if (!mounted) return;
      setState(() {
        _future = Future.value(fresh);
      });
    } catch (_) {
      // Keep cached paint if refresh fails.
    }
  }

  Future<void> _joinAndOpen(Tribe tribe) async {
    if (_joining) return;
    final confirmed = await showJoinTribeSheet(context, tribeName: tribe.name);
    if (!confirmed || !mounted) return;
    setState(() => _joining = true);
    try {
      final joined = await _repository.joinTribe(tribe.id).withLoading(context);
      if (!mounted) return;
      _openGroupChat(joined ?? tribe);
      unawaited(_reload());
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  void _openGroupChat(Tribe tribe) {
    final cached = _repository.peekTribeDetail(tribe.id);
    final conversationId = tribe.conversationId.isNotEmpty
        ? tribe.conversationId
        : (cached?.conversationId ?? '');
    final avatar = tribe.avatars.isNotEmpty
        ? tribe.avatars.first
        : (cached != null && cached.avatars.isNotEmpty
              ? cached.avatars.first
              : _fallbackAvatar);
    final memberCount = cached != null && cached.memberCount > 0
        ? cached.memberCount
        : tribe.memberCount;
    context.push(
      RoutePaths.chatDetail.path,
      extra: ChatDetailRouteArgs(
        name: tribe.name,
        username: tribe.name,
        avatarPath: avatar,
        conversationId: conversationId,
        isGroup: true,
        memberCount: memberCount,
        tribeId: tribe.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reload,
          child: FutureBuilder<TribeBoard>(
            future: _future,
            builder: (context, snapshot) {
              final board = snapshot.data ?? const TribeBoard.empty();
              final loading =
                  snapshot.connectionState == ConnectionState.waiting;
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                clipBehavior: Clip.none,
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 24),
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _TribeHeader(),
                  ),
                  const SizedBox(height: 20),
                  if (loading && board.isEmpty)
                    const _TribePageShimmer()
                  else ...[
                    if (board.featured.isNotEmpty) ...[
                      _FeaturedTribeCarousel(
                        items: board.featured,
                        onJoin: _joinAndOpen,
                      ),
                      const SizedBox(height: 28),
                    ],
                    if (board.tribes.isNotEmpty)
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
                            for (var i = 0; i < board.tribes.length; i++) ...[
                              if (i > 0) const SizedBox(height: 10),
                              _TribeListTile(
                                tribe: board.tribes[i],
                                onTap: board.tribes[i].isMember
                                    ? () => _openGroupChat(board.tribes[i])
                                    : null,
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

Future<bool> showJoinTribeSheet(
  BuildContext context, {
  required String tribeName,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _JoinTribeSheet(tribeName: tribeName),
  );
  return result ?? false;
}

@immutable
final class _JoinTribeSheet extends StatelessWidget {
  const _JoinTribeSheet({required this.tribeName});

  final String tribeName;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              'tribe_join_sheet_title'.tr(),
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
              'tribe_join_sheet_subtitle'.tr(
                namedArgs: {'tribe': tribeName},
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 20 / 16,
                letterSpacing: -0.32,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'tribe_join_sheet_confirm'.tr(),
              backgroundColor: AppColors.zoviOrange,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(false),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'cancel'.tr(),
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

@immutable
final class _TribePageShimmer extends StatelessWidget {
  const _TribePageShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Shimmer.fromColors(
        baseColor: const Color(0xFFE9E9F2),
        highlightColor: const Color(0xFFF7F7FB),
        child: Column(
          children: [
            const _TribeShimmerBox(height: 245, radius: 16),
            const SizedBox(height: 28),
            const Align(
              alignment: Alignment.centerLeft,
              child: _TribeShimmerBox(width: 90, height: 20, radius: 8),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < 5; i++) ...[
              const _TribeShimmerBox(height: 72, radius: 12),
              if (i < 4) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

@immutable
final class _TribeShimmerBox extends StatelessWidget {
  const _TribeShimmerBox({
    this.width = double.infinity,
    required this.height,
    required this.radius,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

@immutable
final class _TribeHeader extends StatelessWidget {
  const _TribeHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}

@immutable
final class _FeaturedTribeCarousel extends StatefulWidget {
  const _FeaturedTribeCarousel({required this.items, required this.onJoin});

  final List<Tribe> items;
  final ValueChanged<Tribe> onJoin;

  @override
  State<_FeaturedTribeCarousel> createState() => _FeaturedTribeCarouselState();
}

final class _FeaturedTribeCarouselState extends State<_FeaturedTribeCarousel> {
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
      height: 245,
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
              final delta = (page - index).abs().clamp(0.0, 0.0);
              final scale = 1 - (delta * 0.02);
              return Transform.scale(
                scale: scale,
                alignment: Alignment.center,
                child: child,
              );
            },
            child: _FeaturedTribeCard(
              item: widget.items[index],
              onJoin: () => widget.onJoin(widget.items[index]),
            ),
          );
        },
      ),
    );
  }
}

@immutable
final class _FeaturedTribeCard extends StatelessWidget {
  const _FeaturedTribeCard({required this.item, required this.onJoin});

  final Tribe item;
  final VoidCallback onJoin;

  String _membersLabel() {
    final parts = <String>[];
    parts.add('tribe_member_count'.tr(args: ['${item.memberCount}']));
    if (item.areaLabel.isNotEmpty) parts.add(item.areaLabel);
    return parts.join(' · ');
  }

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
            item.name,
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
            item.description,
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
              if (item.avatars.isNotEmpty) ...[
                _AvatarPile(avatars: item.avatars),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  _membersLabel(),
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

Widget _avatarImage(String path) {
  final isNetwork = path.startsWith('http://') || path.startsWith('https://');
  if (isNetwork) {
    return Image.network(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) =>
          Image.asset(AssetPaths.avatarJessica, fit: BoxFit.cover),
    );
  }
  return Image.asset(path, fit: BoxFit.cover);
}

@immutable
final class _AvatarPile extends StatelessWidget {
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
                child: ClipOval(child: _avatarImage(shown[i])),
              ),
            ),
        ],
      ),
    );
  }
}

@immutable
final class _TribeListTile extends StatelessWidget {
  const _TribeListTile({required this.tribe, this.onTap});

  final Tribe tribe;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = tribe.isLocked
        ? 'tribe_unlock_hint'.tr(args: ['${tribe.remaining}'])
        : [
            'tribe_member_count'.tr(args: ['${tribe.memberCount}']),
            if (tribe.cadenceLabel.isNotEmpty) tribe.cadenceLabel,
          ].join(' · ');

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: tribe.isMember ? 1 : 0.55,
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
              _TribeListLeading(tribe: tribe),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tribe.name,
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
                      subtitle,
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
              if (tribe.isMember)
                const AppIcon(AssetPaths.iconRight, size: 20)
              else
                Text(
                  tribe.progressLabel,
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

@immutable
final class _TribeListLeading extends StatelessWidget {
  const _TribeListLeading({required this.tribe});

  final Tribe tribe;

  @override
  Widget build(BuildContext context) {
    if (tribe.avatars.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 50,
          height: 50,
          child: _avatarImage(tribe.avatars.first),
        ),
      );
    }
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F9),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(tribe.emoji, style: const TextStyle(fontSize: 24)),
    );
  }
}
