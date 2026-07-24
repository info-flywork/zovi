import 'dart:io';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/presentation/camera/utils/camera_drafts.dart';

Future<String?> showCameraDraftsSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black26,
    builder: (context) => const CameraDraftsSheet(),
  );
}

class CameraDraftsSheet extends StatefulWidget {
  const CameraDraftsSheet({super.key});

  @override
  State<CameraDraftsSheet> createState() => _CameraDraftsSheetState();
}

class _CameraDraftsSheetState extends State<CameraDraftsSheet> {
  var _loading = true;
  List<File> _drafts = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final drafts = await CameraDrafts.list();
    if (!mounted) return;
    setState(() {
      _drafts = drafts;
      _loading = false;
    });
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
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : _drafts.isEmpty
                        ? CustomScrollView(
                            controller: scrollController,
                            physics: const ClampingScrollPhysics(),
                            slivers: const [
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: _DraftsEmptyState(),
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
                              final file = _drafts[index];
                              return GestureDetector(
                                onTap: () =>
                                    Navigator.of(context).pop(file.path),
                                behavior: HitTestBehavior.opaque,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    file,
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

class _DraftsEmptyState extends StatelessWidget {
  const _DraftsEmptyState();

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
              'camera_drafts_empty'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.2,
                letterSpacing: -0.32,
                color: AppColors.white.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
