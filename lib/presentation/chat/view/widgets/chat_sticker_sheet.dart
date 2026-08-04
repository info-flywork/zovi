import 'dart:async';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/core/widgets/app_loading.dart';
import 'package:zovi/core/widgets/app_search_field.dart';
import 'package:zovi/core/widgets/stamp_image.dart';
import 'package:zovi/domain/auth/auth_repository.dart';
import 'package:zovi/domain/user/user_repository.dart';

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
  final _authRepository = getIt<AuthRepository>();

  var _query = '';
  var _loading = true;
  var _loadFailed = false;
  List<StampItem> _stamps = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadStamps();
    });
  }

  List<StampItem> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _stamps;
    return _stamps
        .where((s) => s.title.toLowerCase().contains(q))
        .toList(growable: false);
  }

  Future<void> _loadStamps() async {
    final locale = context.locale.languageCode;
    final peeked = _authRepository.peekChatPickerStamps(locale: locale);
    if (peeked.isNotEmpty) {
      setState(() {
        _stamps = peeked.map(StampItem.fromCatalog).toList(growable: false);
        _loading = false;
        _loadFailed = false;
      });
      // Refresh quietly in the background.
      unawaited(_refreshInBackground(locale));
      return;
    }

    setState(() {
      _loading = true;
      _loadFailed = false;
    });

    try {
      final items = await _authRepository.fetchChatPickerStamps(locale: locale);
      if (!mounted) return;
      setState(() {
        _stamps = items.map(StampItem.fromCatalog).toList(growable: false);
        _loading = false;
        _loadFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _refreshInBackground(String locale) async {
    try {
      final items = await _authRepository.fetchChatPickerStamps(
        locale: locale,
        forceRefresh: true,
      );
      if (!mounted) return;
      setState(() {
        _stamps = items.map(StampItem.fromCatalog).toList(growable: false);
      });
    } catch (_) {
      // Keep peeked list.
    }
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
                    Expanded(child: _buildBody(scrollController, stamps)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(ScrollController scrollController, List<StampItem> stamps) {
    if (_loading) {
      return const Center(
        child: SizedBox(width: 28, height: 28, child: AppLoading()),
      );
    }

    if (_loadFailed && _stamps.isEmpty) {
      return CustomScrollView(
        controller: scrollController,
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: _StampEmptyState(
              messageKey: 'chat_stamp_load_failed',
              onRetry: _loadStamps,
            ),
          ),
        ],
      );
    }

    if (_stamps.isEmpty) {
      return CustomScrollView(
        controller: scrollController,
        physics: const ClampingScrollPhysics(),
        slivers: const [
          SliverFillRemaining(
            hasScrollBody: false,
            child: _StampEmptyState(messageKey: 'chat_stamp_empty_owned'),
          ),
        ],
      );
    }

    if (stamps.isEmpty) {
      return CustomScrollView(
        controller: scrollController,
        physics: const ClampingScrollPhysics(),
        slivers: const [
          SliverFillRemaining(
            hasScrollBody: false,
            child: _StampEmptyState(messageKey: 'chat_stamp_empty_search'),
          ),
        ],
      );
    }

    return GridView.builder(
      controller: scrollController,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: stamps.length,
      itemBuilder: (context, index) {
        final stamp = stamps[index];
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(stamp),
          behavior: HitTestBehavior.opaque,
          child: StampImage(
            path: stamp.imagePath,
            stampId: stamp.id,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

class _StampEmptyState extends StatelessWidget {
  const _StampEmptyState({required this.messageKey, this.onRetry});

  final String messageKey;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
              messageKey.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1,
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
