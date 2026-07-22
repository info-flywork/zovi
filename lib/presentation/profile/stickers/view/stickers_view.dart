import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';

class StickersView extends StatefulWidget {
  const StickersView({super.key});

  @override
  State<StickersView> createState() => _StickersViewState();
}

class _StickersViewState extends State<StickersView> {
  static const _previewCount = 10;
  static const _myCreationsId = 'my_creations';
  static const _zoviStampsId = 'zovi_stamps';
  static const _nightOwlId = 'night_owl';

  late List<String> _myCreations;
  late List<String> _zoviStamps;
  late List<String> _nightOwl;

  final _scrollController = ScrollController();
  final Set<String> _expandedSections = {};
  final Set<String> _hiddenSections = {};
  final Set<_StampKey> _selected = {};
  String? _openMenuSectionId;
  var _isSelecting = false;

  @override
  void initState() {
    super.initState();
    final all = [
      AssetPaths.stamp1,
      AssetPaths.stamp2,
      AssetPaths.stamp3,
      AssetPaths.stamp4,
      AssetPaths.stamp5,
      AssetPaths.stamp6,
      AssetPaths.stamp7,
      AssetPaths.stamp8,
      AssetPaths.stamp9,
      AssetPaths.stamp10,
      AssetPaths.stamp11,
      AssetPaths.stamp12,
      AssetPaths.stamp13,
      AssetPaths.stamp14,
      AssetPaths.stamp15,
      AssetPaths.stamp16,
      AssetPaths.stamp17,
      AssetPaths.stamp1,
      AssetPaths.stamp5,
    ];
    _myCreations = List<String>.from(all);
    _zoviStamps = List<String>.from(all);
    _nightOwl = List<String>.from(all);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<String> _stampsFor(String sectionId) {
    return switch (sectionId) {
      _myCreationsId => _myCreations,
      _zoviStampsId => _zoviStamps,
      _ => _nightOwl,
    };
  }

  void _setStampsFor(String sectionId, List<String> stamps) {
    switch (sectionId) {
      case _myCreationsId:
        _myCreations = stamps;
      case _zoviStampsId:
        _zoviStamps = stamps;
      case _nightOwlId:
        _nightOwl = stamps;
    }
  }

  void _toggleExpanded(String sectionId) {
    setState(() {
      if (_expandedSections.contains(sectionId)) {
        _expandedSections.remove(sectionId);
      } else {
        _expandedSections.add(sectionId);
      }
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

  void _onStampTap(String sectionId, int index, String path) {
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
    _showStampPreview(path);
  }

  Future<void> _showStampPreview(String path) {
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
                child: Image.asset(
                  path,
                  width: 280,
                  height: 280,
                  fit: BoxFit.contain,
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
      bySection.putIfAbsent(key.sectionId, () => []).add(key.index);
    }

    setState(() {
      for (final entry in bySection.entries) {
        final indexes = entry.value.toSet();
        final current = _stampsFor(entry.key);
        final updated = <String>[
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
                            previewCount: _previewCount,
                            isExpanded: _expandedSections.contains(
                              _myCreationsId,
                            ),
                            onToggleMore: () => _toggleExpanded(_myCreationsId),
                            isMenuOpen: _openMenuSectionId == _myCreationsId,
                            onMenuTap: () => _toggleMenu(_myCreationsId),
                            onDeleteSection: () =>
                                _deleteSection(_myCreationsId),
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
                            previewCount: _previewCount,
                            isExpanded: _expandedSections.contains(
                              _zoviStampsId,
                            ),
                            onToggleMore: () => _toggleExpanded(_zoviStampsId),
                            isMenuOpen: _openMenuSectionId == _zoviStampsId,
                            onMenuTap: () => _toggleMenu(_zoviStampsId),
                            onDeleteSection: () =>
                                _deleteSection(_zoviStampsId),
                            isSelecting: _isSelecting,
                            selected: _selected,
                            onStampTap: _onStampTap,
                            onStampLongPress: _onStampLongPress,
                          ),
                          const SizedBox(height: 28),
                        ],
                        if (!_hiddenSections.contains(_nightOwlId))
                          _StickerSection(
                            sectionId: _nightOwlId,
                            title: 'sticker_night_owl'.tr(),
                            stamps: _nightOwl,
                            previewCount: _previewCount,
                            isExpanded: _expandedSections.contains(_nightOwlId),
                            onToggleMore: () => _toggleExpanded(_nightOwlId),
                            isMenuOpen: _openMenuSectionId == _nightOwlId,
                            onMenuTap: () => _toggleMenu(_nightOwlId),
                            onDeleteSection: () => _deleteSection(_nightOwlId),
                            isSelecting: _isSelecting,
                            selected: _selected,
                            onStampTap: _onStampTap,
                            onStampLongPress: _onStampLongPress,
                          ),
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
                              onTap: () =>
                                  context.push(RoutePaths.createSticker.path),
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
    required this.previewCount,
    required this.isExpanded,
    required this.onToggleMore,
    required this.isMenuOpen,
    required this.onMenuTap,
    required this.onDeleteSection,
    required this.isSelecting,
    required this.selected,
    required this.onStampTap,
    required this.onStampLongPress,
  });

  final String sectionId;
  final String title;
  final List<String> stamps;
  final int previewCount;
  final bool isExpanded;
  final VoidCallback onToggleMore;
  final bool isMenuOpen;
  final VoidCallback onMenuTap;
  final VoidCallback onDeleteSection;
  final bool isSelecting;
  final Set<_StampKey> selected;
  final void Function(String sectionId, int index, String path) onStampTap;
  final void Function(String sectionId, int index) onStampLongPress;

  @override
  Widget build(BuildContext context) {
    final remaining = stamps.length - previewCount;
    final visibleCount = isExpanded || remaining <= 0
        ? stamps.length
        : previewCount;

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
                  onTap: isSelecting ? null : onMenuTap,
                  behavior: HitTestBehavior.opaque,
                  child: Opacity(
                    opacity: isSelecting ? 0 : 1,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: AppIcon(AssetPaths.iconThreeDot, size: 24),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visibleCount,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final path = stamps[index];
                final isSelected = selected.contains(
                  _StampKey(sectionId, index),
                );
                return _StampCell(
                  path: path,
                  isSelecting: isSelecting,
                  isSelected: isSelected,
                  onTap: () => onStampTap(sectionId, index, path),
                  onLongPress: () => onStampLongPress(sectionId, index),
                );
              },
            ),
            if (!isExpanded && remaining > 0) ...[
              Transform.translate(
                offset: const Offset(0, -18),
                child: Center(
                  child: GestureDetector(
                    onTap: onToggleMore,
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
        if (isMenuOpen && !isSelecting)
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
    required this.isSelecting,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  final String path;
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
            child: Image.asset(path, fit: BoxFit.contain),
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
