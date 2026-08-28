import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:zovi/core/cache/music_audio_cache.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/utils/bunny_image_url.dart';
import 'package:zovi/core/in_app_notification/app_in_app_notification.dart';
import 'package:zovi/core/in_app_notification/in_app_notification_data.dart';
import 'package:zovi/core/snackbar/app_snackbar.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/navigation/open_user_profile.dart';
import 'package:zovi/core/widgets/app_confirm_dialog.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/core/widgets/app_loading.dart';
import 'package:zovi/core/widgets/profile_avatar.dart';
import 'package:zovi/domain/auth/auth_repository.dart';
import 'package:zovi/domain/chat/chat_repository.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/home/bloc/home_bloc.dart';
import 'package:zovi/presentation/home/bloc/home_event.dart';
import 'package:zovi/presentation/stories/bloc/stories_bloc.dart';
import 'package:zovi/presentation/stories/bloc/stories_event.dart';
import 'package:zovi/presentation/stories/model/story_detail_route_args.dart';

@immutable
final class StoryDetailView extends StatefulWidget {
  const StoryDetailView({required this.args, super.key});

  final StoryDetailRouteArgs args;

  @override
  State<StoryDetailView> createState() => _StoryDetailViewState();
}

final class _StoryDetailViewState extends State<StoryDetailView>
    with SingleTickerProviderStateMixin {
  static const _storyDuration = Duration(seconds: 5);

  late final PageController _pageController;
  late final AnimationController _progressController;
  late int _index;
  late List<StoryMediaItem> _items;
  var _paused = false;
  var _likeInFlight = false;
  var _dragDy = 0.0;
  var _dragging = false;
  var _pausedForDismiss = false;
  var _replySending = false;
  var _deleting = false;
  final _replyController = TextEditingController();
  final _replyFocus = FocusNode();

  final _musicPlayer = AudioPlayer();
  StreamSubscription<Duration>? _musicPosSub;
  StreamSubscription<void>? _musicCompleteSub;
  var _musicSeeking = false;
  VideoPlayerController? _videoController;
  var _videoToken = 0;

  // Next-up video is initialized ahead of time so swiping into it doesn't
  // show a load/black-frame gap.
  VideoPlayerController? _preloadController;
  String? _preloadedPath;

  StoryMediaItem get _current => _items[_index];

  String _ownerKey(StoryMediaItem item, int fallbackIndex) {
    final userId = item.userId?.trim() ?? '';
    if (userId.isNotEmpty) return 'id:$userId';
    final username = item.username?.trim().toLowerCase() ?? '';
    if (username.isNotEmpty) return 'username:$username';
    final avatar = item.avatarPath.trim();
    if (avatar.isNotEmpty) return 'avatar:$avatar';
    return 'story:${item.storyId ?? item.imagePath}:$fallbackIndex';
  }

  List<StoryMediaItem> _groupByOwner(List<StoryMediaItem> source) {
    final groups = <String, List<StoryMediaItem>>{};
    for (var i = 0; i < source.length; i++) {
      final item = source[i];
      groups.putIfAbsent(_ownerKey(item, i), () => []).add(item);
    }
    return [for (final group in groups.values) ...group];
  }

  bool _isSameStory(StoryMediaItem a, StoryMediaItem b) {
    final aId = a.storyId?.trim() ?? '';
    final bId = b.storyId?.trim() ?? '';
    if (aId.isNotEmpty && bId.isNotEmpty) return aId == bId;
    return identical(a, b) ||
        (a.imagePath == b.imagePath &&
            a.userId == b.userId &&
            a.username == b.username);
  }

  ({int start, int length, int localIndex}) get _currentGroup {
    final key = _ownerKey(_current, _index);
    var start = _index;
    while (start > 0 && _ownerKey(_items[start - 1], start - 1) == key) {
      start--;
    }
    var end = _index + 1;
    while (end < _items.length && _ownerKey(_items[end], end) == key) {
      end++;
    }
    return (start: start, length: end - start, localIndex: _index - start);
  }

  @override
  void initState() {
    super.initState();
    final repo = getIt<UserRepository>();
    final source = repo.hydrateStoryLikeState(
      List<StoryMediaItem>.of(widget.args.items),
    );
    final sourceIndex = widget.args.initialIndex.clamp(0, source.length - 1);
    final initiallySelected = source[sourceIndex];
    _items = _groupByOwner(source);
    _index = _items.indexWhere((item) => _isSameStory(item, initiallySelected));
    if (_index < 0) _index = 0;
    _pageController = PageController(initialPage: _index);
    _pageController.addListener(_onPageScroll);
    _progressController = AnimationController(
      vsync: this,
      duration: _storyDuration,
    )..addStatusListener(_onProgressStatus);
    _replyFocus.addListener(_onReplyFocusChange);
    unawaited(_markCurrentViewed());
    unawaited(_bootstrapPlayback());
  }

  Future<void> _markCurrentViewed() async {
    final item = _current;
    if (item.isPulse) return;
    getIt<UserRepository>().markStoryViewed(item.avatarPath);
    final storyId = item.storyId;
    if (storyId != null && storyId.isNotEmpty) {
      await getIt<UserRepository>().markStoryViewedById(storyId);
    }
  }

  Future<void> _stopMusic() async {
    await _musicPosSub?.cancel();
    await _musicCompleteSub?.cancel();
    _musicPosSub = null;
    _musicCompleteSub = null;
    _musicSeeking = false;
    try {
      await _musicPlayer.stop();
    } catch (_) {}
  }

  Future<void> _syncMusic() async {
    await _stopMusic();
    final item = _current;
    if (item.isVideoMedia || !item.hasMusic) return;

    final url = item.musicAudioUrl!.trim();
    final startMs = item.musicClipStartMs ?? 0;
    final durationMs = item.musicClipDurationMs ?? 15000;
    final start = Duration(milliseconds: startMs.clamp(0, 1 << 30));
    final end = start + Duration(milliseconds: durationMs.clamp(1000, 60000));

    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.stop);
      final source = await getIt<MusicAudioCache>().resolveSource(
        trackId: item.musicTrackId ?? item.storyId ?? url,
        url: url,
      );

      _musicPosSub = _musicPlayer.onPositionChanged.listen((pos) async {
        if (_musicSeeking) return;
        if (pos < end) return;
        _musicSeeking = true;
        try {
          await _musicPlayer.seek(start);
        } finally {
          _musicSeeking = false;
        }
      });

      _musicCompleteSub = _musicPlayer.onPlayerComplete.listen((_) async {
        if (_musicSeeking) return;
        _musicSeeking = true;
        try {
          await _musicPlayer.seek(start);
          await _musicPlayer.resume();
        } finally {
          _musicSeeking = false;
        }
      });

      await _musicPlayer.play(source, position: start);
    } catch (_) {
      await _stopMusic();
    }
  }

  Future<void> _bootstrapPlayback() async {
    await _syncVideo();
    await _syncMusic();
    if (mounted) _startProgress();
    unawaited(_preloadNextVideo());
  }

  Future<void> _disposeVideo() async {
    _videoToken++;
    final controller = _videoController;
    _videoController = null;
    if (controller == null) return;
    try {
      await controller.pause();
    } catch (_) {}
    await controller.dispose();
  }

  Future<void> _disposePreload() async {
    final controller = _preloadController;
    _preloadController = null;
    _preloadedPath = null;
    if (controller == null) return;
    try {
      await controller.dispose();
    } catch (_) {}
  }

  /// Initializes (without playing) the next item's video so swiping to it
  /// is instant. Only ever holds one preloaded controller at a time.
  Future<void> _preloadNextVideo() async {
    final nextIndex = _index + 1;
    if (nextIndex >= _items.length) return;
    final next = _items[nextIndex];
    if (!next.isVideoMedia || !next.isNetworkImage) return;
    final path = next.imagePath.trim();
    if (path.isEmpty || path == _preloadedPath) return;

    await _disposePreload();
    final token = _videoToken;
    final controller = VideoPlayerController.networkUrl(Uri.parse(path));
    _preloadedPath = path;
    _preloadController = controller;
    try {
      await controller.initialize();
      // Bail if the user already navigated away while this was loading.
      if (!mounted || token != _videoToken || _preloadController != controller) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(false);
    } catch (_) {
      if (identical(_preloadController, controller)) {
        _preloadController = null;
        _preloadedPath = null;
      }
      try {
        await controller.dispose();
      } catch (_) {}
    }
  }

  Future<void> _syncVideo() async {
    final item = _current;
    final path = item.imagePath.trim();

    // Reuse the preloaded controller if it's already sitting on this item.
    if (item.isVideoMedia && _preloadController != null && _preloadedPath == path) {
      await _disposeVideo();
      final controller = _preloadController!;
      _preloadController = null;
      _preloadedPath = null;
      final token = ++_videoToken;
      _videoController = controller;
      try {
        final duration = controller.value.duration;
        _progressController.duration = duration > const Duration(milliseconds: 400)
            ? duration
            : _storyDuration;
        if (!_paused) await controller.play();
        if (mounted) setState(() {});
      } catch (_) {
        if (identical(_videoController, controller)) _videoController = null;
        try {
          await controller.dispose();
        } catch (_) {}
        _progressController.duration = _storyDuration;
      }
      unawaited(token == _videoToken ? _preloadNextVideo() : Future.value());
      return;
    }

    await _disposeVideo();
    if (!item.isVideoMedia) {
      _progressController.duration = _storyDuration;
      return;
    }

    final token = ++_videoToken;
    final controller = item.isNetworkImage
        ? VideoPlayerController.networkUrl(Uri.parse(path))
        : VideoPlayerController.file(File(path.replaceFirst('file://', '')));
    _videoController = controller;
    try {
      await controller.initialize();
      if (!mounted || token != _videoToken) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(false);
      final duration = controller.value.duration;
      _progressController.duration = duration > const Duration(milliseconds: 400)
          ? duration
          : _storyDuration;
      if (!_paused) await controller.play();
      if (mounted) setState(() {});
    } catch (_) {
      if (identical(_videoController, controller)) _videoController = null;
      try {
        await controller.dispose();
      } catch (_) {}
      _progressController.duration = _storyDuration;
    }
  }

  @override
  void dispose() {
    _replyFocus.removeListener(_onReplyFocusChange);
    _replyFocus.dispose();
    _replyController.dispose();
    unawaited(_stopMusic());
    unawaited(_musicPlayer.dispose());
    unawaited(_disposeVideo());
    unawaited(_disposePreload());
    _progressController
      ..removeStatusListener(_onProgressStatus)
      ..dispose();
    _pageController
      ..removeListener(_onPageScroll)
      ..dispose();
    super.dispose();
  }

  void _onReplyFocusChange() {
    if (_replyFocus.hasFocus) {
      _pause();
      return;
    }
    if (!_pausedForDismiss && !_dragging && !_replySending) {
      _resume();
    }
  }

  bool get _isOwnCurrentStory {
    final myId = getIt<AuthRepository>().backendUserId?.trim() ?? '';
    final ownerId = _current.userId?.trim() ?? '';
    if (myId.isNotEmpty && ownerId.isNotEmpty && myId == ownerId) return true;
    var myHandle =
        getIt<UserRepository>().cachedCurrentUser?.usernameHandle
            .trim()
            .toLowerCase() ??
        '';
    var storyHandle = (_current.username ?? '').trim().toLowerCase();
    if (myHandle.startsWith('@')) myHandle = myHandle.substring(1);
    if (storyHandle.startsWith('@')) storyHandle = storyHandle.substring(1);
    return myHandle.isNotEmpty && myHandle == storyHandle;
  }

  bool get _canDeleteCurrent {
    if (_current.isPulse) return false;
    final id = _current.storyId?.trim() ?? '';
    return id.isNotEmpty && _isOwnCurrentStory;
  }

  bool get _canReplyToCurrent {
    if (_isOwnCurrentStory) return false;
    final ownerId = _current.userId?.trim() ?? '';
    final handle = _current.username?.trim() ?? '';
    return ownerId.isNotEmpty || handle.isNotEmpty;
  }

  Future<String?> _peerUserIdForReply() async {
    final ownerId = _current.userId?.trim() ?? '';
    if (ownerId.isNotEmpty) return ownerId;
    final handle = _current.username?.trim() ?? '';
    if (handle.isEmpty) return null;
    try {
      final profile = await getIt<UserRepository>().getPublicUserProfile(handle);
      final id = profile.userId.trim();
      return id.isEmpty ? null : id;
    } catch (_) {
      return null;
    }
  }

  Future<void> _confirmDeleteStory() async {
    if (!_canDeleteCurrent || _deleting) return;
    _pause();
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'story_delete_title'.tr(),
      subtitle: 'story_delete_subtitle'.tr(),
      confirmLabel: 'story_delete_confirm'.tr(),
    );
    if (!mounted) return;
    if (!confirmed) {
      if (!_replyFocus.hasFocus && !_pausedForDismiss) _resume();
      return;
    }
    await _deleteCurrentStory();
  }

  Future<void> _deleteCurrentStory() async {
    final storyId = _current.storyId?.trim() ?? '';
    if (storyId.isEmpty || _deleting) return;
    setState(() => _deleting = true);
    try {
      await getIt<UserRepository>().deleteStory(storyId);
      if (!mounted) return;

      try {
        getIt<HomeBloc>().add(const HomeStoriesRefreshRequested());
      } catch (_) {}
      try {
        getIt<StoriesBloc>().add(const StoriesRefreshRequested(force: true));
      } catch (_) {}

      final removedIndex = _index;
      final nextItems = [
        for (var i = 0; i < _items.length; i++)
          if (i != removedIndex) _items[i],
      ];
      if (nextItems.isEmpty) {
        context.pop();
        return;
      }

      final nextIndex = removedIndex.clamp(0, nextItems.length - 1);
      setState(() {
        _items = nextItems;
        _index = nextIndex;
        _deleting = false;
      });
      if (_pageController.hasClients) {
        _pageController.jumpToPage(nextIndex);
      }
      unawaited(_markCurrentViewed());
      await _bootstrapPlayback();
      if (mounted && !_replyFocus.hasFocus && !_pausedForDismiss) {
        _resume();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleting = false);
      AppSnackbar.instance.show(
        context,
        'story_delete_failed'.tr(),
        isError: true,
      );
      if (!_replyFocus.hasFocus && !_pausedForDismiss) _resume();
    }
  }

  Future<void> _sendStoryReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _replySending || !_canReplyToCurrent) return;
    setState(() => _replySending = true);
    _pause();
    try {
      final peerId = await _peerUserIdForReply();
      if (peerId == null || peerId.isEmpty) {
        throw StateError('Missing peer');
      }
      final chat = getIt<ChatRepository>();
      final conversation = await chat.openDm(peerId);
      final mediaUrl = _current.isNetworkImage ? _current.imagePath.trim() : '';
      await chat.sendMessage(
        conversationId: conversation.id,
        type: 'text',
        body: text,
        mediaUrl: mediaUrl.isEmpty ? null : mediaUrl,
        replyPreview: storyReplyPreviewFor(
          storyId: _current.storyId,
          isPulse: _current.isPulse,
        ),
      );
      if (!mounted) return;
      _replyController.clear();
      _replyFocus.unfocus();
      AppInAppNotification.instance.show(
        InAppNotificationData(
          username: _current.storyLabel,
          displayName: _current.label,
          avatarPath: _current.avatarPath,
          messageKey: 'map_friend_message_sent',
          showGradientRing: true,
          action: InAppNotificationAction.openChat,
          conversationId: conversation.id,
          userId: peerId,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.instance.show(context, 'chat_send_failed'.tr(), isError: true);
    } finally {
      if (mounted) setState(() => _replySending = false);
      if (mounted && !_replyFocus.hasFocus && !_pausedForDismiss) {
        _resume();
      }
    }
  }

  void _onProgressStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _paused) return;
    _goNext();
  }

  void _startProgress() {
    _paused = false;
    _progressController
      ..reset()
      ..forward();
  }

  /// Empties the active segment as soon as a transition begins, so the next
  /// story never briefly inherits the previous one's fill.
  void _resetProgress() {
    if (_progressController.value == 0) return;
    _progressController
      ..stop()
      ..value = 0;
  }

  /// A swipe moves the page well before [_onPageChanged] fires; keep the bar
  /// in sync with the page the user is dragging towards.
  void _onPageScroll() {
    final page = _pageController.page;
    if (page == null) return;
    if ((page - _index).abs() > 0.02) _resetProgress();
  }

  void _pause() {
    if (_paused) return;
    _paused = true;
    _progressController.stop();
    unawaited(_musicPlayer.pause());
    unawaited(_videoController?.pause());
  }

  void _resume() {
    if (!_paused) return;
    _paused = false;
    _progressController.forward();
    unawaited(_musicPlayer.resume());
    unawaited(_videoController?.play());
  }

  Future<void> _goTo(int index) async {
    if (index < 0 || index >= _items.length) {
      if (mounted) context.pop();
      return;
    }
    if (index == _index) {
      try {
        await _videoController?.seekTo(Duration.zero);
        if (!_paused) await _videoController?.play();
      } catch (_) {}
      _startProgress();
      return;
    }
    _resetProgress();
    setState(() => _index = index);
    unawaited(_markCurrentViewed());
    await _syncVideo();
    unawaited(_syncMusic());
    unawaited(_preloadNextVideo());
    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
    if (mounted) _startProgress();
  }

  void _goNext() => _goTo(_index + 1);

  void _goPrevious() {
    // Nothing before the first story — replay it instead of closing.
    if (_index == 0) {
      unawaited(_goTo(0));
      return;
    }
    _goTo(_index - 1);
  }

  void _onPageChanged(int index) {
    if (index == _index) return;
    _replyController.clear();
    if (_replyFocus.hasFocus) _replyFocus.unfocus();
    setState(() => _index = index);
    unawaited(_markCurrentViewed());
    unawaited(() async {
      await _syncVideo();
      await _syncMusic();
      if (mounted) _startProgress();
      unawaited(_preloadNextVideo());
    }());
  }

  Future<void> _toggleLike() async {
    if (_likeInFlight) return;
    final item = _current;
    final storyId = item.storyId?.trim() ?? '';
    final willLike = !item.likedByMe;
    final previous = item;
    final optimisticCount = willLike
        ? item.likeCount + 1
        : (item.likeCount - 1).clamp(0, 1 << 30);

    setState(() {
      _items[_index] = item.copyWith(
        likedByMe: willLike,
        likeCount: optimisticCount,
      );
    });

    // Mock feed entries have no server id — keep the local toggle only.
    if (storyId.isEmpty) return;

    _likeInFlight = true;
    final repo = getIt<UserRepository>();
    final bool? likedByMe;
    final int? likeCount;
    if (item.isPulse) {
      final updated = await repo.togglePulseLike(
        pulseId: storyId,
        like: willLike,
      );
      likedByMe = updated?.likedByMe;
      likeCount = updated?.likeCount;
    } else {
      final updated = await repo.toggleStoryLike(
        storyId: storyId,
        like: willLike,
      );
      likedByMe = updated?.likedByMe;
      likeCount = updated?.likeCount;
    }
    _likeInFlight = false;
    if (!mounted) return;

    if (likedByMe == null || likeCount == null) {
      setState(() => _items[_index] = previous);
      return;
    }

    setState(() {
      _items[_index] = _items[_index].copyWith(
        likedByMe: likedByMe,
        likeCount: likeCount,
      );
    });
    getIt<StoriesBloc>().add(const StoriesRefreshRequested());
    getIt<HomeBloc>().add(const HomeStoriesRefreshRequested());
  }

  Future<void> _openProfile() async {
    final handle = _current.username?.trim() ?? '';
    if (handle.isEmpty) return;
    final myHandle =
        getIt<UserRepository>().cachedCurrentUser?.usernameHandle.trim().toLowerCase() ??
            '';
    final storyHandle =
        (handle.startsWith('@') ? handle.substring(1) : handle).toLowerCase();
    if (myHandle.isNotEmpty && myHandle == storyHandle) return;
    _pause();
    await openUserProfile(
      context,
      handle,
      seed: PublicUserProfile.skeleton(
        username: handle,
        name: _current.label,
        avatarPath: _current.avatarPath,
        userId: _current.userId ?? '',
        hasActiveStory: true,
      ),
    );
    if (mounted) _resume();
  }

  Widget _buildMedia(StoryMediaItem item) {
    if (item.isVideoMedia) {
      final controller = _videoController;
      if (controller != null && controller.value.isInitialized) {
        return ColoredBox(
          color: AppColors.black,
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
          ),
        );
      }
      return const ColoredBox(
        color: AppColors.black,
        child: AppLoading(),
      );
    }
    if (item.isNetworkImage) {
      final pixelWidth =
          (MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context))
              .round();
      return CachedNetworkImage(
        imageUrl: bunnySizedUrl(item.imagePath, pixelWidth, quality: 85),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        memCacheWidth: pixelWidth,
        fadeInDuration: Duration.zero,
        placeholder: (_, _) => const ColoredBox(color: AppColors.black),
        errorWidget: (_, _, _) => const ColoredBox(color: AppColors.black),
      );
    }
    return Image.asset(
      item.imagePath,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.black,
        resizeToAvoidBottomInset: true,
        body: GestureDetector(
          onVerticalDragStart: _onDismissDragStart,
          onVerticalDragUpdate: _onDismissDragUpdate,
          onVerticalDragEnd: _onDismissDragEnd,
          onVerticalDragCancel: _onDismissDragCancel,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: _dragDy),
            duration: _dragging
                ? Duration.zero
                : const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            builder: (context, dy, child) {
              final t = height <= 0 ? 0.0 : (dy / height).clamp(0.0, 1.0);
              return Transform.translate(
                offset: Offset(0, dy),
                child: Transform.scale(
                  scale: 1 - t * 0.12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(t * 24),
                    child: child,
                  ),
                ),
              );
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  onTapUp: _onTapUp,
                  onLongPressStart: (_) => _pause(),
                  onLongPressEnd: (_) => _resume(),
                  child: PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.horizontal,
                    itemCount: _items.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, index) {
                      return _buildMedia(_items[index]);
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
                      final group = _currentGroup;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _SegmentedProgressBar(
                                  segmentCount: group.length,
                                  activeIndex: group.localIndex,
                                  progress: _progressController.value,
                                ),
                              ),
                              const SizedBox(width: 10),
                              if (_canDeleteCurrent) ...[
                                GestureDetector(
                                  onTap: _deleting
                                      ? null
                                      : _confirmDeleteStory,
                                  behavior: HitTestBehavior.opaque,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: _deleting
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: AppLoading(
                                              color: AppColors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const AppIcon(
                                            AssetPaths.iconTrash,
                                            size: 22,
                                            color: AppColors.white,
                                          ),
                                  ),
                                ),
                              ],
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
                          ),
                          if (_current.hasMusic) ...[
                            const SizedBox(height: 10),
                            _StoryMusicPill(item: _current),
                          ],
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
                liked: _current.likedByMe,
                likeCount: _current.likeCount,
                showLikeCount:
                    _current.storyId != null &&
                    _current.storyId!.trim().isNotEmpty,
                canReply: _canReplyToCurrent,
                replyController: _replyController,
                replyFocus: _replyFocus,
                replySending: _replySending,
                onLike: _toggleLike,
                onProfileTap: _openProfile,
                onReplySubmit: _sendStoryReply,
              ),
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const _dismissDistance = 120.0;
  static const _dismissVelocity = 800.0;

  void _onDismissDragStart(DragStartDetails details) {
    _dragging = true;
  }

  void _onDismissDragUpdate(DragUpdateDetails details) {
    final next = _dragDy + details.delta.dy;
    final dy = next < 0 ? 0.0 : next;
    if (dy > 8 && !_pausedForDismiss) {
      _pausedForDismiss = true;
      _pause();
    }
    setState(() => _dragDy = dy);
  }

  void _snapDismissDragBack() {
    setState(() {
      _dragging = false;
      _dragDy = 0;
    });
    if (!_pausedForDismiss) return;
    _pausedForDismiss = false;
    _resume();
  }

  void _onDismissDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (_dragDy > _dismissDistance || velocity > _dismissVelocity) {
      context.pop();
      return;
    }
    _snapDismissDragBack();
  }

  void _onDismissDragCancel() => _snapDismissDragBack();

  void _onTapUp(TapUpDetails details) {
    if (_replyFocus.hasFocus) {
      _replyFocus.unfocus();
      return;
    }
    final width = MediaQuery.sizeOf(context).width;
    if (details.localPosition.dx < width * 0.35) {
      _goPrevious();
    } else if (details.localPosition.dx > width * 0.65) {
      _goNext();
    }
  }
}

@immutable
final class _StoryMusicPill extends StatelessWidget {
  const _StoryMusicPill({required this.item});

  final StoryMediaItem item;

  String get _title {
    final title = item.musicTitle?.trim() ?? '';
    if (title.isNotEmpty) return title;
    return 'Music';
  }

  String get _subtitle {
    final raw = item.musicArtist?.trim() ?? '';
    if (raw.isEmpty) return '';
    return raw
        .replaceFirst(
          RegExp(r'^(suno(\s*ai)?|udio)\s*[|\-–—:]\s*', caseSensitive: false),
          '',
        )
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final cover = item.musicCoverUrl?.trim() ?? '';
    final subtitle = _subtitle;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: 36,
          padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: cover.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: bunnySizedUrl(cover, 56),
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                        memCacheWidth: 56,
                        fadeInDuration: Duration.zero,
                        errorWidget: (_, _, _) => Image.asset(
                          AssetPaths.stamp13,
                          width: 28,
                          height: 28,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        cover.isEmpty ? AssetPaths.stamp13 : cover,
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'SF Pro',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 16 / 14,
                        letterSpacing: -0.28,
                        color: AppColors.white,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'SF Pro',
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          height: 12 / 10,
                          letterSpacing: -0.2,
                          color: Color(0xFFB3B3B3),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@immutable
final class _SegmentedProgressBar extends StatelessWidget {
  const _SegmentedProgressBar({
    required this.segmentCount,
    required this.activeIndex,
    required this.progress,
  });

  final int segmentCount;
  final int activeIndex;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < segmentCount; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: _ProgressSegment(
              progress: i < activeIndex
                  ? 1
                  : i == activeIndex
                  ? progress
                  : 0,
            ),
          ),
        ],
      ],
    );
  }
}

@immutable
final class _ProgressSegment extends StatelessWidget {
  const _ProgressSegment({required this.progress});

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

@immutable
final class _BottomOverlay extends StatelessWidget {
  const _BottomOverlay({
    required this.item,
    required this.liked,
    required this.likeCount,
    required this.showLikeCount,
    required this.canReply,
    required this.replyController,
    required this.replyFocus,
    required this.replySending,
    required this.onLike,
    required this.onProfileTap,
    required this.onReplySubmit,
  });

  final StoryMediaItem item;
  final bool liked;
  final int likeCount;
  final bool showLikeCount;
  final bool canReply;
  final TextEditingController replyController;
  final FocusNode replyFocus;
  final bool replySending;
  final VoidCallback onLike;
  final VoidCallback onProfileTap;
  final VoidCallback onReplySubmit;

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                            ProfileAvatar(path: item.avatarPath, size: 34),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                item.storyLabel,
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
                      if (item.caption.trim().isNotEmpty) ...[
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
                    ],
                  ),
                ),
                if (!canReply) ...[
                  const SizedBox(width: 12),
                  _LikeButton(
                    liked: liked,
                    likeCount: likeCount,
                    showCount: showLikeCount,
                    onLike: onLike,
                  ),
                ],
              ],
            ),
            if (canReply) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _StoryReplyField(
                      controller: replyController,
                      focusNode: replyFocus,
                      enabled: !replySending,
                      onSubmit: onReplySubmit,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _LikeButton(
                    liked: liked,
                    likeCount: likeCount,
                    showCount: showLikeCount,
                    onLike: onLike,
                  ),
                  ListenableBuilder(
                    listenable: replyController,
                    builder: (context, _) {
                      if (replyController.text.trim().isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: GestureDetector(
                          onTap: replySending ? null : onReplySubmit,
                          behavior: HitTestBehavior.opaque,
                          child: Opacity(
                            opacity: replySending ? 0.45 : 1,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.black.withValues(alpha: 0.35),
                              ),
                              alignment: Alignment.center,
                              child: const AppIcon(
                                AssetPaths.iconChatSend,
                                size: 20,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

@immutable
final class _StoryReplyField extends StatelessWidget {
  const _StoryReplyField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.black.withValues(alpha: 0.40),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            maxLines: 1,
            textInputAction: TextInputAction.send,
            cursorColor: AppColors.white,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 20 / 14,
              letterSpacing: -0.28,
              color: AppColors.white,
            ),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: 'story_send_message'.tr(),
              hintStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 20 / 14,
                letterSpacing: -0.28,
                color: AppColors.white,
              ),
              contentPadding: EdgeInsets.zero,
            ),
            onSubmitted: (_) => onSubmit(),
          ),
        ),
      ),
    );
  }
}

@immutable
final class _LikeButton extends StatefulWidget {
  const _LikeButton({
    required this.liked,
    required this.likeCount,
    required this.showCount,
    required this.onLike,
  });

  final bool liked;
  final int likeCount;
  final bool showCount;
  final VoidCallback onLike;

  @override
  State<_LikeButton> createState() => _LikeButtonState();
}

final class _LikeButtonState extends State<_LikeButton>
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
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
        ),
        if (widget.showCount) ...[
          const SizedBox(height: 4),
          Text(
            '${widget.likeCount}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1,
              letterSpacing: -0.2,
              color: AppColors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ],
    );
  }
}

@immutable
final class _FloatingHeartData {
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

@immutable
final class _FloatingHeart extends StatefulWidget {
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

final class _FloatingHeartState extends State<_FloatingHeart>
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
