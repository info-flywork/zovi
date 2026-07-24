import 'dart:math' as math;
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/core/widgets/app_search_field.dart';

class CameraMusicTrack {
  const CameraMusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.genre,
    required this.duration,
    required this.coverPath,
  });

  final String id;
  final String title;
  final String artist;
  final String genre;
  final Duration duration;
  final String coverPath;

  String get artistGenre => '$artist | $genre';
}

class CameraMusicSelection {
  const CameraMusicSelection({
    required this.track,
    required this.clipStart,
    required this.clipDuration,
  });

  final CameraMusicTrack track;
  final Duration clipStart;
  final Duration clipDuration;
}

const _mockTracks = [
  CameraMusicTrack(
    id: 'neria',
    title: 'Neria',
    artist: 'Heyson',
    genre: 'House',
    duration: Duration(minutes: 3, seconds: 13),
    coverPath: AssetPaths.stamp13,
  ),
  CameraMusicTrack(
    id: 'outside',
    title: 'Can You Come Outside to Play?',
    artist: 'Heyson',
    genre: 'House',
    duration: Duration(minutes: 3, seconds: 13),
    coverPath: AssetPaths.stamp10,
  ),
  CameraMusicTrack(
    id: 'midnight',
    title: 'Midnight Walk',
    artist: 'Heyson',
    genre: 'House',
    duration: Duration(minutes: 2, seconds: 48),
    coverPath: AssetPaths.stamp4,
  ),
  CameraMusicTrack(
    id: 'afterglow',
    title: 'Afterglow',
    artist: 'Nova',
    genre: 'Indie',
    duration: Duration(minutes: 3, seconds: 42),
    coverPath: AssetPaths.stamp1,
  ),
  CameraMusicTrack(
    id: 'soft_pulse',
    title: 'Soft Pulse',
    artist: 'Kite',
    genre: 'Electronic',
    duration: Duration(minutes: 4, seconds: 5),
    coverPath: AssetPaths.stamp7,
  ),
];

Future<CameraMusicSelection?> showCameraMusicSheet(BuildContext context) {
  return showModalBottomSheet<CameraMusicSelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black26,
    builder: (context) => const CameraMusicSheet(),
  );
}

class CameraMusicSheet extends StatefulWidget {
  const CameraMusicSheet({super.key});

  @override
  State<CameraMusicSheet> createState() => _CameraMusicSheetState();
}

class _CameraMusicSheetState extends State<CameraMusicSheet> {
  var _query = '';
  CameraMusicTrack? _trimming;

  List<CameraMusicTrack> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _mockTracks;
    return _mockTracks
        .where(
          (t) =>
              t.title.toLowerCase().contains(q) ||
              t.artist.toLowerCase().contains(q) ||
              t.genre.toLowerCase().contains(q),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final trimming = _trimming;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: trimming == null
          ? _MusicListSheet(
              tracks: _filtered,
              onQueryChanged: (value) => setState(() => _query = value),
              onSelect: (track) => setState(() => _trimming = track),
            )
          : _MusicTrimSheet(
              track: trimming,
              onBack: () => setState(() => _trimming = null),
              onSave: (selection) => Navigator.of(context).pop(selection),
            ),
    );
  }
}

class _MusicListSheet extends StatelessWidget {
  const _MusicListSheet({
    required this.tracks,
    required this.onQueryChanged,
    required this.onSelect,
  });

  final List<CameraMusicTrack> tracks;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<CameraMusicTrack> onSelect;

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
                          onDebouncedChanged: onQueryChanged,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  Expanded(
                    child: tracks.isEmpty
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
                            itemCount: tracks.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final track = tracks[index];
                              return _MusicTrackTile(
                                track: track,
                                onTap: () => onSelect(track),
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

class _MusicEmptyState extends StatelessWidget {
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

class _MusicTrackTile extends StatelessWidget {
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
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              track.coverPath,
              width: 68,
              height: 68,
              fit: BoxFit.cover,
            ),
          ),
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

class _MusicTrimSheet extends StatefulWidget {
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

class _MusicTrimSheetState extends State<_MusicTrimSheet> {
  static const _minClip = Duration(seconds: 5);

  /// Track üzerinde seçimin başlangıç/bitiş oranı (0–1).
  late double _startNorm;
  late double _endNorm;

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
  }

  void _onRangeChanged(double start, double end) {
    setState(() {
      _startNorm = start.clamp(0.0, 1.0);
      _endNorm = end.clamp(_startNorm + _minNorm, 1.0);
      if (_endNorm - _startNorm < _minNorm) {
        _startNorm = (_endNorm - _minNorm).clamp(0.0, 1.0);
      }
    });
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
                      onTap: widget.onBack,
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        track.coverPath,
                        width: 68,
                        height: 68,
                        fit: BoxFit.cover,
                      ),
                    ),
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
                  onTap: () => widget.onSave(
                    CameraMusicSelection(
                      track: track,
                      clipStart: start,
                      clipDuration: clipDuration,
                    ),
                  ),
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

class _MusicWaveformTrim extends StatefulWidget {
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

class _MusicWaveformTrimState extends State<_MusicWaveformTrim> {
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

class _TrimHandle extends StatelessWidget {
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

