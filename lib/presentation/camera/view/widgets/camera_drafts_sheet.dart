import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/core/widgets/app_loading.dart';
import 'package:zovi/core/widgets/stamp_image.dart';
import 'package:zovi/domain/auth/auth_repository.dart';
import 'package:zovi/presentation/camera/utils/camera_drafts.dart';

@immutable
final class CameraDraftPick {
  const CameraDraftPick({
    required this.imagePath,
    this.draftId,
  });

  final String imagePath;
  final String? draftId;
}

Future<CameraDraftPick?> showCameraDraftsSheet(BuildContext context) {
  return showModalBottomSheet<CameraDraftPick>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black26,
    builder: (context) => const CameraDraftsSheet(),
  );
}

@immutable
final class CameraDraftsSheet extends StatefulWidget {
  const CameraDraftsSheet({super.key});

  @override
  State<CameraDraftsSheet> createState() => _CameraDraftsSheetState();
}

final class _CameraDraftsSheetState extends State<CameraDraftsSheet> {
  var _loading = true;
  var _opening = false;
  var _loadFailed = false;
  List<StoryDraftItem> _drafts = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = getIt<AuthRepository>();
    final peeked = auth.peekStoryDrafts();
    final needsRefresh = auth.storyDraftsNeedRefresh;

    if (peeked != null && mounted) {
      setState(() {
        _drafts = peeked;
        _loading = needsRefresh;
        _loadFailed = false;
      });
      if (!needsRefresh) return;
    } else if (mounted) {
      setState(() {
        _loading = true;
        _loadFailed = false;
      });
    }

    try {
      final drafts = await auth.fetchStoryDrafts(
        forceRefresh: needsRefresh,
      );
      if (!mounted) return;
      setState(() {
        _drafts = drafts;
        _loading = false;
        _loadFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        // Keep peeked list if we already had cache.
        _loadFailed = peeked == null;
      });
    }
  }

  Future<void> _openDraft(StoryDraftItem draft) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final file = await CameraDrafts.materializeRemoteDraft(draft);
      if (!mounted) return;
      Navigator.of(context).pop(
        CameraDraftPick(imagePath: file.path, draftId: draft.id),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.52,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: const Color(0xE6000000),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Column(
                      children: [
                        Container(
                          width: 55,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.progressInactive,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'camera_drafts_title'.tr(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                            letterSpacing: -0.36,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _loading || _opening
                        ? const AppLoading(
                            color: AppColors.white,
                            strokeWidth: 2,
                          )
                        : _loadFailed
                        ? CustomScrollView(
                            controller: scrollController,
                            physics: const ClampingScrollPhysics(),
                            slivers: [
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: _DraftsEmptyState(
                                  messageKey: 'camera_drafts_load_failed',
                                  onRetry: _load,
                                ),
                              ),
                            ],
                          )
                        : _drafts.isEmpty
                        ? CustomScrollView(
                            controller: scrollController,
                            physics: const ClampingScrollPhysics(),
                            slivers: const [
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: _DraftsEmptyState(
                                  messageKey: 'camera_drafts_empty',
                                ),
                              ),
                            ],
                          )
                        : GridView.builder(
                            controller: scrollController,
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  childAspectRatio: 1,
                                ),
                            itemCount: _drafts.length,
                            itemBuilder: (context, index) {
                              final draft = _drafts[index];
                              return GestureDetector(
                                onTap: () => _openDraft(draft),
                                behavior: HitTestBehavior.opaque,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: StampImage(
                                    path: draft.mediaUrl,
                                    stampId: draft.id,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => ColoredBox(
                                      color: AppColors.white.withValues(
                                        alpha: 0.12,
                                      ),
                                      child: const Center(
                                        child: AppIcon(
                                          AssetPaths.iconPhotoGallery,
                                          size: 28,
                                          color: AppColors.white,
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
          ),
        );
      },
    );
  }
}

@immutable
final class _DraftsEmptyState extends StatelessWidget {
  const _DraftsEmptyState({
    required this.messageKey,
    this.onRetry,
  });

  final String messageKey;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              AssetPaths.iconPhotoGallery,
              size: 40,
              color: AppColors.white.withValues(alpha: 0.55),
            ),
            const SizedBox(height: 12),
            Text(
              messageKey.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.2,
                letterSpacing: -0.32,
                color: AppColors.white.withValues(alpha: 0.65),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onRetry,
                child: Text(
                  'retry'.tr(),
                  style: const TextStyle(color: AppColors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
