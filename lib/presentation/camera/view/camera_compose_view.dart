import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:zovi/core/cache/music_audio_cache.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/in_app_notification/app_in_app_notification.dart';
import 'package:zovi/core/in_app_notification/in_app_notification_data.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/widgets/app_confirm_dialog.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/core/widgets/app_loading.dart';
import 'package:zovi/core/widgets/stamp_image.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/camera/model/camera_compose_route_args.dart';
import 'package:zovi/presentation/camera/utils/camera_drafts.dart';
import 'package:zovi/presentation/camera/view/widgets/camera_music_sheet.dart';
import 'package:zovi/presentation/camera/view/widgets/camera_text_editor_sheet.dart';
import 'package:zovi/presentation/chat/view/widgets/chat_sticker_sheet.dart';
import 'package:zovi/presentation/home/bloc/home_bloc.dart';
import 'package:zovi/presentation/home/bloc/home_event.dart';

enum _ComposeAudience { friendsOnly, public }

enum _DragKind { none, text, stamp }

class _ComposeTextItem {
  _ComposeTextItem({
    required this.id,
    required this.draft,
    this.alignment = const Alignment(0, -0.25),
  });

  final String id;
  CameraTextDraft draft;
  Alignment alignment;
  double scale = 1;
  double rotation = 0;
}

class _ComposeStampItem {
  _ComposeStampItem({
    required this.id,
    required this.stamp,
    this.alignment = const Alignment(0.72, 0.42),
  });

  final String id;
  final StampItem stamp;
  Alignment alignment;
  double scale = 1;
  double rotation = 0;
}

class CameraComposeView extends StatefulWidget {
  const CameraComposeView({required this.args, super.key});

  final CameraComposeRouteArgs args;

  @override
  State<CameraComposeView> createState() => _CameraComposeViewState();
}

class _CameraComposeViewState extends State<CameraComposeView> {
  final _stageKey = GlobalKey();
  final _composeKey = GlobalKey();
  final _musicPlayer = AudioPlayer();
  StreamSubscription<Duration>? _musicPositionSub;
  StreamSubscription<void>? _musicCompleteSub;
  var _musicSeeking = false;
  var _saving = false;
  var _audience = _ComposeAudience.friendsOnly;
  final List<_ComposeTextItem> _texts = [];
  final List<_ComposeStampItem> _stamps = [];
  CameraMusicSelection? _selectedMusic;
  var _dragKind = _DragKind.none;
  String? _draggingTextId;
  String? _draggingStampId;
  var _overDelete = false;
  var _toolsExpanded = true;
  var _gestureMoved = false;
  double? _gestureStartScale;
  double? _gestureStartRotation;

  /// True after the user adds/edits text, stamps, music, audience, or transforms.
  var _hasEdits = false;

  CameraComposeRouteArgs get args => widget.args;

  void _markEdited() {
    if (_hasEdits) return;
    _hasEdits = true;
  }

  @override
  void dispose() {
    unawaited(_stopMusicPreview());
    unawaited(_musicPlayer.dispose());
    super.dispose();
  }

  bool get _isDragging => _dragKind != _DragKind.none;

  _ComposeTextItem? _textById(String id) {
    for (final item in _texts) {
      if (item.id == id) return item;
    }
    return null;
  }

  _ComposeStampItem? _stampById(String id) {
    for (final item in _stamps) {
      if (item.id == id) return item;
    }
    return null;
  }

  void _showBanner({
    required String titleKey,
    String? subtitleKey,
    required String icon,
  }) {
    AppInAppNotification.instance.show(
      InAppNotificationData(
        username: '',
        messageKey: titleKey,
        subtitleKey: subtitleKey,
        avatarPath: AssetPaths.avatarYou,
        leadingIconPath: icon,
        useFullTitle: true,
      ),
      alignment: Alignment.topCenter,
    );
  }

  Future<Uint8List?> _captureComposeBytes() async {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context).clamp(2.0, 3.0);
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return null;

    final boundary =
        _composeKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return null;

    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes?.buffer.asUint8List();
  }

  Future<void> _saveToGallery() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final permission = await PhotoManager.requestPermissionExtend(
        requestOption: const PermissionRequestOption(
          iosAccessLevel: IosAccessLevel.readWrite,
        ),
      );
      if (!permission.hasAccess) {
        if (!mounted) return;
        _showBanner(
          titleKey: 'camera_compose_save_permission',
          subtitleKey: 'camera_compose_save_permission_subtitle',
          icon: AssetPaths.iconImportArrow,
        );
        return;
      }

      final bytes = await _captureComposeBytes();
      if (bytes == null || bytes.isEmpty) {
        throw StateError('capture failed');
      }

      final filename = 'zovi_${DateTime.now().millisecondsSinceEpoch}.png';
      await PhotoManager.editor.saveImage(bytes, filename: filename);

      if (!mounted) return;
      _showBanner(
        titleKey: 'camera_compose_saved',
        subtitleKey: 'camera_compose_saved_subtitle',
        icon: AssetPaths.iconImportArrow,
      );
    } catch (_) {
      if (!mounted) return;
      _showBanner(
        titleKey: 'camera_compose_save_failed',
        subtitleKey: 'camera_compose_save_failed_subtitle',
        icon: AssetPaths.iconImportArrow,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveAsDraft() async {
    final bytes = await _captureComposeBytes();
    if (bytes == null || bytes.isEmpty) {
      throw StateError('capture failed');
    }
    await CameraDrafts.saveRemote(bytes);
  }

  Future<void> _onClosePressed() async {
    // Re-opening an unchanged draft shouldn't ask to save it again.
    final needsSavePrompt = !args.fromDraft || _hasEdits;
    if (!needsSavePrompt) {
      if (mounted) context.pop();
      return;
    }

    final shouldSave = await showAppConfirmDialog(
      context,
      title: 'camera_compose_save_draft_title'.tr(),
      subtitle: 'camera_compose_save_draft_subtitle'.tr(),
      confirmLabel: 'camera_compose_save_draft_confirm'.tr(),
    );
    if (!mounted) return;

    if (shouldSave) {
      setState(() => _saving = true);
      try {
        await _saveAsDraft();
        if (!mounted) return;
        _showBanner(
          titleKey: 'camera_compose_draft_saved',
          subtitleKey: 'camera_compose_draft_saved_subtitle',
          icon: AssetPaths.iconImportArrow,
        );
      } catch (_) {
        if (!mounted) return;
        _showBanner(
          titleKey: 'camera_compose_save_failed',
          subtitleKey: 'camera_compose_save_failed_subtitle',
          icon: AssetPaths.iconImportArrow,
        );
        setState(() => _saving = false);
        return;
      }
      if (mounted) setState(() => _saving = false);
    }

    if (mounted) context.pop();
  }

  Future<void> _shareStory() async {
    if (_saving) return;
    setState(() => _saving = true);
    File? tempFile;
    try {
      final bytes = await _captureComposeBytes();
      if (bytes == null || bytes.isEmpty) {
        _showBanner(
          titleKey: 'camera_compose_save_failed',
          subtitleKey: 'camera_compose_save_failed_subtitle',
          icon: AssetPaths.iconImportArrow,
        );
        return;
      }

      final dir = await getTemporaryDirectory();
      tempFile = File(
        '${dir.path}/story_share_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await tempFile.writeAsBytes(bytes, flush: true);

      final music = _selectedMusic;
      await getIt<UserRepository>().publishStory(
        imagePath: tempFile.path,
        audience: _audience == _ComposeAudience.public
            ? 'public'
            : 'friends_only',
        musicTrackId: music?.track.id,
        musicClipStartMs: music?.clipStart.inMilliseconds,
        musicClipDurationMs: music?.clipDuration.inMilliseconds,
      );

      if (!mounted) return;
      await _stopMusicPreview();
      if (!mounted) return;
      _showBanner(
        titleKey: 'camera_compose_shared',
        subtitleKey: 'camera_compose_shared_subtitle',
        icon: AssetPaths.iconSendPlane,
      );
      getIt<HomeBloc>().add(const HomeStoriesRefreshRequested());
      context.go(RoutePaths.home.path);
    } catch (_) {
      if (!mounted) return;
      _showBanner(
        titleKey: 'camera_compose_share_failed',
        subtitleKey: 'camera_compose_share_failed_subtitle',
        icon: AssetPaths.iconImportArrow,
      );
    } finally {
      try {
        await tempFile?.delete();
      } catch (_) {}
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toggleAudience() {
    setState(() {
      _audience = _audience == _ComposeAudience.friendsOnly
          ? _ComposeAudience.public
          : _ComposeAudience.friendsOnly;
    });
    _markEdited();
  }

  Future<void> _openTextEditor({Alignment? at, String? editId}) async {
    final existing = editId == null ? null : _textById(editId);
    final result = await showCameraTextEditorSheet(
      context,
      initial: existing?.draft ?? const CameraTextDraft(),
    );
    if (!mounted || result == null) return;

    setState(() {
      if (!result.hasContent) {
        if (editId != null) {
          _texts.removeWhere((item) => item.id == editId);
          _markEdited();
        }
        return;
      }

      if (existing != null) {
        existing.draft = result;
        _markEdited();
        return;
      }

      _texts.add(
        _ComposeTextItem(
          id: 'text_${DateTime.now().microsecondsSinceEpoch}',
          draft: result,
          alignment: at ?? const Alignment(0, -0.25),
        ),
      );
      _markEdited();
    });
  }

  void _onStageTapUp(TapUpDetails details) {
    if (_isDragging) return;
    final box = _stageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final local = box.globalToLocal(details.globalPosition);
    final size = box.size;
    if (!size.contains(local)) return;

    final align = Alignment(
      ((local.dx / size.width) * 2 - 1).clamp(-1.0, 1.0),
      ((local.dy / size.height) * 2 - 1).clamp(-1.0, 1.0),
    );
    _openTextEditor(at: align);
  }

  Future<void> _openStampSheet() async {
    final stamp = await showChatStickerSheet(
      context,
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.8,
    );
    if (!mounted || stamp == null) return;
    setState(() {
      final offset = (_stamps.length % 5) * 0.08;
      _stamps.add(
        _ComposeStampItem(
          id: 'stamp_${DateTime.now().microsecondsSinceEpoch}',
          stamp: stamp,
          alignment: Alignment(
            (0.72 - offset).clamp(-1.0, 1.0),
            (0.42 - offset).clamp(-1.0, 1.0),
          ),
        ),
      );
    });
    _markEdited();
  }

  Future<void> _openMusicSheet() async {
    await _stopMusicPreview();
    if (!mounted) return;
    final selection = await showCameraMusicSheet(context);
    if (!mounted || selection == null) return;
    setState(() => _selectedMusic = selection);
    _markEdited();
    await _playMusicSelection(selection);
  }

  Future<void> _clearSelectedMusic() async {
    await _stopMusicPreview();
    if (!mounted) return;
    setState(() => _selectedMusic = null);
    _markEdited();
  }

  Future<void> _stopMusicPreview() async {
    await _musicPositionSub?.cancel();
    await _musicCompleteSub?.cancel();
    _musicPositionSub = null;
    _musicCompleteSub = null;
    _musicSeeking = false;
    try {
      await _musicPlayer.stop();
    } catch (_) {}
  }

  Future<void> _playMusicSelection(CameraMusicSelection selection) async {
    await _stopMusicPreview();
    final start = selection.clipStart;
    final end = start + selection.clipDuration;
    final url = selection.track.audioUrl.trim();
    if (url.isEmpty) return;

    await _musicPlayer.setReleaseMode(ReleaseMode.stop);

    _musicPositionSub = _musicPlayer.onPositionChanged.listen((pos) async {
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

    try {
      final source = await getIt<MusicAudioCache>().resolveSource(
        trackId: selection.track.id,
        url: url,
      );
      await _musicPlayer.play(source, position: start);
    } catch (_) {
      await _stopMusicPreview();
    }
  }

  void _startTextGesture(String id) {
    final item = _textById(id);
    if (item == null) return;
    HapticFeedback.selectionClick();
    _dragKind = _DragKind.text;
    _draggingTextId = id;
    _draggingStampId = null;
    _overDelete = false;
    _gestureMoved = false;
    _gestureStartScale = item.scale;
    _gestureStartRotation = item.rotation;
    setState(() {});
  }

  void _startStampGesture(String id) {
    final item = _stampById(id);
    if (item == null) return;
    HapticFeedback.selectionClick();
    _dragKind = _DragKind.stamp;
    _draggingStampId = id;
    _draggingTextId = null;
    _overDelete = false;
    _gestureMoved = false;
    _gestureStartScale = item.scale;
    _gestureStartRotation = item.rotation;
    setState(() {});
  }

  void _updateGesture(ScaleUpdateDetails details) {
    final startScale = _gestureStartScale;
    final startRotation = _gestureStartRotation;
    final box = _stageKey.currentContext?.findRenderObject() as RenderBox?;
    if (startScale == null ||
        startRotation == null ||
        box == null ||
        _dragKind == _DragKind.none) {
      return;
    }

    final moved =
        details.focalPointDelta.distance > 0.8 ||
        (details.scale - 1).abs() > 0.01 ||
        details.rotation.abs() > 0.01;
    if (moved) {
      _gestureMoved = true;
      _markEdited();
    }

    final size = box.size;
    final dx = details.focalPointDelta.dx / (size.width / 2);
    final dy = details.focalPointDelta.dy / (size.height / 2);

    final nextScale = (startScale * details.scale).clamp(0.35, 4.0);
    final nextRotation = startRotation + details.rotation;

    final local = box.globalToLocal(details.focalPoint);
    final deleteRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height - 96),
      width: 88,
      height: 88,
    );
    final overDelete = deleteRect.contains(local);

    setState(() {
      if (_dragKind == _DragKind.text) {
        final item = _draggingTextId == null
            ? null
            : _textById(_draggingTextId!);
        if (item != null) {
          item.alignment = Alignment(
            (item.alignment.x + dx).clamp(-1.15, 1.15),
            (item.alignment.y + dy).clamp(-1.15, 1.15),
          );
          item.scale = nextScale;
          item.rotation = nextRotation;
        }
      } else if (_dragKind == _DragKind.stamp) {
        final item = _draggingStampId == null
            ? null
            : _stampById(_draggingStampId!);
        if (item != null) {
          item.alignment = Alignment(
            (item.alignment.x + dx).clamp(-1.15, 1.15),
            (item.alignment.y + dy).clamp(-1.15, 1.15),
          );
          item.scale = nextScale;
          item.rotation = nextRotation;
        }
      }
      if (overDelete != _overDelete) {
        HapticFeedback.selectionClick();
        _overDelete = overDelete;
      }
    });
  }

  void _endGesture({bool cancelled = false}) {
    final wasTap = !cancelled && !_gestureMoved && _dragKind == _DragKind.text;
    final editId = _draggingTextId;
    final shouldDelete = !cancelled && _overDelete;

    if (shouldDelete) {
      HapticFeedback.heavyImpact();
      _markEdited();
      setState(() {
        if (_dragKind == _DragKind.text && _draggingTextId != null) {
          _texts.removeWhere((item) => item.id == _draggingTextId);
        } else if (_dragKind == _DragKind.stamp && _draggingStampId != null) {
          _stamps.removeWhere((item) => item.id == _draggingStampId);
        }
        _dragKind = _DragKind.none;
        _draggingTextId = null;
        _draggingStampId = null;
        _overDelete = false;
        _gestureMoved = false;
        _gestureStartScale = null;
        _gestureStartRotation = null;
      });
      return;
    }

    setState(() {
      _dragKind = _DragKind.none;
      _draggingTextId = null;
      _draggingStampId = null;
      _overDelete = false;
      _gestureMoved = false;
      _gestureStartScale = null;
      _gestureStartRotation = null;
    });

    if (wasTap && editId != null) {
      _openTextEditor(editId: editId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final isPublic = _audience == _ComposeAudience.public;
    final hideChrome = _isDragging;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop || _saving) return;
          _onClosePressed();
        },
        child: Scaffold(
          backgroundColor: AppColors.black,
          resizeToAvoidBottomInset: false,
          body: Stack(
            key: _stageKey,
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  key: _composeKey,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fill(
                        child: args.isAsset
                            ? Image.asset(args.imagePath, fit: BoxFit.cover)
                            : Image.file(
                                File(args.imagePath),
                                fit: BoxFit.cover,
                              ),
                      ),
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapUp: _onStageTapUp,
                        ),
                      ),
                      ..._stamps.map((item) {
                        final dragging =
                            _dragKind == _DragKind.stamp &&
                            _draggingStampId == item.id;
                        return Align(
                          key: ValueKey(item.id),
                          alignment: item.alignment,
                          child: _DraggableComposeItem(
                            dragging: dragging,
                            shrinking: dragging && _overDelete,
                            scale: item.scale,
                            rotation: item.rotation,
                            onScaleStart: (_) => _startStampGesture(item.id),
                            onScaleUpdate: _updateGesture,
                            onScaleEnd: (_) => _endGesture(),
                            child: StampImage(
                              path: item.stamp.imagePath,
                              stampId: item.stamp.id,
                              width: 96,
                              height: 96,
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                      }),
                      ..._texts.map((item) {
                        final dragging =
                            _dragKind == _DragKind.text &&
                            _draggingTextId == item.id;
                        return Align(
                          key: ValueKey(item.id),
                          alignment: item.alignment,
                          child: _DraggableComposeItem(
                            dragging: dragging,
                            shrinking: dragging && _overDelete,
                            scale: item.scale,
                            rotation: item.rotation,
                            onScaleStart: (_) => _startTextGesture(item.id),
                            onScaleUpdate: _updateGesture,
                            onScaleEnd: (_) => _endGesture(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                                maxWidth:
                                    MediaQuery.sizeOf(context).width * 0.85,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  item.draft.displayText,
                                  textAlign: item.draft.align,
                                  style: item.draft.textStyle,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              if (_isDragging)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 48 + bottomInset),
                    child: _DeleteDropZone(active: _overDelete),
                  ),
                ),
              IgnorePointer(
                ignoring: hideChrome,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: hideChrome ? 0 : 1,
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: _saving ? null : _onClosePressed,
                                behavior: HitTestBehavior.opaque,
                                child: const AppIcon(
                                  AssetPaths.iconCloose,
                                  size: 32,
                                ),
                              ),
                              if (_selectedMusic != null) ...[
                                const SizedBox(width: 10),
                                _SelectedMusicPill(
                                  selection: _selectedMusic!,
                                  onClear: _clearSelectedMusic,
                                ),
                              ],
                              const Spacer(),
                              SizedBox(
                                width: 44,
                                child: Column(
                                  children: [
                                    _ToolIcon(
                                      asset: AssetPaths.iconSetting,
                                      onTap: () {
                                        setState(
                                          () =>
                                              _toolsExpanded = !_toolsExpanded,
                                        );
                                      },
                                    ),
                                    ClipRect(
                                      child: TweenAnimationBuilder<double>(
                                        tween: Tween<double>(
                                          end: _toolsExpanded ? 1 : 0,
                                        ),
                                        duration: const Duration(
                                          milliseconds: 280,
                                        ),
                                        curve: Curves.easeOutCubic,
                                        builder: (context, value, child) {
                                          return Align(
                                            alignment: Alignment.topCenter,
                                            heightFactor: value,
                                            widthFactor: 1,
                                            child: Opacity(
                                              opacity: value.clamp(0.0, 1.0),
                                              child: child,
                                            ),
                                          );
                                        },
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const SizedBox(height: 20),
                                            _ToolIcon(
                                              asset: AssetPaths.iconTextAa,
                                              onTap: () => _openTextEditor(),
                                            ),
                                            const SizedBox(height: 20),
                                            _ToolIcon(
                                              asset: AssetPaths.iconSticker,
                                              onTap: _openStampSheet,
                                            ),
                                            const SizedBox(height: 20),
                                            _ToolIcon(
                                              asset: AssetPaths.iconMusicNote,
                                              onTap: _openMusicSheet,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        ClipRect(
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              width: double.infinity,
                              color: AppColors.black.withValues(alpha: 0.70),
                              padding: EdgeInsets.fromLTRB(
                                16,
                                16,
                                16,
                                16 + bottomInset,
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: _saving ? null : _saveToGallery,
                                    behavior: HitTestBehavior.opaque,
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.black.withValues(
                                          alpha: 0.50,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: _saving
                                          ? const AppLoading(
                                              size: 18,
                                              strokeWidth: 2,
                                              color: AppColors.white,
                                              centered: false,
                                            )
                                          : const AppIcon(
                                              AssetPaths.iconImportArrow,
                                              size: 24,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: _toggleAudience,
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        height: 44,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.black.withValues(
                                            alpha: 0.40,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            9999,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 280,
                                          ),
                                          switchInCurve: Curves.easeOutCubic,
                                          switchOutCurve: Curves.easeInCubic,
                                          transitionBuilder:
                                              (child, animation) {
                                                final offset = Tween<Offset>(
                                                  begin: const Offset(0, 0.35),
                                                  end: Offset.zero,
                                                ).animate(animation);
                                                return FadeTransition(
                                                  opacity: animation,
                                                  child: SlideTransition(
                                                    position: offset,
                                                    child: child,
                                                  ),
                                                );
                                              },
                                          child: Row(
                                            key: ValueKey(_audience),
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              AppIcon(
                                                isPublic
                                                    ? AssetPaths.iconPublic
                                                    : AssetPaths.iconAiUsers,
                                                size: 24,
                                                color: AppColors.white,
                                              ),
                                              const SizedBox(width: 10),
                                              Flexible(
                                                child: Text(
                                                  isPublic
                                                      ? 'camera_compose_public'
                                                            .tr()
                                                      : 'camera_compose_friends_only'
                                                            .tr(),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                    height: 1,
                                                    letterSpacing: -0.32,
                                                    color: AppColors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: _saving ? null : _shareStory,
                                    behavior: HitTestBehavior.opaque,
                                    child: Container(
                                      height: 44,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.zoviOrange,
                                        borderRadius: BorderRadius.circular(
                                          9999,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'camera_compose_share'.tr(),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              height: 1,
                                              letterSpacing: -0.32,
                                              color: AppColors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          const AppIcon(
                                            AssetPaths.iconSendPlane,
                                            size: 24,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DraggableComposeItem extends StatelessWidget {
  const _DraggableComposeItem({
    required this.child,
    required this.dragging,
    required this.shrinking,
    required this.scale,
    required this.rotation,
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onScaleEnd,
  });

  final Widget child;
  final bool dragging;
  final bool shrinking;
  final double scale;
  final double rotation;
  final GestureScaleStartCallback onScaleStart;
  final GestureScaleUpdateCallback onScaleUpdate;
  final GestureScaleEndCallback onScaleEnd;

  @override
  Widget build(BuildContext context) {
    final visualScale = scale * (shrinking ? 0.55 : (dragging ? 1.04 : 1));
    // Transform dışarıda olmalı: hit-test görsel boyuta göre çalışsın,
    // büyüttükten sonra tekrar pinch yakalanabilsin.
    return Transform.rotate(
      angle: rotation,
      child: Transform.scale(
        scale: visualScale,
        child: GestureDetector(
          onScaleStart: onScaleStart,
          onScaleUpdate: onScaleUpdate,
          onScaleEnd: onScaleEnd,
          behavior: HitTestBehavior.translucent,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 140),
            opacity: shrinking ? 0.45 : 1,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _DeleteDropZone extends StatelessWidget {
  const _DeleteDropZone({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: active ? 72 : 56,
      height: active ? 72 : 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? AppColors.logoutRed
            : AppColors.black.withValues(alpha: 0.55),
        border: Border.all(
          color: AppColors.white.withValues(alpha: active ? 0.9 : 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (active ? AppColors.logoutRed : AppColors.black).withValues(
              alpha: 0.35,
            ),
            blurRadius: 18,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: AppIcon(
        AssetPaths.iconTrash,
        size: active ? 28 : 24,
        color: AppColors.white,
      ),
    );
  }
}

class _SelectedMusicPill extends StatelessWidget {
  const _SelectedMusicPill({required this.selection, required this.onClear});

  final CameraMusicSelection selection;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final track = selection.track;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: 36,
          padding: const EdgeInsets.fromLTRB(4, 4, 6, 4),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: track.coverUrl.startsWith('http')
                    ? Image.network(
                        track.coverUrl,
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Image.asset(
                          AssetPaths.stamp13,
                          width: 28,
                          height: 28,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        track.coverUrl.isEmpty
                            ? AssetPaths.stamp13
                            : track.coverUrl,
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
                    _MarqueeText(
                      text: track.title,
                      style: const TextStyle(
                        fontFamily: 'SF Pro',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 16 / 14,
                        letterSpacing: -0.28,
                        color: AppColors.white,
                      ),
                    ),
                    _MarqueeText(
                      text: track.artistGenre,
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
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onClear,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: AppIcon(
                    AssetPaths.iconCloooose,
                    size: 16,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarqueeText extends StatefulWidget {
  const _MarqueeText({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  static const _gap = 32.0;
  static const _speedPxPerSec = 24.0;

  late final AnimationController _controller;
  double _textWidth = 0;
  double _viewportWidth = 0;

  double get _lineHeight {
    final size = widget.style.fontSize ?? 14;
    final height = widget.style.height ?? 1;
    return size * height;
  }

  bool get _overflows =>
      _viewportWidth > 0 && _textWidth > _viewportWidth + 0.5;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(covariant _MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.style != widget.style) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(_syncAnimation);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncAnimation() {
    final painter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
    )..layout();
    _textWidth = painter.width;

    if (!_overflows) {
      _controller.stop();
      _controller.value = 0;
      return;
    }

    final travel = _textWidth + _gap;
    final ms = (travel / _speedPxPerSec * 1000).round().clamp(1200, 30000);
    _controller.duration = Duration(milliseconds: ms);
    if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        if (maxW.isFinite && (maxW - _viewportWidth).abs() > 0.5) {
          _viewportWidth = maxW;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(_syncAnimation);
          });
        }

        if (!_overflows) {
          return SizedBox(
            height: _lineHeight,
            child: Text(
              widget.text,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              style: widget.style,
            ),
          );
        }

        return SizedBox(
          height: _lineHeight,
          width: maxW,
          child: ClipRect(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final dx = -_controller.value * (_textWidth + _gap);
                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Transform.translate(
                      offset: Offset(dx, 0),
                      child: Text(
                        widget.text,
                        maxLines: 1,
                        softWrap: false,
                        style: widget.style,
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(dx + _textWidth + _gap, 0),
                      child: Text(
                        widget.text,
                        maxLines: 1,
                        softWrap: false,
                        style: widget.style,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ToolIcon extends StatelessWidget {
  const _ToolIcon({required this.asset, required this.onTap});

  final String asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AppIcon(asset, size: 32, color: AppColors.white),
    );
  }
}
