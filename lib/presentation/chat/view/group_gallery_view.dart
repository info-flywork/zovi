import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/bunny_image_url.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/domain/chat/chat_repository.dart';
import 'package:zovi/domain/tribe/tribe_repository.dart';
import 'package:zovi/presentation/chat/model/group_info_route_args.dart';
import 'package:zovi/presentation/chat/view/widgets/chat_media_viewer.dart';

@immutable
final class GroupGalleryView extends StatefulWidget {
  const GroupGalleryView({required this.args, super.key});

  final GroupInfoRouteArgs args;

  @override
  State<GroupGalleryView> createState() => _GroupGalleryViewState();
}

final class _GroupGalleryViewState extends State<GroupGalleryView> {
  final ChatRepository _chat = getIt<ChatRepository>();
  final TribeRepository _tribes = getIt<TribeRepository>();

  var _loading = true;
  List<ChatGalleryMedia> _media = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<String?> _resolveConversationId() async {
    final fromArgs = widget.args.conversationId.trim();
    if (fromArgs.isNotEmpty) return fromArgs;

    final tribeId = widget.args.tribeId.trim();
    if (tribeId.isEmpty) return null;

    final cached = _tribes.peekTribeDetail(tribeId);
    if (cached != null && cached.conversationId.trim().isNotEmpty) {
      return cached.conversationId.trim();
    }

    final detail = await _tribes.refreshTribeDetail(tribeId);
    final resolved = detail?.conversationId.trim() ?? '';
    return resolved.isEmpty ? null : resolved;
  }

  Future<void> _load() async {
    try {
      final conversationId = await _resolveConversationId();
      if (conversationId == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final media = await _chat.listConversationMedia(conversationId);
      if (!mounted) return;
      setState(() {
        _media = media;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    behavior: HitTestBehavior.opaque,
                    child: const AppIcon(
                      AssetPaths.iconArrowLeft,
                      size: 32,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'group_gallery_title'.tr(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1,
                            letterSpacing: -0.32,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.args.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1,
                            letterSpacing: -0.24,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'group_gallery_count'.tr(
                    namedArgs: {'count': '${_media.length}'},
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1,
                    letterSpacing: -0.28,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? _GalleryShimmer()
                  : _media.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppIcon(
                            AssetPaths.iconUserSquare,
                            size: 40,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'group_gallery_empty'.tr(),
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
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      physics: const ClampingScrollPhysics(),
                      itemCount: _media.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                      itemBuilder: (context, index) {
                        final item = _media[index];
                        final url = item.mediaUrl.trim();
                        final heroTag = 'group-gallery-${item.id}';
                        return GestureDetector(
                          onTap: () {
                            if (url.isEmpty) return;
                            showChatMediaViewer(
                              context,
                              heroTag: heroTag,
                              networkUrl: url,
                            );
                          },
                          child: Hero(
                            tag: heroTag,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: url.isEmpty
                                  ? ColoredBox(
                                      color: AppColors.textSecondary
                                          .withValues(alpha: 0.12),
                                      child: const Center(
                                        child: AppIcon(
                                          AssetPaths.iconUserSquare,
                                          size: 24,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: bunnySizedUrl(
                                        url,
                                        ((MediaQuery.sizeOf(context).width / 3) *
                                                MediaQuery.devicePixelRatioOf(context))
                                            .ceil()
                                            .clamp(160, 480),
                                      ),
                                      fit: BoxFit.cover,
                                      fadeInDuration: Duration.zero,
                                      errorWidget: (_, _, _) => ColoredBox(
                                        color: AppColors.textSecondary
                                            .withValues(alpha: 0.12),
                                        child: const Center(
                                          child: AppIcon(
                                            AssetPaths.iconUserSquare,
                                            size: 24,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

@immutable
final class _GalleryShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 9,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: const Color(0xFFE8E8F0),
          highlightColor: const Color(0xFFF5F5FA),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: const ColoredBox(color: Color(0xFFE8E8F0)),
          ),
        );
      },
    );
  }
}
