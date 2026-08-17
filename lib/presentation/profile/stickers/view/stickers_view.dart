import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/core/widgets/stamp_image.dart';
import 'package:zovi/domain/auth/auth_repository.dart';

class StickersView extends StatefulWidget {
  const StickersView({super.key});

  @override
  State<StickersView> createState() => _StickersViewState();
}

class _StickersViewState extends State<StickersView> {
  static const _previewCount = 10;
  static const _myCreationsId = 'my_creations';
  static const _zoviStampsId = 'zovi_stamps';

  final AuthRepository _authRepository = getIt<AuthRepository>();
  List<_StickerItem> _myCreations = [];
  List<_StickerItem> _zoviStamps = [];

  final _scrollController = ScrollController();
  final Map<String, int> _visibleCountBySection = {};
  final Set<String> _hiddenSections = {};
  final Set<_StampKey> _selected = {};
  String? _openMenuSectionId;
  var _isSelecting = false;
  String? _lastLoadedLocale;
  var _isLoadingMyCreations = false;
  var _isLoadingZoviStamps = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = context.locale.languageCode;
    if (_lastLoadedLocale == locale) return;
    _lastLoadedLocale = locale;
    _loadStickers(locale);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadStickers(String locale) async {
    final peekedCatalog = _authRepository.peekStampCatalog(locale: locale);

    if (mounted) {
      setState(() {
        _isLoadingMyCreations = _myCreations.isEmpty;
        if (peekedCatalog != null) {
          _zoviStamps = peekedCatalog
              .map(
                (item) => _StickerItem(
                  id: item.id,
                  path: item.imageUrl,
                  name: item.name,
                ),
              )
              .toList();
          _isLoadingZoviStamps = false;
        } else {
          _isLoadingZoviStamps = true;
        }
      });
    }

    try {
      final catalog = await _authRepository.fetchStampCatalog(locale: locale);
      final zoviStamps = catalog
          .map(
            (item) =>
                _StickerItem(id: item.id, path: item.imageUrl, name: item.name),
          )
          .toList();
      if (mounted) {
        setState(() {
          _zoviStamps = zoviStamps;
          _isLoadingZoviStamps = false;
        });
      }
    } catch (_) {
      if (kDebugMode) {
        debugPrint('StickersView: failed to fetch /stamps catalog');
      }
      if (mounted) {
        setState(() {
          _isLoadingZoviStamps = false;
        });
      }
    }

    // "My Creations" holds both what the user made and what they earned.
    try {
      final owned = await _authRepository.fetchOwnedPickerStamps(
        locale: locale,
        forceRefresh: true,
      );
      final myCreations = owned
          .map(
            (item) =>
                _StickerItem(id: item.id, path: item.imageUrl, name: item.name),
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _myCreations = myCreations;
        _isLoadingMyCreations = false;
      });
    } catch (_) {
      if (kDebugMode) {
        debugPrint('StickersView: failed to fetch owned stickers/stamps');
      }
      if (!mounted) return;
      setState(() {
        _isLoadingMyCreations = false;
      });
    }
  }

  List<_StickerItem> _stampsFor(String sectionId) {
    return switch (sectionId) {
      _myCreationsId => _myCreations,
      _zoviStampsId => _zoviStamps,
      _ => const [],
    };
  }

  void _setStampsFor(String sectionId, List<_StickerItem> stamps) {
    switch (sectionId) {
      case _myCreationsId:
        _myCreations = stamps;
      case _zoviStampsId:
        _zoviStamps = stamps;
    }
  }

  void _showMore(String sectionId) {
    final total = _stampsFor(sectionId).length;
    if (total <= 0) return;
    final currentVisible = _visibleCountBySection[sectionId] ?? _previewCount;
    final minVisible = total < _previewCount ? total : _previewCount;
    final nextVisible = (currentVisible + _previewCount).clamp(
      minVisible,
      total,
    );
    setState(() {
      _visibleCountBySection[sectionId] = nextVisible;
      _openMenuSectionId = null;
    });
  }

  void _toggleMenu(String sectionId) {
    setState(() {
      _openMenuSectionId = _openMenuSectionId == sectionId ? null : sectionId;
    });
  }

  void _deleteSection(String sectionId) {
    setState(() {
      _hiddenSections.add(sectionId);
      _openMenuSectionId = null;
      _setStampsFor(sectionId, []);
      _selected.removeWhere((key) => key.sectionId == sectionId);
      if (_selected.isEmpty) _isSelecting = false;
    });
  }

  void _exitSelection() {
    setState(() {
      _isSelecting = false;
      _selected.clear();
      _openMenuSectionId = null;
    });
  }

  void _onStampLongPress(String sectionId, int index) {
    if (sectionId == _zoviStampsId) return;
    final offset = _scrollController.hasClients
        ? _scrollController.offset
        : 0.0;
    setState(() {
      _openMenuSectionId = null;
      _isSelecting = true;
      _selected.add(_StampKey(sectionId, index));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final position = _scrollController.position;
      _scrollController.jumpTo(
        offset.clamp(position.minScrollExtent, position.maxScrollExtent),
      );
    });
  }

  void _onStampTap(String sectionId, int index, _StickerItem stamp) {
    if (_isSelecting) {
      setState(() {
        final key = _StampKey(sectionId, index);
        if (_selected.contains(key)) {
          _selected.remove(key);
          if (_selected.isEmpty) _isSelecting = false;
        } else {
          _selected.add(key);
        }
      });
      return;
    }
    _openMenuSectionId = null;
    _showStampPreview(stamp);
  }

  Future<void> _showStampPreview(_StickerItem stamp) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'sticker_preview',
      barrierColor: Colors.black.withValues(alpha: 0.72),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return SafeArea(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: _StampImage(
                  path: stamp.path,
                  stampId: stamp.id,
                  size: 280,
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  void _deleteSelected() {
    if (_selected.isEmpty) return;

    final bySection = <String, List<int>>{};
    for (final key in _selected) {
      if (key.sectionId == _zoviStampsId) continue;
      bySection.putIfAbsent(key.sectionId, () => []).add(key.index);
    }
    if (bySection.isEmpty) return;

    setState(() {
      for (final entry in bySection.entries) {
        final indexes = entry.value.toSet();
        final current = _stampsFor(entry.key);
        final updated = <_StickerItem>[
          for (var i = 0; i < current.length; i++)
            if (!indexes.contains(i)) current[i],
        ];
        _setStampsFor(entry.key, updated);
        if (updated.isEmpty) _hiddenSections.add(entry.key);
      }
      _selected.clear();
      _isSelecting = false;
      _openMenuSectionId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const buttonHeight = 50.0;
    const buttonTopGap = 8.0;
    final listBottomPad = buttonHeight + buttonTopGap + bottomInset + 16;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _StickersHeader(
              isSelecting: _isSelecting,
              selectedCount: _selected.length,
              onCancelSelection: _exitSelection,
            ),
            Expanded(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _openMenuSectionId = null),
                    behavior: HitTestBehavior.translucent,
                    child: ListView(
                      controller: _scrollController,
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16, 8, 16, listBottomPad),
                      children: [
                        if (!_hiddenSections.contains(_myCreationsId)) ...[
                          _StickerSection(
                            sectionId: _myCreationsId,
                            title: 'sticker_my_creations'.tr(),
                            stamps: _myCreations,
                            emptyTextKey: 'sticker_empty_my_creations',
                            isLoading: _isLoadingMyCreations,
                            previewCount: _previewCount,
                            visibleCount:
                                _visibleCountBySection[_myCreationsId] ??
                                _previewCount,
                            onShowMore: () => _showMore(_myCreationsId),
                            isMenuOpen: _openMenuSectionId == _myCreationsId,
                            onMenuTap: () => _toggleMenu(_myCreationsId),
                            onDeleteSection: () =>
                                _deleteSection(_myCreationsId),
                            canDeleteSection: true,
                            isSelecting: _isSelecting,
                            selected: _selected,
                            onStampTap: _onStampTap,
                            onStampLongPress: _onStampLongPress,
                          ),
                          const SizedBox(height: 28),
                        ],
                        if (!_hiddenSections.contains(_zoviStampsId)) ...[
                          _StickerSection(
                            sectionId: _zoviStampsId,
                            title: 'sticker_zovi_stamps'.tr(),
                            stamps: _zoviStamps,
                            emptyTextKey: 'sticker_empty_zovi_stamps',
                            isLoading: _isLoadingZoviStamps,
                            previewCount: _previewCount,
                            visibleCount:
                                _visibleCountBySection[_zoviStampsId] ??
                                _previewCount,
                            onShowMore: () => _showMore(_zoviStampsId),
                            isMenuOpen: _openMenuSectionId == _zoviStampsId,
                            onMenuTap: () {},
                            onDeleteSection: () {},
                            canDeleteSection: false,
                            isSelecting: _isSelecting,
                            selected: _selected,
                            onStampTap: _onStampTap,
                            onStampLongPress: _onStampLongPress,
                          ),
                          const SizedBox(height: 28),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: bottomInset + buttonTopGap,
                    child: SizedBox(
                      height: buttonHeight,
                      child: _isSelecting
                          ? _DeleteSelectedButton(
                              enabled: _selected.isNotEmpty,
                              onTap: _deleteSelected,
                            )
                          : _CreateStickerButton(
                              onTap: () async {
                                final created = await context.push<bool>(
                                  RoutePaths.createSticker.path,
                                );
                                if (!context.mounted || created != true) return;
                                await _loadStickers(
                                  context.locale.languageCode,
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StampKey {
  const _StampKey(this.sectionId, this.index);

  final String sectionId;
  final int index;

  @override
  bool operator ==(Object other) {
    return other is _StampKey &&
        other.sectionId == sectionId &&
        other.index == index;
  }

  @override
  int get hashCode => Object.hash(sectionId, index);
}

class _StickersHeader extends StatelessWidget {
  const _StickersHeader({
    required this.isSelecting,
    required this.selectedCount,
    required this.onCancelSelection,
  });

  final bool isSelecting;
  final int selectedCount;
  final VoidCallback onCancelSelection;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            if (!isSelecting) ...[
              GestureDetector(
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(RoutePaths.profile.path);
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: const AppIcon(AssetPaths.iconBack, size: 24),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                isSelecting
                    ? 'sticker_selected_count'.tr(
                        namedArgs: {'count': '$selectedCount'},
                      )
                    : 'sticker_title'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1,
                  letterSpacing: -0.32,
                  color: AppColors.black,
                ),
              ),
            ),
            if (isSelecting)
              GestureDetector(
                onTap: onCancelSelection,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'sticker_clear_selection'.tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1,
                      letterSpacing: -0.28,
                      color: AppColors.zoviOrange,
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

class _StickerSection extends StatelessWidget {
  const _StickerSection({
    required this.sectionId,
    required this.title,
    required this.stamps,
    required this.emptyTextKey,
    required this.isLoading,
    required this.previewCount,
    required this.visibleCount,
    required this.onShowMore,
    required this.isMenuOpen,
    required this.onMenuTap,
    required this.onDeleteSection,
    required this.canDeleteSection,
    required this.isSelecting,
    required this.selected,
    required this.onStampTap,
    required this.onStampLongPress,
  });

  final String sectionId;
  final String title;
  final List<_StickerItem> stamps;
  final String emptyTextKey;
  final bool isLoading;
  final int previewCount;
  final int visibleCount;
  final VoidCallback onShowMore;
  final bool isMenuOpen;
  final VoidCallback onMenuTap;
  final VoidCallback onDeleteSection;
  final bool canDeleteSection;
  final bool isSelecting;
  final Set<_StampKey> selected;
  final void Function(String sectionId, int index, _StickerItem stamp)
  onStampTap;
  final void Function(String sectionId, int index) onStampLongPress;

  @override
  Widget build(BuildContext context) {
    final canShowMenu = canDeleteSection && stamps.isNotEmpty;
    final safeVisibleCount = stamps.isEmpty
        ? 0
        : visibleCount.clamp(
            stamps.length < previewCount ? stamps.length : previewCount,
            stamps.length,
          );
    final remaining = stamps.length - safeVisibleCount;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1,
                      letterSpacing: -0.32,
                      color: AppColors.black,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: isSelecting || !canShowMenu ? null : onMenuTap,
                  behavior: HitTestBehavior.opaque,
                  child: Opacity(
                    opacity: isSelecting || !canShowMenu ? 0 : 1,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: AppIcon(AssetPaths.iconThreeDot, size: 24),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (isLoading)
              const _SectionLoadingState()
            else if (stamps.isEmpty)
              _SectionEmptyState(textKey: emptyTextKey)
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: safeVisibleCount,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final stamp = stamps[index];
                  final isSelected = selected.contains(
                    _StampKey(sectionId, index),
                  );
                  return _StampCell(
                    path: stamp.path,
                    stampId: stamp.id,
                    isSelecting: isSelecting,
                    isSelected: isSelected,
                    onTap: () => onStampTap(sectionId, index, stamp),
                    onLongPress: () => onStampLongPress(sectionId, index),
                  );
                },
              ),
            if (remaining > 0) ...[
              Transform.translate(
                offset: const Offset(0, -18),
                child: Center(
                  child: GestureDetector(
                    onTap: onShowMore,
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      'sticker_more'.tr(namedArgs: {'count': '$remaining'}),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1,
                        letterSpacing: -0.32,
                        color: AppColors.zoviOrange,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (isMenuOpen && !isSelecting && canShowMenu)
          Positioned(
            top: 36,
            right: 0,
            child: _DeleteMenu(onDelete: onDeleteSection),
          ),
      ],
    );
  }
}

class _StampCell extends StatelessWidget {
  const _StampCell({
    required this.path,
    required this.stampId,
    required this.isSelecting,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  final String path;
  final String stampId;
  final bool isSelecting;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.all(2),
            child: _StampImage(path: path, stampId: stampId),
          ),
          if (isSelected)
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.zoviOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.zoviOrange, width: 1.5),
                ),
              ),
            ),
          Positioned(
            top: 2,
            right: 2,
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 120),
                opacity: isSelecting ? 1 : 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.zoviOrange : AppColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.zoviOrange
                          : const Color(0xFFE2E2E2),
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 12,
                          color: AppColors.white,
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StampImage extends StatelessWidget {
  const _StampImage({required this.path, this.size, this.stampId = ''});

  final String path;
  final String stampId;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return StampImage(
      path: path,
      stampId: stampId,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}

class _SectionEmptyState extends StatelessWidget {
  const _SectionEmptyState({required this.textKey});

  final String textKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(AssetPaths.iconAward, size: 24, color: AppColors.mutedGray),
          const SizedBox(height: 8),
          Text(
            textKey.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLoadingState extends StatelessWidget {
  const _SectionLoadingState();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEDEDED),
      highlightColor: const Color(0xFFF8F8F8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 10,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1,
        ),
        itemBuilder: (_, _) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }
}

class _DeleteMenu extends StatelessWidget {
  const _DeleteMenu({required this.onDelete});

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: onDelete,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 38,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.25),
                offset: const Offset(0, 1),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppIcon(AssetPaths.iconTrash, size: 18),
              const SizedBox(width: 10),
              Text(
                'sticker_delete'.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1,
                  letterSpacing: -0.28,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteSelectedButton extends StatelessWidget {
  const _DeleteSelectedButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: enabled ? 1 : 0.4,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFEC1C24),
            borderRadius: BorderRadius.circular(99999),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppIcon(
                AssetPaths.iconTrash,
                size: 22,
                color: AppColors.white,
              ),
              const SizedBox(width: 10),
              Text(
                'sticker_delete_selected'.tr(),
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
    );
  }
}

class _CreateStickerButton extends StatelessWidget {
  const _CreateStickerButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
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
            const AppIcon(AssetPaths.iconAi, size: 24),
            const SizedBox(width: 10),
            Text(
              'sticker_create'.tr(),
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
    );
  }
}

class _StickerItem {
  const _StickerItem({
    required this.id,
    required this.path,
    required this.name,
  });

  final String id;
  final String path;
  final String name;
}
