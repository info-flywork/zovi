import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/navigation/open_user_profile.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/stories/model/story_detail_route_args.dart';

class StoryDetailView extends StatefulWidget {
  const StoryDetailView({required this.args, super.key});

  final StoryDetailRouteArgs args;

  @override
  State<StoryDetailView> createState() => _StoryDetailViewState();
}

class _StoryDetailViewState extends State<StoryDetailView>
    with SingleTickerProviderStateMixin {
  static const _storyDuration = Duration(seconds: 5);

  late final PageController _pageController;
  late final AnimationController _progressController;
  late int _index;
  final Set<int> _liked = {};
  var _paused = false;

  List<StoryMediaItem> get _items => widget.args.items;

  StoryMediaItem get _current => _items[_index];

  @override
  void initState() {
    super.initState();
    _index = widget.args.initialIndex.clamp(0, _items.length - 1);
    _pageController = PageController(initialPage: _index);
    _progressController = AnimationController(
      vsync: this,
      duration: _storyDuration,
    )..addStatusListener(_onProgressStatus);
    _markCurrentViewed();
    _startProgress();
  }

  void _markCurrentViewed() {
    getIt<UserRepository>().markStoryViewed(_current.avatarPath);
  }

  @override
  void dispose() {
    _progressController
      ..removeStatusListener(_onProgressStatus)
      ..dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onProgressStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _paused) return;
    if (_current.isReel) {
      _progressController
        ..reset()
        ..forward();
      return;
    }
    _goNext();
  }

  void _startProgress() {
    _paused = false;
    _progressController
      ..reset()
      ..forward();
  }

  void _pause() {
    if (_paused) return;
    _paused = true;
    _progressController.stop();
  }

  void _resume() {
    if (!_paused) return;
    _paused = false;
    _progressController.forward();
  }

  Future<void> _goTo(int index) async {
    if (index < 0 || index >= _items.length) {
      if (mounted) context.pop();
      return;
    }
    if (index == _index) {
      _startProgress();
      return;
    }
    setState(() => _index = index);
    _markCurrentViewed();
    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
    if (mounted) _startProgress();
  }

  void _goNext() => _goTo(_index + 1);

  void _goPrevious() {
    if (_progressController.value > 0.2) {
      _startProgress();
      return;
    }
    _goTo(_index - 1);
  }

  void _onPageChanged(int index) {
    if (index == _index) return;
    setState(() => _index = index);
    _markCurrentViewed();
    _startProgress();
  }

  void _toggleLike() {
    setState(() {
      if (!_liked.add(_index)) {
        _liked.remove(_index);
      }
    });
  }

  Future<void> _openProfile() async {
    _pause();
    await openUserProfile(context, _current.label);
    if (mounted) _resume();
  }

  void _onTapUp(TapUpDetails details) {
    final width = MediaQuery.sizeOf(context).width;
    if (details.localPosition.dx < width * 0.35) {
      _goPrevious();
    } else if (details.localPosition.dx > width * 0.65) {
      _goNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTapUp: _onTapUp,
              onLongPressStart: (_) => _pause(),
              onLongPressEnd: (_) => _resume(),
              child: PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: _items.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Image.asset(
                    item.imagePath,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  );
                },
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, _) {
                      return Row(
                        children: [
                          Expanded(
                            child: _ProgressBar(
                              progress: _progressController.value,
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => context.pop(),
                            behavior: HitTestBehavior.opaque,
                            child: const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.close,
                                color: AppColors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomOverlay(
                item: _current,
                liked: _liked.contains(_index),
                onLike: _toggleLike,
                onProfileTap: _openProfile,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 2,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0x33FFFFFF)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: const ColoredBox(color: AppColors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomOverlay extends StatelessWidget {
  const _BottomOverlay({
    required this.item,
    required this.liked,
    required this.onLike,
    required this.onProfileTap,
  });

  final StoryMediaItem item;
  final bool liked;
  final VoidCallback onLike;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xFF000000), Color(0x00000000)],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 40, 16, 16 + bottomPad),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: onProfileTap,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFB6B6B6),
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              item.avatarPath,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              height: 1,
                              letterSpacing: -0.32,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        if (item.isVerified) ...[
                          const SizedBox(width: 6),
                          const AppIcon(AssetPaths.iconVerify, size: 18),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1,
                      letterSpacing: -0.28,
                      color: AppColors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _LikeButton(liked: liked, onLike: onLike),
          ],
        ),
      ),
    );
  }
}

class _LikeButton extends StatefulWidget {
  const _LikeButton({required this.liked, required this.onLike});

  final bool liked;
  final VoidCallback onLike;

  @override
  State<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<_LikeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  final List<_FloatingHeartData> _hearts = [];
  var _heartId = 0;

  static const _bursts = [
    (dx: -18.0, size: 16.0, delayMs: 0),
    (dx: 6.0, size: 20.0, delayMs: 40),
    (dx: -8.0, size: 14.0, delayMs: 80),
    (dx: 16.0, size: 18.0, delayMs: 110),
    (dx: -2.0, size: 22.0, delayMs: 150),
    (dx: 10.0, size: 15.0, delayMs: 190),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.4), weight: 45),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.4, end: 0.88),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.88, end: 1.0),
        weight: 30,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spawnHearts() {
    setState(() {
      for (final burst in _bursts) {
        _hearts.add(
          _FloatingHeartData(
            id: _heartId++,
            dx: burst.dx,
            size: burst.size,
            delay: Duration(milliseconds: burst.delayMs),
          ),
        );
      }
    });
  }

  void _removeHeart(int id) {
    if (!mounted) return;
    setState(() => _hearts.removeWhere((heart) => heart.id == id));
  }

  void _handleTap() {
    final willLike = !widget.liked;
    widget.onLike();
    if (willLike) {
      _controller.forward(from: 0);
      _spawnHearts();
    } else {
      _controller.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          for (final heart in _hearts)
            _FloatingHeart(
              key: ValueKey(heart.id),
              data: heart,
              onCompleted: () => _removeHeart(heart.id),
            ),
          GestureDetector(
            onTap: _handleTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.black.withValues(alpha: 0.35),
              ),
              alignment: Alignment.center,
              child: ScaleTransition(
                scale: _scale,
                child: AppIcon(
                  AssetPaths.iconHeart2,
                  size: 20,
                  color: widget.liked ? AppColors.zoviOrange : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingHeartData {
  const _FloatingHeartData({
    required this.id,
    required this.dx,
    required this.size,
    required this.delay,
  });

  final int id;
  final double dx;
  final double size;
  final Duration delay;
}

class _FloatingHeart extends StatefulWidget {
  const _FloatingHeart({
    required this.data,
    required this.onCompleted,
    super.key,
  });

  final _FloatingHeartData data;
  final VoidCallback onCompleted;

  @override
  State<_FloatingHeart> createState() => _FloatingHeartState();
}

class _FloatingHeartState extends State<_FloatingHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _dy;
  late final Animation<double> _dx;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _dy = Tween<double>(begin: 0, end: -110).animate(curved);
    _dx = Tween<double>(
      begin: widget.data.dx * 0.2,
      end: widget.data.dx,
    ).animate(curved);
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 35),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 50),
    ]).animate(_controller);
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.4, end: 1.15),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 0.85),
        weight: 65,
      ),
    ]).animate(curved);

    Future<void>.delayed(widget.data.delay, () {
      if (!mounted) return;
      _controller.forward().whenComplete(widget.onCompleted);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_dx.value, _dy.value),
          child: Opacity(
            opacity: _opacity.value.clamp(0.0, 1.0),
            child: Transform.scale(scale: _scale.value, child: child),
          ),
        );
      },
      child: AppIcon(
        AssetPaths.iconHeart2,
        size: widget.data.size,
        color: AppColors.zoviOrange,
      ),
    );
  }
}
