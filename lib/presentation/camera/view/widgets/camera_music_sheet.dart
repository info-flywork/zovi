import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:zovi/core/cache/music_audio_cache.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/core/widgets/app_loading.dart';
import 'package:zovi/core/widgets/app_search_field.dart';
import 'package:zovi/domain/auth/auth_repository.dart';

@immutable
final class CameraMusicTrack {
  const CameraMusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.genre,
    required this.duration,
    required this.coverUrl,
    required this.audioUrl,
  });

  factory CameraMusicTrack.fromItem(MusicTrackItem item) {
    return CameraMusicTrack(
      id: item.id,
      title: item.title,
      artist: item.artist,
      genre: item.genre,
      duration: Duration(milliseconds: item.durationMs),
      coverUrl: item.coverUrl,
      audioUrl: item.audioUrl,
    );
  }

  final String id;
  final String title;
  final String artist;
  final String genre;
  final Duration duration;
  final String coverUrl;
  final String audioUrl;

  String get artistGenre {
    final g = _stripMusicProviderPrefix(genre);
    if (g.isNotEmpty) return g;
    final a = _stripMusicProviderPrefix(artist);
    if (_isGenericMusicProvider(a)) return '';
    return a;
  }

  bool get hasNetworkCover =>
      coverUrl.startsWith('http://') || coverUrl.startsWith('https://');
}

String _stripMusicProviderPrefix(String value) {
  return value
      .trim()
      .replaceFirst(
        RegExp(r'^(suno(\s*ai)?|udio)\s*[|\-–—:]\s*', caseSensitive: false),
        '',
      )
      .trim();
}

bool _isGenericMusicProvider(String value) {
  final n = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  return n.isEmpty ||
      n == 'suno' ||
      n == 'sunoai' ||
      n.startsWith('suno') ||
      n == 'udio' ||
      n == 'ai';
}

@immutable
final class CameraMusicSelection {
  const CameraMusicSelection({
    required this.track,
    required this.clipStart,
    required this.clipDuration,
  });

  final CameraMusicTrack track;
  final Duration clipStart;
  final Duration clipDuration;
}

Future<CameraMusicSelection?> showCameraMusicSheet(BuildContext context) {
  return showModalBottomSheet<CameraMusicSelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black26,
    builder: (context) => const CameraMusicSheet(),
  );
}

@immutable
final class CameraMusicSheet extends StatefulWidget {
  const CameraMusicSheet({super.key});

  @override
  State<CameraMusicSheet> createState() => _CameraMusicSheetState();
}

final class _CameraMusicSheetState extends State<CameraMusicSheet> {
  static const _pageSize = 10;

  var _query = '';
  CameraMusicTrack? _trimming;
  List<CameraMusicTrack> _tracks = const [];
  var _nextOffset = 0;
  var _hasMore = true;
  var _isLoading = true;
  var _isLoadingMore = false;
  var _hasError = false;
  var _requestId = 0;

  @override
  void initState() {
    super.initState();
    _loadTracks(reset: true);
  }

  Future<void> _loadTracks({required bool reset}) async {
    if (!reset && (!_hasMore || _isLoadingMore || _isLoading)) return;

    final requestId = ++_requestId;
    final query = _query;
    final offset = reset ? 0 : _nextOffset;
    final repo = getIt<AuthRepository>();
    final cached = repo.peekMusicTracks(
      query: query,
      offset: offset,
      limit: _pageSize,
    );

    setState(() {
      if (reset) {
        _hasError = false;
        _hasMore = true;
        _nextOffset = 0;
        if (cached != null && cached.tracks.isNotEmpty) {
          _tracks = _dedupeTracks(
            cached.tracks.map(CameraMusicTrack.fromItem),
          );
          _hasMore = cached.hasMore;
          _nextOffset = cached.nextOffset;
          _isLoading = false;
        } else {
          _isLoading = true;
        }
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      var page = await repo.fetchMusicTracks(
        query: query,
        offset: offset,
        limit: _pageSize,
      );

      // Backend may be generating in background — poll until tracks arrive
      // or expand finishes without new rows.
      var polls = 0;
      while (!reset &&
          page.tracks.isEmpty &&
          page.hasMore &&
          page.expanding &&
          polls < 40) {
        await Future<void>.delayed(const Duration(seconds: 5));
        if (!mounted || requestId != _requestId) return;
        page = await repo.fetchMusicTracks(
          query: query,
          offset: offset,
          limit: _pageSize,
        );
        polls += 1;
      }

      if (!mounted || requestId != _requestId) return;
      final mapped = page.tracks
          .map(CameraMusicTrack.fromItem)
          .toList(growable: false);
      setState(() {
        _tracks = reset
            ? _dedupeTracks(mapped)
            : _dedupeTracks([..._tracks, ...mapped]);
        _hasMore = page.hasMore;
        _nextOffset = page.nextOffset;
        _isLoading = false;
        _isLoadingMore = false;
        _hasError = false;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        if (reset && _tracks.isEmpty) {
          _hasError = true;
        }
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  /// Keeps first occurrence per id / normalized title (Suno often returns
  /// multiple clips of the same song with different durations).
  List<CameraMusicTrack> _dedupeTracks(Iterable<CameraMusicTrack> tracks) {
    final seenIds = <String>{};
    final seenTitles = <String>{};
    final out = <CameraMusicTrack>[];
    for (final track in tracks) {
      final id = track.id.trim();
      final titleKey = track.title.trim().toLowerCase();
      if (id.isNotEmpty && !seenIds.add(id)) continue;
      if (titleKey.isNotEmpty && !seenTitles.add(titleKey)) continue;
      out.add(track);
    }
    return List<CameraMusicTrack>.unmodifiable(out);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final trimming = _trimming;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: trimming == null
          ? _MusicListSheet(
              tracks: _tracks,
              isLoading: _isLoading,
              isLoadingMore: _isLoadingMore,
              hasMore: _hasMore,
              hasError: _hasError,
              onQueryChanged: (value) {
                _query = value;
                _loadTracks(reset: true);
              },
              onRetry: () => _loadTracks(reset: true),
              onLoadMore: () => _loadTracks(reset: false),
              onSelect: (track) {
                unawaited(
                  getIt<MusicAudioCache>().prefetch(
                    trackId: track.id,
                    url: track.audioUrl,
                  ),
                );
                setState(() => _trimming = track);
              },
            )
          : _MusicTrimSheet(
              track: trimming,
              onBack: () => setState(() => _trimming = null),
              onSave: (selection) => Navigator.of(context).pop(selection),
            ),
    );
  }
}

@immutable
final class _MusicListSheet extends StatefulWidget {
  const _MusicListSheet({
    required this.tracks,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.hasError,
    required this.onQueryChanged,
    required this.onRetry,
    required this.onLoadMore,
    required this.onSelect,
  });

  final List<CameraMusicTrack> tracks;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final bool hasError;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;
  final ValueChanged<CameraMusicTrack> onSelect;

  @override
  State<_MusicListSheet> createState() => _MusicListSheetState();
}

final class _MusicListSheetState extends State<_MusicListSheet> {
  ScrollController? _scrollController;

  @override
  void dispose() {
    _scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  void _attachScroll(ScrollController controller) {
    if (identical(_scrollController, controller)) return;
    _scrollController?.removeListener(_onScroll);
    _scrollController = controller;
    _scrollController?.addListener(_onScroll);
  }

  void _onScroll() {
    final controller = _scrollController;
    if (controller == null || !controller.hasClients) return;
    if (!widget.hasMore || widget.isLoadingMore || widget.isLoading) return;
    final position = controller.position;
    if (position.pixels >= position.maxScrollExtent - 120) {
      widget.onLoadMore();
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
        _attachScroll(scrollController);
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
                        const SizedBox(height: 12),
                        AppSearchField(
                          hintText: 'search'.tr(),
                          isDark: true,
                          onDebouncedChanged: widget.onQueryChanged,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  Expanded(
                    child: widget.isLoading
                        ? const AppLoading(
                            size: 28,
                            strokeWidth: 2.4,
                            color: AppColors.white,
                          )
                        : widget.hasError
                        ? Center(
                            child: TextButton(
                              onPressed: widget.onRetry,
                              child: Text(
                                'camera_music_retry'.tr(),
                                style: const TextStyle(color: AppColors.white),
                              ),
                            ),
                          )
                        : widget.tracks.isEmpty
                        ? CustomScrollView(
                            controller: scrollController,
                            physics: const ClampingScrollPhysics(),
                            slivers: const [
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: _MusicEmptyState(),
                              ),
                            ],
                          )
                        : ListView.separated(
                            controller: scrollController,
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount:
                                widget.tracks.length +
                                (widget.isLoadingMore ? 1 : 0),
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              if (index >= widget.tracks.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: AppLoading(
                                    size: 22,
                                    strokeWidth: 2.2,
                                    color: AppColors.white,
                                  ),
                                );
                              }
                              final track = widget.tracks[index];
                              return _MusicTrackTile(
                                track: track,
                                onTap: () => widget.onSelect(track),
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
final class _MusicEmptyState extends StatelessWidget {
  const _MusicEmptyState();

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
            'camera_music_empty_search'.tr(),
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

@immutable
final class _MusicTrackCover extends StatelessWidget {
  const _MusicTrackCover({required this.track});

  final CameraMusicTrack track;

  @override
  Widget build(BuildContext context) {
    const size = 68.0;
    final fallback = Image.asset(
      AssetPaths.stamp13,
      width: size,
      height: size,
      fit: BoxFit.cover,
    );

    if (!track.hasNetworkCover) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: fallback,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        track.coverUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

@immutable
final class _MusicTrackTile extends StatelessWidget {
  const _MusicTrackTile({required this.track, required this.onTap});

  final CameraMusicTrack track;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          _MusicTrackCover(track: track),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'SF Pro',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 22 / 16,
                    letterSpacing: -0.32,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  track.artistGenre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'SF Pro',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 22 / 14,
                    letterSpacing: -0.28,
                    color: Color(0xFFB3B3B3),
                  ),
                ),
                Text(
                  _formatDuration(track.duration),
                  style: const TextStyle(
                    fontFamily: 'SF Pro',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 22 / 14,
                    letterSpacing: -0.28,
                    color: Color(0xFFB3B3B3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

@immutable
final class _MusicTrimSheet extends StatefulWidget {
  const _MusicTrimSheet({
    required this.track,
    required this.onBack,
    required this.onSave,
  });

  final CameraMusicTrack track;
  final VoidCallback onBack;
  final ValueChanged<CameraMusicSelection> onSave;

  @override
  State<_MusicTrimSheet> createState() => _MusicTrimSheetState();
}

final class _MusicTrimSheetState extends State<_MusicTrimSheet> {
  static const _minClip = Duration(seconds: 5);

  /// Track üzerinde seçimin başlangıç/bitiş oranı (0–1).
  late double _startNorm;
  late double _endNorm;

  final _player = AudioPlayer();
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<void>? _completeSub;
  var _seeking = false;
  var _sourceReady = false;
  Timer? _rangeDebounce;

  Duration get _clipStart => Duration(
    milliseconds: (_startNorm * widget.track.duration.inMilliseconds).round(),
  );

  Duration get _clipEnd => Duration(
    milliseconds: (_endNorm * widget.track.duration.inMilliseconds).round(),
  );

  Duration get _clipDuration => _clipEnd - _clipStart;

  double get _minNorm {
    final total = widget.track.duration.inMilliseconds;
    if (total <= 0) return 0.1;
    return (_minClip.inMilliseconds / total).clamp(0.05, 1.0);
  }

  @override
  void initState() {
    super.initState();
    final total = widget.track.duration.inMilliseconds;
    final preferred = const Duration(seconds: 30).inMilliseconds;
    final clipMs = math.min(preferred, total).toDouble();
    final startMs = math.min(
      preferred.toDouble(),
      math.max(0, total - clipMs),
    );
    _startNorm = total == 0 ? 0 : startMs / total;
    _endNorm = total == 0 ? 1 : (startMs + clipMs) / total;
    unawaited(_startPreview());
  }

  @override
  void dispose() {
    _rangeDebounce?.cancel();
    unawaited(_tearDownPlayer());
    super.dispose();
  }

  Future<void> _tearDownPlayer() async {
    await _positionSub?.cancel();
    await _completeSub?.cancel();
    _positionSub = null;
    _completeSub = null;
    try {
      await _player.stop();
    } catch (_) {}
    try {
      await _player.dispose();
    } catch (_) {}
  }

  Future<void> _startPreview() async {
    final url = widget.track.audioUrl.trim();
    if (url.isEmpty) return;

    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      final source = await getIt<MusicAudioCache>().resolveSource(
        trackId: widget.track.id,
        url: url,
      );
      await _player.setSource(source);
      _sourceReady = true;

      _positionSub = _player.onPositionChanged.listen((pos) async {
        if (_seeking || !mounted) return;
        if (pos < _clipEnd) return;
        _seeking = true;
        try {
          await _player.seek(_clipStart);
        } finally {
          _seeking = false;
        }
      });

      _completeSub = _player.onPlayerComplete.listen((_) async {
        if (_seeking || !mounted) return;
        _seeking = true;
        try {
          await _player.seek(_clipStart);
          await _player.resume();
        } finally {
          _seeking = false;
        }
      });

      await _player.seek(_clipStart);
      await _player.resume();
    } catch (_) {
      _sourceReady = false;
    }
  }

  Future<void> _seekToClipStart() async {
    if (!_sourceReady) return;
    _seeking = true;
    try {
      await _player.seek(_clipStart);
      final state = _player.state;
      if (state != PlayerState.playing) {
        await _player.resume();
      }
    } catch (_) {
      // ignore preview seek errors
    } finally {
      _seeking = false;
    }
  }

  void _onRangeChanged(double start, double end) {
    final previousStart = _startNorm;
    setState(() {
      _startNorm = start.clamp(0.0, 1.0);
      _endNorm = end.clamp(_startNorm + _minNorm, 1.0);
      if (_endNorm - _startNorm < _minNorm) {
        _startNorm = (_endNorm - _minNorm).clamp(0.0, 1.0);
      }
    });

    // Sadece clip başlangıcı değişince başa sar; bitiş sürüklenince devam etsin.
    final startChanged = (_startNorm - previousStart).abs() > 0.0005;
    if (!startChanged) return;

    _rangeDebounce?.cancel();
    _rangeDebounce = Timer(const Duration(milliseconds: 120), () {
      unawaited(_seekToClipStart());
    });
  }

  Future<void> _handleBack() async {
    try {
      await _player.stop();
    } catch (_) {}
    widget.onBack();
  }

  Future<void> _handleSave() async {
    final selection = CameraMusicSelection(
      track: widget.track,
      clipStart: _clipStart,
      clipDuration: _clipDuration,
    );
    try {
      await _player.stop();
    } catch (_) {}
    widget.onSave(selection);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final track = widget.track;
    final start = _clipStart;
    final end = _clipEnd;
    final clipDuration = _clipDuration;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            color: const Color(0xE6000000),
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 55,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.progressInactive,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _handleBack,
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: AppIcon(
                          AssetPaths.iconArrowLeft,
                          size: 24,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    _MusicTrackCover(track: track),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'SF Pro',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 22 / 16,
                              letterSpacing: -0.32,
                              color: AppColors.white,
                            ),
                          ),
                          Text(
                            track.artistGenre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'SF Pro',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 22 / 14,
                              letterSpacing: -0.28,
                              color: Color(0xFFB3B3B3),
                            ),
                          ),
                          Text(
                            '${_formatDuration(start)} – ${_formatDuration(end)}  ·  ${_formatDuration(clipDuration)} / ${_formatDuration(track.duration)}',
                            style: const TextStyle(
                              fontFamily: 'SF Pro',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 22 / 14,
                              letterSpacing: -0.28,
                              color: Color(0xFFB3B3B3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _MusicWaveformTrim(
                  startNorm: _startNorm,
                  endNorm: _endNorm,
                  minNorm: _minNorm,
                  onChanged: _onRangeChanged,
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _handleSave,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      'camera_music_save'.tr(),
                      style: const TextStyle(
                        fontFamily: 'SF Pro',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        height: 48 / 20,
                        letterSpacing: -0.4,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _TrimDragKind { none, move, start, end }

@immutable
final class _MusicWaveformTrim extends StatefulWidget {
  const _MusicWaveformTrim({
    required this.startNorm,
    required this.endNorm,
    required this.minNorm,
    required this.onChanged,
  });

  final double startNorm;
  final double endNorm;
  final double minNorm;
  final void Function(double start, double end) onChanged;

  @override
  State<_MusicWaveformTrim> createState() => _MusicWaveformTrimState();
}

final class _MusicWaveformTrimState extends State<_MusicWaveformTrim> {
  static const _handleHit = 28.0;

  static const _heights = [
    0.35, 0.55, 0.42, 0.78, 0.50, 0.90, 0.62, 0.40, 0.72, 0.48,
    0.85, 0.58, 0.36, 0.70, 0.92, 0.45, 0.66, 0.80, 0.52, 0.38,
    0.74, 0.60, 0.88, 0.44, 0.68, 0.56, 0.82, 0.46, 0.64, 0.76,
    0.50, 0.90, 0.42, 0.70, 0.58, 0.84, 0.48, 0.62, 0.78, 0.40,
    0.72, 0.54, 0.86, 0.46, 0.66, 0.80, 0.52, 0.74, 0.60, 0.88,
  ];

  var _dragKind = _TrimDragKind.none;
  double _dragStartNorm = 0;
  double _dragEndNorm = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final left = widget.startNorm * width;
        final right = widget.endNorm * width;
        final windowWidth = math.max(0.0, right - left);

        return GestureDetector(
          onHorizontalDragStart: (details) {
            final x = details.localPosition.dx;
            _dragStartNorm = widget.startNorm;
            _dragEndNorm = widget.endNorm;
            if ((x - left).abs() <= _handleHit) {
              _dragKind = _TrimDragKind.start;
            } else if ((x - right).abs() <= _handleHit) {
              _dragKind = _TrimDragKind.end;
            } else if (x >= left && x <= right) {
              _dragKind = _TrimDragKind.move;
            } else {
              _dragKind = _TrimDragKind.none;
            }
          },
          onHorizontalDragUpdate: (details) {
            if (_dragKind == _TrimDragKind.none || width <= 0) return;
            final dxNorm = details.delta.dx / width;
            switch (_dragKind) {
              case _TrimDragKind.start:
                final nextStart = (_dragStartNorm + dxNorm).clamp(
                  0.0,
                  _dragEndNorm - widget.minNorm,
                );
                _dragStartNorm = nextStart;
                widget.onChanged(nextStart, _dragEndNorm);
              case _TrimDragKind.end:
                final nextEnd = (_dragEndNorm + dxNorm).clamp(
                  _dragStartNorm + widget.minNorm,
                  1.0,
                );
                _dragEndNorm = nextEnd;
                widget.onChanged(_dragStartNorm, nextEnd);
              case _TrimDragKind.move:
                final span = _dragEndNorm - _dragStartNorm;
                var nextStart = _dragStartNorm + dxNorm;
                var nextEnd = _dragEndNorm + dxNorm;
                if (nextStart < 0) {
                  nextStart = 0;
                  nextEnd = span;
                } else if (nextEnd > 1) {
                  nextEnd = 1;
                  nextStart = 1 - span;
                }
                _dragStartNorm = nextStart;
                _dragEndNorm = nextEnd;
                widget.onChanged(nextStart, nextEnd);
              case _TrimDragKind.none:
                break;
            }
          },
          onHorizontalDragEnd: (_) => _dragKind = _TrimDragKind.none,
          onHorizontalDragCancel: () => _dragKind = _TrimDragKind.none,
          child: SizedBox(
            height: 56,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Row(
                  children: [
                    for (var i = 0; i < _heights.length; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: Align(
                            alignment: Alignment.center,
                            child: FractionallySizedBox(
                              heightFactor: _heights[i],
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: _isInWindow(i, left, windowWidth, width)
                                      ? AppColors.white
                                      : AppColors.white.withValues(alpha: 0.28),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                                child: const SizedBox.expand(),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Positioned(
                  left: left,
                  width: windowWidth,
                  top: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.white, width: 2),
                    ),
                    child: Row(
                      children: [
                        _TrimHandle(),
                        const Spacer(),
                        _TrimHandle(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isInWindow(int index, double left, double windowWidth, double width) {
    final barCenter = (index + 0.5) / _heights.length * width;
    return barCenter >= left && barCenter <= left + windowWidth;
  }
}

@immutable
final class _TrimHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      alignment: Alignment.center,
      child: Container(
        width: 3,
        height: 22,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

String _formatDuration(Duration value) {
  final minutes = value.inMinutes;
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
