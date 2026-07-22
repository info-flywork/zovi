import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:zovi/core/snackbar/app_snackbar.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/utils/extensions/future_extensions.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/presentation/chat/model/chat_detail_route_args.dart';
import 'package:zovi/presentation/chat/model/group_info_route_args.dart';
import 'package:zovi/presentation/chat/view/widgets/chat_media_viewer.dart';
import 'package:zovi/presentation/chat/view/widgets/chat_sticker_sheet.dart';

class ChatDetailView extends StatefulWidget {
  const ChatDetailView({required this.args, super.key});

  final ChatDetailRouteArgs args;

  @override
  State<ChatDetailView> createState() => _ChatDetailViewState();
}

class _ChatDetailViewState extends State<ChatDetailView> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  final _audioRecorder = AudioRecorder();

  late final List<_ChatMessage> _messages;
  var _hasText = false;
  var _isRecording = false;
  var _isRecordingPaused = false;
  var _recordingSeconds = 0;
  var _recordedDuration = Duration.zero;
  DateTime? _recordingSegmentStartedAt;
  Timer? _recordingTimer;
  StreamSubscription<Amplitude>? _amplitudeSub;
  String? _recordingPath;
  final List<double> _waveLevels = List<double>.generate(28, (_) => 0.12);

  @override
  void initState() {
    super.initState();
    _messages = widget.args.isGroup
        ? [
            _ChatMessage(
              text: 'chat_demo_incoming'.tr(),
              isMine: false,
              senderName: 'Julia Ivanova',
              senderAvatarPath: AssetPaths.avatarJulia,
            ),
            const _ChatMessage(text: 'Hey!', isMine: true),
            _ChatMessage(
              text: 'chat_group_demo_incoming'.tr(),
              isMine: false,
              senderName: 'Sona Black',
              senderAvatarPath: AssetPaths.avatarSona,
            ),
          ]
        : [_ChatMessage(text: 'chat_demo_incoming'.tr(), isMine: false)];
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    unawaited(_amplitudeSub?.cancel());
    _controller
      ..removeListener(_onTextChanged)
      ..dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    unawaited(_audioRecorder.dispose());
    super.dispose();
  }

  void _onTextChanged() {
    final next = _controller.text.trim().isNotEmpty;
    if (next == _hasText) return;
    setState(() => _hasText = next);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _addMessage(_ChatMessage message) {
    setState(() => _messages.add(message));
    _scrollToBottom();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _addMessage(_ChatMessage(text: text, isMine: true));
    _controller.clear();
    setState(() => _hasText = false);
    _focusNode.requestFocus();
  }

  Future<void> _openStickers() async {
    _focusNode.unfocus();
    final stamp = await showChatStickerSheet(context);
    if (!mounted || stamp == null) return;
    _addMessage(_ChatMessage(stampPath: stamp.imagePath, isMine: true));
  }

  Future<void> _pickImage(ImageSource source) async {
    _focusNode.unfocus();
    if (!mounted) return;

    try {
      final image = await _pickImageFlow(source).withLoading(context);
      if (!mounted || image == null) return;
      _addMessage(_ChatMessage(imagePath: image.path, isMine: true));
    } on _MediaPermissionDeniedException {
      if (!mounted) return;
      AppSnackbar.instance.show(
        context,
        'chat_permission_denied'.tr(),
        isError: true,
      );
    }
  }

  Future<XFile?> _pickImageFlow(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        throw const _MediaPermissionDeniedException();
      }
    }
    return _imagePicker.pickImage(source: source, imageQuality: 85);
  }

  Duration get _currentRecordingDuration {
    var total = _recordedDuration;
    final started = _recordingSegmentStartedAt;
    if (!_isRecordingPaused && started != null) {
      total += DateTime.now().difference(started);
    }
    return total;
  }

  void _startRecordingTimers() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || !_isRecording) return;
      setState(() => _recordingSeconds = _currentRecordingDuration.inSeconds);
    });

    unawaited(_amplitudeSub?.cancel());
    _amplitudeSub = _audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 70))
        .listen((amplitude) {
          if (!mounted || _isRecordingPaused) return;
          // dBFS roughly -60..0 for speech
          final level = ((amplitude.current + 55) / 55).clamp(0.1, 1.0);
          setState(() {
            for (var i = 0; i < _waveLevels.length - 1; i++) {
              _waveLevels[i] = _waveLevels[i + 1];
            }
            _waveLevels[_waveLevels.length - 1] = level;
          });
        });
  }

  void _resetWaveLevels() {
    for (var i = 0; i < _waveLevels.length; i++) {
      _waveLevels[i] = 0.12;
    }
  }

  Future<void> _startRecording() async {
    _focusNode.unfocus();
    if (!mounted) return;

    try {
      await _prepareAndStartRecording().withLoading(context);
    } on _MediaPermissionDeniedException {
      if (!mounted) return;
      AppSnackbar.instance.show(
        context,
        'chat_permission_denied'.tr(),
        isError: true,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.instance.show(
        context,
        'chat_permission_denied'.tr(),
        isError: true,
      );
    }
  }

  Future<void> _prepareAndStartRecording() async {
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        throw const _MediaPermissionDeniedException();
      }
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/zovi_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _audioRecorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );

    if (!mounted) return;
    _recordedDuration = Duration.zero;
    _recordingSegmentStartedAt = DateTime.now();
    _resetWaveLevels();
    setState(() {
      _isRecording = true;
      _isRecordingPaused = false;
      _recordingSeconds = 0;
      _recordingPath = path;
    });
    _startRecordingTimers();
  }

  Future<void> _toggleRecordingPause() async {
    if (!_isRecording) return;

    if (_isRecordingPaused) {
      await _audioRecorder.resume();
      if (!mounted) return;
      _recordingSegmentStartedAt = DateTime.now();
      setState(() => _isRecordingPaused = false);
      return;
    }

    final started = _recordingSegmentStartedAt;
    if (started != null) {
      _recordedDuration += DateTime.now().difference(started);
    }
    _recordingSegmentStartedAt = null;
    await _audioRecorder.pause();
    if (!mounted) return;
    setState(() {
      _isRecordingPaused = true;
      _recordingSeconds = _recordedDuration.inSeconds;
    });
  }

  Future<void> _cancelRecording() async {
    _recordingTimer?.cancel();
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    _recordingSegmentStartedAt = null;
    _recordedDuration = Duration.zero;
    if (await _audioRecorder.isRecording()) {
      await _audioRecorder.stop();
    }
    final path = _recordingPath;
    if (path != null) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _isRecordingPaused = false;
      _recordingSeconds = 0;
      _recordingPath = null;
      _resetWaveLevels();
    });
  }

  Future<void> _stopRecordingAndSend() async {
    _recordingTimer?.cancel();
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;

    final elapsed = _currentRecordingDuration;
    final path = await _audioRecorder.stop() ?? _recordingPath;
    _recordingSegmentStartedAt = null;
    _recordedDuration = Duration.zero;

    if (!mounted) return;

    if (elapsed.inMilliseconds < 500 || path == null) {
      if (path != null) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _isRecordingPaused = false;
        _recordingSeconds = 0;
        _recordingPath = null;
        _resetWaveLevels();
      });
      AppSnackbar.instance.show(context, 'chat_voice_too_short'.tr());
      return;
    }

    setState(() {
      _isRecording = false;
      _isRecordingPaused = false;
      _recordingSeconds = 0;
      _recordingPath = null;
      _resetWaveLevels();
    });
    _addMessage(
      _ChatMessage(voicePath: path, voiceDuration: elapsed, isMine: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            _ChatDetailHeader(args: widget.args),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: Divider(
                height: 1,
                thickness: 1,
                color: AppColors.borderLight,
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _MessageBubble(
                      message: message,
                      avatarPath: widget.args.avatarPath,
                      isGroup: widget.args.isGroup,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 10 + bottomInset),
              child: _isRecording
                  ? _VoiceRecordingBar(
                      seconds: _recordingSeconds,
                      isPaused: _isRecordingPaused,
                      waveLevels: _waveLevels,
                      onCancel: _cancelRecording,
                      onTogglePause: _toggleRecordingPause,
                      onSend: _stopRecordingAndSend,
                    )
                  : _ChatInputBar(
                      controller: _controller,
                      focusNode: _focusNode,
                      hasText: _hasText,
                      onSend: _send,
                      onStickerTap: _openStickers,
                      onCameraTap: () => _pickImage(ImageSource.camera),
                      onGalleryTap: () => _pickImage(ImageSource.gallery),
                      onMicTap: _startRecording,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    this.text,
    this.stampPath,
    this.imagePath,
    this.voicePath,
    this.voiceDuration,
    this.senderName,
    this.senderAvatarPath,
    required this.isMine,
  });

  final String? text;
  final String? stampPath;
  final String? imagePath;
  final String? voicePath;
  final Duration? voiceDuration;
  final String? senderName;
  final String? senderAvatarPath;
  final bool isMine;

  bool get isStamp => stampPath != null;
  bool get isImage => imagePath != null;
  bool get isVoice => voicePath != null;
}

class _ChatDetailHeader extends StatelessWidget {
  const _ChatDetailHeader({required this.args});

  final ChatDetailRouteArgs args;

  @override
  Widget build(BuildContext context) {
    final subtitle = args.isGroup
        ? 'chat_member_count'.tr(
            namedArgs: {'count': '${args.memberCount ?? 0}'},
          )
        : 'chat_active_ago'.tr(namedArgs: {'time': args.lastActive});

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            behavior: HitTestBehavior.opaque,
            child: const AppIcon(AssetPaths.iconArrowLeft),
          ),
          const SizedBox(width: 12),
          ClipOval(
            child: Image.asset(
              args.avatarPath,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  args.headerTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1,
                    letterSpacing: -0.32,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: args.isGroup ? 14 : 12,
                    fontWeight: FontWeight.w500,
                    height: 1,
                    letterSpacing: args.isGroup ? -0.28 : -0.24,
                    color: args.isGroup
                        ? AppColors.deepRoast.withValues(alpha: 0.65)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (args.isGroup) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                context.push(
                  RoutePaths.groupInfo.path,
                  extra: GroupInfoRouteArgs(
                    name: args.name,
                    avatarPath: args.avatarPath,
                    memberCount: args.memberCount ?? 0,
                  ),
                );
              },
              behavior: HitTestBehavior.opaque,
              child: const AppIcon(
                AssetPaths.iconSetting,
                size: 32,
                color: AppColors.deepRoast,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.avatarPath,
    required this.isGroup,
  });

  final _ChatMessage message;
  final String avatarPath;
  final bool isGroup;

  void _openMedia(
    BuildContext context, {
    required String heroTag,
    String? assetPath,
    String? filePath,
  }) {
    showChatMediaViewer(
      context,
      heroTag: heroTag,
      assetPath: assetPath,
      filePath: filePath,
    );
  }

  Widget _wrapIncoming({required Widget child}) {
    final senderAvatar = message.senderAvatarPath ?? avatarPath;
    final senderName = message.senderName;

    if (!isGroup) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ClipOval(
            child: Image.asset(
              senderAvatar,
              width: 32,
              height: 32,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(child: child),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ClipOval(
          child: Image.asset(
            senderAvatar,
            width: 32,
            height: 32,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (senderName != null && senderName.isNotEmpty) ...[
                Text(
                  senderName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1,
                    letterSpacing: -0.28,
                    color: AppColors.zoviOrange,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              child,
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (message.isStamp) {
      final heroTag = 'chat_stamp_${identityHashCode(message)}';
      final stamp = GestureDetector(
        onTap: () =>
            _openMedia(context, heroTag: heroTag, assetPath: message.stampPath),
        child: Hero(
          tag: heroTag,
          child: Image.asset(
            message.stampPath!,
            width: 140,
            height: 140,
            fit: BoxFit.contain,
          ),
        ),
      );
      if (message.isMine) {
        return Align(alignment: Alignment.centerRight, child: stamp);
      }
      return _wrapIncoming(child: stamp);
    }

    if (message.isImage) {
      final heroTag = 'chat_image_${identityHashCode(message)}';
      final image = GestureDetector(
        onTap: () =>
            _openMedia(context, heroTag: heroTag, filePath: message.imagePath),
        child: Hero(
          tag: heroTag,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              File(message.imagePath!),
              width: 220,
              height: 220,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
      if (message.isMine) {
        return Align(alignment: Alignment.centerRight, child: image);
      }
      return _wrapIncoming(child: image);
    }

    if (message.isVoice) {
      final voice = _VoiceBubble(
        path: message.voicePath!,
        duration: message.voiceDuration ?? Duration.zero,
        isMine: message.isMine,
      );
      if (message.isMine) {
        return Align(alignment: Alignment.centerRight, child: voice);
      }
      return _wrapIncoming(child: voice);
    }

    if (message.isMine) {
      return Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.zoviOrange,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Text(
              message.text!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 20 / 16,
                letterSpacing: -0.32,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      );
    }

    final bubble = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.72,
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.chatBubbleIncoming,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.2)),
        ),
        child: Text(
          message.text!,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 20 / 16,
            letterSpacing: -0.32,
            color: AppColors.deepRoast,
          ),
        ),
      ),
    );

    return _wrapIncoming(child: bubble);
  }
}

class _VoiceBubble extends StatefulWidget {
  const _VoiceBubble({
    required this.path,
    required this.duration,
    required this.isMine,
  });

  final String path;
  final Duration duration;
  final bool isMine;

  @override
  State<_VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<_VoiceBubble> {
  final _player = AudioPlayer();
  var _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.stop();
      setState(() => _isPlaying = false);
      return;
    }
    await _player.play(DeviceFileSource(widget.path));
    setState(() => _isPlaying = true);
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isMine
        ? AppColors.zoviOrange
        : AppColors.chatBubbleIncoming;
    final fg = widget.isMine ? AppColors.white : AppColors.deepRoast;

    return GestureDetector(
      onTap: _togglePlay,
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: Radius.circular(widget.isMine ? 4 : 16),
            bottomLeft: Radius.circular(widget.isMine ? 16 : 4),
            bottomRight: const Radius.circular(16),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: fg.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 20,
                color: fg,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                children: List.generate(18, (index) {
                  final heights = [8.0, 14.0, 10.0, 18.0, 12.0, 16.0, 9.0];
                  final h = heights[index % heights.length];
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Container(
                        height: h,
                        decoration: BoxDecoration(
                          color: fg.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _format(widget.duration),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1,
                letterSpacing: -0.24,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceRecordingBar extends StatelessWidget {
  const _VoiceRecordingBar({
    required this.seconds,
    required this.isPaused,
    required this.waveLevels,
    required this.onCancel,
    required this.onTogglePause,
    required this.onSend,
  });

  final int seconds;
  final bool isPaused;
  final List<double> waveLevels;
  final VoidCallback onCancel;
  final VoidCallback onTogglePause;
  final VoidCallback onSend;

  String _format(int total) {
    final m = (total ~/ 60).toString();
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.chatBubbleIncoming,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onCancel,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.logoutRed.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.close_rounded,
                size: 22,
                color: AppColors.logoutRed,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _format(seconds),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1,
              letterSpacing: -0.28,
              color: AppColors.deepRoast,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 28,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  for (var i = 0; i < waveLevels.length; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0.8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 70),
                          curve: Curves.easeOut,
                          height: 4 + (24 * waveLevels[i]),
                          decoration: BoxDecoration(
                            color: isPaused
                                ? AppColors.textSecondary
                                : AppColors.zoviOrange,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onTogglePause,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.deepRoast.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                size: 22,
                color: AppColors.deepRoast,
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onSend,
            behavior: HitTestBehavior.opaque,
            child: const _ChatCircleAction(icon: AssetPaths.iconChatSend),
          ),
        ],
      ),
    );
  }
}

class _ChatInputBar extends StatefulWidget {
  const _ChatInputBar({
    required this.controller,
    required this.focusNode,
    required this.hasText,
    required this.onSend,
    required this.onStickerTap,
    required this.onCameraTap,
    required this.onGalleryTap,
    required this.onMicTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasText;
  final VoidCallback onSend;
  final VoidCallback onStickerTap;
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;
  final VoidCallback onMicTap;

  @override
  State<_ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<_ChatInputBar>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 220);
  static const _cameraSlotWidth = 52.0;
  static const _accessoriesWidth = 100.0;
  static const _sendWidth = 44.0;

  late final AnimationController _controller;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _duration,
      value: widget.hasText ? 1 : 0,
    );
    _t = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  }

  @override
  void didUpdateWidget(covariant _ChatInputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasText == oldWidget.hasText) return;
    if (widget.hasText) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.chatBubbleIncoming,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: AnimatedBuilder(
        animation: _t,
        builder: (context, child) {
          final t = _t.value;
          final rightWidth =
              _accessoriesWidth + (_sendWidth - _accessoriesWidth) * t;

          return Row(
            children: [
              ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: 1 - t,
                  child: Opacity(
                    opacity: (1 - t).clamp(0.0, 1.0),
                    child: SizedBox(
                      width: _cameraSlotWidth,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: widget.onCameraTap,
                          behavior: HitTestBehavior.opaque,
                          child: const _ChatCircleAction(
                            icon: AssetPaths.iconChatCamera,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              child!,
              SizedBox(
                width: rightWidth,
                height: 44,
                child: Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    IgnorePointer(
                      ignoring: t > 0.5,
                      child: Opacity(
                        opacity: (1 - t).clamp(0.0, 1.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: widget.onStickerTap,
                                behavior: HitTestBehavior.opaque,
                                child: const AppIcon(
                                  AssetPaths.iconChatSticker,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: widget.onGalleryTap,
                                behavior: HitTestBehavior.opaque,
                                child: const AppIcon(
                                  AssetPaths.iconChatGallery,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: widget.onMicTap,
                                behavior: HitTestBehavior.opaque,
                                child: const AppIcon(
                                  AssetPaths.iconChatMicrophone,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                          ),
                        ),
                      ),
                    ),
                    IgnorePointer(
                      ignoring: t < 0.5,
                      child: Opacity(
                        opacity: t.clamp(0.0, 1.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: widget.onSend,
                            behavior: HitTestBehavior.opaque,
                            child: const _ChatCircleAction(
                              icon: AssetPaths.iconChatSend,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        child: Expanded(
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => widget.onSend(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 18 / 16,
              letterSpacing: -0.32,
              color: AppColors.deepRoast,
            ),
            decoration: InputDecoration(
              hintText: 'chat_message_hint'.tr(),
              hintStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 18 / 16,
                letterSpacing: -0.32,
                color: AppColors.deepRoast.withValues(alpha: 0.45),
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 10,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatCircleAction extends StatelessWidget {
  const _ChatCircleAction({required this.icon});

  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.chatPurple,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: AppIcon(icon, size: 24),
    );
  }
}

class _MediaPermissionDeniedException implements Exception {
  const _MediaPermissionDeniedException();
}
