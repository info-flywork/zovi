import 'dart:async';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:zovi/core/billing/open_coin_paywall.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/snackbar/app_snackbar.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/utils/extensions/future_extensions.dart';
import 'package:zovi/core/widgets/app_button.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/domain/tribe/tribe_repository.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/chat/model/chat_detail_route_args.dart';
import 'package:zovi/presentation/profile/stickers/view/widgets/create_sticker_confirm_sheet.dart';

@immutable
final class TribeView extends StatefulWidget {
  const TribeView({super.key});

  @override
  State<TribeView> createState() => _TribeViewState();
}

final class _TribeViewState extends State<TribeView> {
  final TribeRepository _repository = getIt<TribeRepository>();
  final UserRepository _userRepository = getIt<UserRepository>();

  static const _fallbackAvatar = AssetPaths.iconTribeNonamePhoto;
  static const _createGroupCoinCost = 100;
  static const _pageSize = 15;

  TribeBoard _board = const TribeBoard.empty();
  bool _loading = true;
  bool _loadingMore = false;
  bool _joining = false;
  bool _creatingGroup = false;

  @override
  void initState() {
    super.initState();
    final cached = _repository.peekTribes();
    if (cached != null) {
      _board = cached;
      _loading = false;
      unawaited(_reload(silent: true));
    } else {
      unawaited(_reload());
    }
  }

  Future<void> _reload({bool silent = false}) async {
    if (!silent) {
      setState(() => _loading = _board.isEmpty);
    }
    try {
      final board = await _repository.fetchTribes(
        forceRefresh: true,
        limit: _pageSize,
        offset: 0,
      );
      if (!mounted) return;
      setState(() {
        _board = board;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_board.hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final next = await _repository.fetchTribes(
        forceRefresh: true,
        limit: _pageSize,
        offset: _board.nextOffset,
      );
      if (!mounted) return;
      setState(() {
        _board = next;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.pixels >=
        notification.metrics.maxScrollExtent - 280) {
      unawaited(_loadMore());
    }
    return false;
  }

  Future<void> _joinAndOpen(Tribe tribe) async {
    if (_joining) return;
    final confirmed = await showJoinTribeSheet(
      context,
      tribeName: tribe.localizedName,
    );
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

  Future<void> _onCreateGroupTap() async {
    final coinBalance = _userRepository.currentUserListenable.value?.coins ?? 0;
    final action = await showCreateStickerConfirmSheet(
      context,
      coinBalance: coinBalance,
      coinCost: _createGroupCoinCost,
      titleText: 'tribe_create_sheet_title'.tr(),
      subtitleText: 'tribe_create_sheet_subtitle'.tr(
        namedArgs: {'count': '$_createGroupCoinCost'},
      ),
      costLabelText: 'tribe_create_sheet_cost_label'.tr(),
      balanceLabelText: 'tribe_create_sheet_balance_label'.tr(),
      confirmLabelText: 'tribe_create_sheet_confirm'.tr(
        namedArgs: {'count': '$_createGroupCoinCost'},
      ),
      buyCoinsLabelText: 'sticker_create_sheet_buy_coins'.tr(),
    );
    if (!mounted || action == null) return;
    if (action == CreateStickerConfirmAction.buyCoins) {
      await openZoviCoinPaywall(context);
      return;
    }

    final groupName = await showCreateGroupNameSheet(context);
    if (!mounted || groupName == null || groupName.trim().isEmpty) return;

    if (_creatingGroup) return;
    setState(() => _creatingGroup = true);
    try {
      final result = await _repository
          .createTribe(name: groupName.trim())
          .withLoading(context);
      if (!mounted) return;

      final coinsBalance = result?.coinsBalance;
      if (coinsBalance != null) {
        final current = _userRepository.currentUserListenable.value;
        if (current != null && current.coins != coinsBalance) {
          _userRepository.currentUserListenable.value = current.copyWith(
            coins: coinsBalance,
          );
        }
      }

      final tribe = result?.tribe;
      if (tribe == null) {
        AppSnackbar.instance.show(
          context,
          'tribe_create_group_failed'.tr(),
          isError: true,
        );
        return;
      }

      _openGroupChat(tribe);
      unawaited(_reload());
    } on DioException catch (e) {
      if (!mounted) return;
      final body = e.response?.data;
      var code = '';
      if (body is Map) {
        final error = body['error'];
        if (error is Map) {
          code = '${error['code'] ?? ''}';
        }
      }
      if (code == 'INSUFFICIENT_COINS') {
        AppSnackbar.instance.show(
          context,
          'tribe_error_insufficient_coins'.tr(),
          isError: true,
        );
        return;
      }
      AppSnackbar.instance.show(
        context,
        'tribe_create_group_failed'.tr(),
        isError: true,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.instance.show(
        context,
        'tribe_create_group_failed'.tr(),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _creatingGroup = false);
    }
  }

  void _openGroupChat(Tribe tribe) {
    final cached = _repository.peekTribeDetail(tribe.id);
    final conversationId = tribe.conversationId.isNotEmpty
        ? tribe.conversationId
        : (cached?.conversationId ?? '');
    final avatar = tribe.displayAvatarPath.isNotEmpty
        ? tribe.displayAvatarPath
        : (cached?.displayAvatarPath ?? _fallbackAvatar);
    final memberCount = cached != null && cached.memberCount > 0
        ? cached.memberCount
        : tribe.memberCount;
    context.push(
      RoutePaths.chatDetail.path,
      extra: ChatDetailRouteArgs(
        name: tribe.localizedName,
        username: tribe.localizedName,
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
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: RefreshIndicator(
            onRefresh: () => _reload(),
            child: _loading && _board.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: ClampingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 24),
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: _TribeHeader(onCreateTap: _onCreateGroupTap),
                      ),
                      const SizedBox(height: 20),
                      const _TribePageShimmer(),
                    ],
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: ClampingScrollPhysics(),
                    ),
                    clipBehavior: Clip.none,
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 24),
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: _TribeHeader(onCreateTap: _onCreateGroupTap),
                      ),
                      const SizedBox(height: 20),
                      if (_board.featured.isNotEmpty) ...[
                        _FeaturedTribeCarousel(
                          items: _board.featured,
                          onJoin: _joinAndOpen,
                        ),
                        const SizedBox(height: 28),
                      ],
                      if (_board.tribes.isNotEmpty)
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
                              for (
                                var i = 0;
                                i < _board.tribes.length;
                                i++
                              ) ...[
                                if (i > 0) const SizedBox(height: 10),
                                _TribeListTile(
                                  tribe: _board.tribes[i],
                                  onTap: _board.tribes[i].isMember
                                      ? () => _openGroupChat(_board.tribes[i])
                                      : _board.tribes[i].isUnlocked
                                      ? () => _joinAndOpen(_board.tribes[i])
                                      : null,
                                ),
                              ],
                              if (_loadingMore) ...[
                                const SizedBox(height: 16),
                                const Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ],
                            ],
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

Future<String?> showCreateGroupNameSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const _CreateGroupNameSheet(),
  );
}

@immutable
final class _CreateGroupNameSheet extends StatefulWidget {
  const _CreateGroupNameSheet();

  @override
  State<_CreateGroupNameSheet> createState() => _CreateGroupNameSheetState();
}

final class _CreateGroupNameSheetState extends State<_CreateGroupNameSheet> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_nameController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      behavior: HitTestBehavior.opaque,
                      child: const AppIcon(
                        AssetPaths.iconCloseCircle,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'tribe_create_name_sheet_title'.tr(),
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
                'tribe_create_name_sheet_subtitle'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  height: 24 / 20,
                  letterSpacing: -0.4,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'tribe_create_name_sheet_field_label'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 20 / 16,
                    letterSpacing: -0.32,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(99999),
                  border: Border.all(
                    color: AppColors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Center(
                  child: TextField(
                    controller: _nameController,
                    maxLength: 40,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                      hintText: 'tribe_create_name_sheet_placeholder'.tr(),
                      hintStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 20 / 16,
                        letterSpacing: -0.32,
                        color: AppColors.black.withValues(alpha: 0.30),
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 20 / 16,
                      letterSpacing: -0.32,
                      color: AppColors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'tribe_create_name_sheet_confirm'.tr(),
                onPressed: _submit,
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
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
      ),
    );
  }
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
              'tribe_join_sheet_subtitle'.tr(namedArgs: {'tribe': tribeName}),
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
  const _TribeHeader({required this.onCreateTap});

  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
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
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onCreateTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            child: const AppIcon(
              AssetPaths.iconAdd2,
              size: 24,
              color: AppColors.black,
            ),
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
  double _pixels = 0;

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.sizeOf(context).width - 16 - 28;
    const gap = 10.0;
    final itemExtent = cardWidth + gap;
    return SizedBox(
      height: 250,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis != Axis.horizontal) return false;
          final pixels = notification.metrics.pixels;
          if ((pixels - _pixels).abs() < 0.5) return false;
          setState(() => _pixels = pixels);
          return false;
        },
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          physics: _SnapScrollPhysics(
            itemExtent: itemExtent,
            parent: const ClampingScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: widget.items.length,
          separatorBuilder: (_, _) => const SizedBox(width: gap),
          itemBuilder: (context, index) {
            final delta = ((_pixels / itemExtent) - index).abs().clamp(
              0.0,
              1.0,
            );
            final scale = 1 - (delta * 0.14);
            final down = delta * 16;
            return SizedBox(
              width: cardWidth,
              child: Transform.translate(
                offset: Offset(0, down),
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.topCenter,
                  child: _FeaturedTribeCard(
                    item: widget.items[index],
                    onJoin: () => widget.onJoin(widget.items[index]),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

final class _SnapScrollPhysics extends ScrollPhysics {
  const _SnapScrollPhysics({required this.itemExtent, super.parent});

  final double itemExtent;

  @override
  _SnapScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _SnapScrollPhysics(
      itemExtent: itemExtent,
      parent: buildParent(ancestor),
    );
  }

  double _targetPixels(ScrollMetrics position, double velocity) {
    final page = position.pixels / itemExtent;
    final next = velocity.abs() < 80
        ? page.roundToDouble()
        : velocity < 0
        ? page.floorToDouble()
        : page.ceilToDouble();
    return (next * itemExtent).clamp(0.0, position.maxScrollExtent);
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final target = _targetPixels(position, velocity);
    if ((target - position.pixels).abs() < 0.5) {
      return super.createBallisticSimulation(position, velocity);
    }
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: toleranceFor(position),
    );
  }

  @override
  bool get allowImplicitScrolling => false;
}

@immutable
final class _FeaturedTribeCard extends StatelessWidget {
  const _FeaturedTribeCard({required this.item, required this.onJoin});

  final Tribe item;
  final VoidCallback onJoin;

  String _membersLabel() {
    if (item.memberCount <= 0) {
      return 'tribe_members_be_first'.tr();
    }
    final cadence = item.localizedCadence;
    final count = 'tribe_member_count'.tr(args: ['${item.memberCount}']);
    if (cadence.isEmpty) return count;
    return '$count · $cadence';
  }

  @override
  Widget build(BuildContext context) {
    final description = item.localizedDescription.trim();
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(AppColors.white, AppColors.zoviOrange, 0.18)!,
            Color.lerp(AppColors.white, AppColors.chatPurple, 0.22)!,
          ],
        ),
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
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: _avatarImage(item.displayAvatarPath),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.localizedName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                    letterSpacing: -0.48,
                    color: AppColors.black,
                  ),
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              description,
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
          ],
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
      errorBuilder: (_, _, _) => _defaultTribeAvatar(),
    );
  }
  if (path.toLowerCase().endsWith('.svg')) {
    return _defaultTribeAvatar(path: path);
  }
  return Image.asset(
    path,
    fit: BoxFit.cover,
    errorBuilder: (_, _, _) => _defaultTribeAvatar(),
  );
}

Widget _defaultTribeAvatar({String path = AssetPaths.iconTribeNonamePhoto}) {
  return ColoredBox(
    color: const Color(0xFFF4F4F9),
    child: Center(child: AppIcon(path, size: 28)),
  );
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
            if (tribe.localizedCadence.isNotEmpty) tribe.localizedCadence,
          ].join(' · ');

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: tribe.isLocked ? 0.55 : 1,
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
                      tribe.localizedName,
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
    final avatarPath = tribe.displayAvatarPath;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(width: 50, height: 50, child: _avatarImage(avatarPath)),
    );
  }
}
