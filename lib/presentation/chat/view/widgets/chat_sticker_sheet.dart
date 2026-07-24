import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/core/widgets/app_search_field.dart';
import 'package:zovi/domain/user/user_repository.dart';

const _stamps = [
  StampItem(imagePath: AssetPaths.stamp1, title: 'After Hours'),
  StampItem(imagePath: AssetPaths.stamp2, title: 'VIP Pass'),
  StampItem(imagePath: AssetPaths.stamp3, title: 'DJ Booth'),
  StampItem(imagePath: AssetPaths.stamp4, title: 'Surf Mode'),
  StampItem(imagePath: AssetPaths.stamp5, title: 'Barista'),
  StampItem(imagePath: AssetPaths.stamp6, title: 'Brunch Club'),
  StampItem(imagePath: AssetPaths.stamp7, title: 'Globetrotter'),
  StampItem(imagePath: AssetPaths.stamp8, title: 'Need Coffee'),
  StampItem(imagePath: AssetPaths.stamp9, title: 'Power Duo'),
  StampItem(imagePath: AssetPaths.stamp10, title: 'On The Decks'),
  StampItem(imagePath: AssetPaths.stamp11, title: 'Soulmates'),
  StampItem(imagePath: AssetPaths.stamp12, title: 'Day & Night'),
  StampItem(imagePath: AssetPaths.stamp13, title: 'Music Fest'),
  StampItem(imagePath: AssetPaths.stamp14, title: 'Spark Pals'),
  StampItem(imagePath: AssetPaths.stamp15, title: 'Foodies'),
  StampItem(imagePath: AssetPaths.stamp16, title: 'Founder'),
  StampItem(imagePath: AssetPaths.stamp17, title: 'Peekaboo'),
];

Future<StampItem?> showChatStickerSheet(
  BuildContext context, {
  double initialChildSize = 0.62,
  double minChildSize = 0.4,
  double maxChildSize = 0.8,
}) {
  return showModalBottomSheet<StampItem>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black26,
    builder: (context) => ChatStickerSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
    ),
  );
}

class ChatStickerSheet extends StatefulWidget {
  const ChatStickerSheet({
    this.initialChildSize = 0.62,
    this.minChildSize = 0.4,
    this.maxChildSize = 0.8,
    super.key,
  });

  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;

  @override
  State<ChatStickerSheet> createState() => _ChatStickerSheetState();
}

class _ChatStickerSheetState extends State<ChatStickerSheet> {
  var _query = '';

  List<StampItem> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _stamps;
    return _stamps
        .where((s) => s.title.toLowerCase().contains(q))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final stamps = _filtered;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: widget.initialChildSize,
        minChildSize: widget.minChildSize,
        maxChildSize: widget.maxChildSize,
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
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                          const SizedBox(height: 10),
                          AppSearchField(
                            hintText: 'search'.tr(),
                            isDark: true,
                            onDebouncedChanged: (value) =>
                                setState(() => _query = value),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                    Expanded(
                      child: stamps.isEmpty
                          ? CustomScrollView(
                              controller: scrollController,
                              physics: const ClampingScrollPhysics(),
                              slivers: const [
                                SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: _StampEmptyState(),
                                ),
                              ],
                            )
                          : GridView.builder(
                              controller: scrollController,
                              physics: const ClampingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 1,
                              ),
                              itemCount: stamps.length,
                              itemBuilder: (context, index) {
                                final stamp = stamps[index];
                                return GestureDetector(
                                  onTap: () =>
                                      Navigator.of(context).pop(stamp),
                                  behavior: HitTestBehavior.opaque,
                                  child: Image.asset(
                                    stamp.imagePath,
                                    fit: BoxFit.contain,
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
      ),
    );
  }
}

class _StampEmptyState extends StatelessWidget {
  const _StampEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            AssetPaths.iconSearch,
            size: 40,
            color: AppColors.white.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 12),
          Text(
            'chat_stamp_empty_search'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1,
              letterSpacing: -0.32,
              color: AppColors.white.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}
