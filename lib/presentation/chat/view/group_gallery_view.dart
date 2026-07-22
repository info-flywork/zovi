import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/presentation/chat/model/group_info_route_args.dart';
import 'package:zovi/presentation/chat/view/widgets/chat_media_viewer.dart';

class GroupGalleryView extends StatelessWidget {
  const GroupGalleryView({required this.args, super.key});

  final GroupInfoRouteArgs args;

  static const _media = [
    AssetPaths.checkinPlace,
    AssetPaths.mapFirst,
    AssetPaths.mapSecond,
    AssetPaths.storyJulia,
    AssetPaths.pulse1,
    AssetPaths.pulse2,
    AssetPaths.pulse3,
    AssetPaths.pulseJhon,
    AssetPaths.pulseJessica,
    AssetPaths.blueLocation,
    AssetPaths.avatarLyra,
    AssetPaths.avatarJessica,
  ];

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
                          args.name,
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
              child: _media.isEmpty
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
                        final path = _media[index];
                        final heroTag = 'group-gallery-$index';
                        return GestureDetector(
                          onTap: () {
                            showChatMediaViewer(
                              context,
                              heroTag: heroTag,
                              assetPath: path,
                            );
                          },
                          child: Hero(
                            tag: heroTag,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                path,
                                fit: BoxFit.cover,
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
