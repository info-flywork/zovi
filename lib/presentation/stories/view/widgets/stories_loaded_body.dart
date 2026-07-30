part of '../stories_view.dart';

class StoriesLoadedBody extends StatelessWidget {
  const StoriesLoadedBody({
    required this.items,
    required this.onOpen,
    super.key,
  });

  final List<StoryMediaItem> items;
  final void Function(List<StoryMediaItem> items, int index) onOpen;

  String get _contentKey =>
      items.isEmpty ? 'empty' : items.map((e) => e.imagePath).join('|');

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            ...previousChildren,
            ?currentChild,
          ],
        );
      },
      transitionBuilder: (child, animation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(_contentKey),
        child: items.isEmpty
            ? const _StoriesEmptyState()
            : SizedBox.expand(
                child: _StoriesGrid(
                  items: items,
                  onOpen: onOpen,
                ),
              ),
      ),
    );
  }
}

class StoriesGridShimmer extends StatelessWidget {
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

class _StoriesEmptyState extends StatelessWidget {
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

class _StoriesGrid extends StatelessWidget {
  const _StoriesGrid({
    required this.items,
    required this.onOpen,
  });

  final List<StoryMediaItem> items;
  final void Function(List<StoryMediaItem> items, int index) onOpen;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.only(
        bottom: MainWrapper.navBarHeight + MediaQuery.paddingOf(context).bottom,
      ),
      physics: const ClampingScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final delayMs = (index % 9) * 28;
        return _StoryGridItem(
          key: ValueKey(item.storyId ?? item.imagePath),
          item: item,
          delay: Duration(milliseconds: delayMs),
          onTap: () => onOpen(items, index),
        );
      },
    );
  }
}

class _StoryGridItem extends StatefulWidget {
  const _StoryGridItem({
    required this.item,
    required this.delay,
    required this.onTap,
    super.key,
  });

  final StoryMediaItem item;
  final Duration delay;
  final VoidCallback onTap;

  @override
  State<_StoryGridItem> createState() => _StoryGridItemState();
}

class _StoryGridItemState extends State<_StoryGridItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _scale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (widget.item.isNetworkImage)
                StampImage(
                  path: widget.item.imagePath,
                  stampId: widget.item.storyId ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const ColoredBox(color: AppColors.surfaceGray),
                )
              else
                Image.asset(
                  widget.item.imagePath,
                  fit: BoxFit.cover,
                ),
              if (widget.item.isReel)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: AppIcon(
                    AssetPaths.iconReelsSquare,
                    size: 22,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
