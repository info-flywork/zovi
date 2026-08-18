part of '../stories_view.dart';

@immutable
final class StoriesLoadedBody extends StatelessWidget {
  const StoriesLoadedBody({
    required this.items,
    required this.onOpen,
    super.key,
  });

  final List<StoryMediaItem> items;
  final void Function(List<StoryMediaItem> items, int index) onOpen;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const _StoriesEmptyState();
    return _StoriesGrid(items: items, onOpen: onOpen);
  }
}

@immutable
final class StoriesGridShimmer extends StatelessWidget {
  const StoriesGridShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8E8E8),
      highlightColor: const Color(0xFFF5F5F5),
      child: GridView.builder(
        padding: EdgeInsets.only(
          bottom:
              MainWrapper.navBarHeight + MediaQuery.paddingOf(context).bottom,
        ),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 18,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 1.5,
          crossAxisSpacing: 1.5,
          childAspectRatio: 1,
        ),
        itemBuilder: (_, _) => const ColoredBox(color: AppColors.white),
      ),
    );
  }
}

@immutable
final class _StoriesEmptyState extends StatelessWidget {
  const _StoriesEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppIcon(
              AssetPaths.iconSearch,
              size: 40,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              'stories_empty'.tr(),
              textAlign: TextAlign.center,
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
      ),
    );
  }
}

@immutable
final class _StoriesGrid extends StatefulWidget {
  const _StoriesGrid({
    required this.items,
    required this.onOpen,
  });

  final List<StoryMediaItem> items;
  final void Function(List<StoryMediaItem> items, int index) onOpen;

  @override
  State<_StoriesGrid> createState() => _StoriesGridState();
}

final class _StoriesGridState extends State<_StoriesGrid> {
  var _peeking = false;

  @override
  Widget build(BuildContext context) {
    final cacheSide = GridThumbnailImage.cacheSideFor(context);
    return GridView.builder(
      padding: EdgeInsets.only(
        bottom: MainWrapper.navBarHeight + MediaQuery.paddingOf(context).bottom,
      ),
      physics: _peeking
          ? const NeverScrollableScrollPhysics()
          : const ClampingScrollPhysics(),
      itemCount: widget.items.length,
      addAutomaticKeepAlives: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final item = widget.items[index];
        return _StoryGridItem(
          key: ValueKey(
            item.storyId ??
                '${item.isPulse ? 'p' : 's'}_${item.userId}_${item.imagePath}',
          ),
          item: item,
          cacheSide: cacheSide,
          onTap: () => widget.onOpen(widget.items, index),
          onPeekChanged: (peeking) {
            if (_peeking == peeking) return;
            setState(() => _peeking = peeking);
          },
        );
      },
    );
  }
}

@immutable
final class _StoryGridItem extends StatefulWidget {
  const _StoryGridItem({
    required this.item,
    required this.cacheSide,
    required this.onTap,
    required this.onPeekChanged,
    super.key,
  });

  final StoryMediaItem item;
  final int cacheSide;
  final VoidCallback onTap;
  final ValueChanged<bool> onPeekChanged;

  @override
  State<_StoryGridItem> createState() => _StoryGridItemState();
}

final class _StoryGridItemState extends State<_StoryGridItem>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _entry;
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.86, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _removePeek(immediate: true);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showPeek() async {
    if (_entry != null) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    HapticFeedback.mediumImpact();
    widget.onPeekChanged(true);

    _entry = OverlayEntry(
      builder: (context) => _StoryPeekOverlay(
        item: widget.item,
        fade: _fade,
        scale: _scale,
      ),
    );
    overlay.insert(_entry!);
    await _controller.forward();
  }

  Future<void> _hidePeek() async {
    if (_entry == null) return;
    await _controller.reverse();
    _removePeek();
  }

  void _removePeek({bool immediate = false}) {
    _entry?.remove();
    _entry = null;
    if (!immediate && mounted) widget.onPeekChanged(false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPressStart: (_) => _showPeek(),
      onLongPressEnd: (_) => _hidePeek(),
      onLongPressCancel: _hidePeek,
      child: _StoryThumb(
        item: widget.item,
        cacheSide: widget.cacheSide,
      ),
    );
  }
}

@immutable
final class _StoryThumb extends StatelessWidget {
  const _StoryThumb({
    required this.item,
    required this.cacheSide,
  });

  final StoryMediaItem item;
  final int cacheSide;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (item.isVideo)
          const ColoredBox(color: AppColors.black)
        else if (item.isNetworkImage)
          GridThumbnailImage(
            url: item.gridImagePath,
            cacheSize: cacheSide,
          )
        else
          Image.asset(
            item.imagePath,
            fit: BoxFit.cover,
          ),
        if (item.isReel || item.isVideo)
          const Positioned(
            top: 8,
            right: 8,
            child: AppIcon(
              AssetPaths.iconReelsSquare,
              size: 22,
            ),
          ),
      ],
    );
  }
}

@immutable
final class _StoryPeekOverlay extends StatelessWidget {
  const _StoryPeekOverlay({
    required this.item,
    required this.fade,
    required this.scale,
  });

  final StoryMediaItem item;
  final Animation<double> fade;
  final Animation<double> scale;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screen = media.size;
    final previewW = (screen.width * 0.88).clamp(280.0, screen.width - 24);
    final previewH = (previewW * 1.38).clamp(
      360.0,
      screen.height - media.padding.top - media.padding.bottom - 48,
    );

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: fade,
        builder: (context, child) {
          return Stack(
            children: [
              ColoredBox(
                color: AppColors.black.withValues(alpha: 0.42 * fade.value),
              ),
              Center(
                child: FadeTransition(
                  opacity: fade,
                  child: ScaleTransition(
                    scale: scale,
                    child: SizedBox(
                      width: previewW,
                      height: previewH,
                      child: child,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        child: Material(
          color: AppColors.white,
          elevation: 18,
          shadowColor: AppColors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Row(
                  children: [
                    ProfileAvatar(
                      path: item.avatarPath,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.storyLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _StoryThumb(
                  item: item,
                  cacheSide: GridThumbnailImage.cacheSideFor(context) * 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
