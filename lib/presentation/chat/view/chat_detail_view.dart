import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:shimmer/shimmer.dart';
import 'package:zovi/core/cache/chat_messages_cache.dart';
import 'package:zovi/core/chat/active_chat_tracker.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/snackbar/app_snackbar.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/utils/navigation/open_user_profile.dart';
import 'package:zovi/core/widgets/app_confirm_dialog.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/core/widgets/profile_avatar.dart';
import 'package:zovi/core/widgets/stamp_image.dart';
import 'package:zovi/domain/auth/auth_repository.dart';
import 'package:zovi/domain/chat/chat_repository.dart';
import 'package:zovi/domain/tribe/tribe_repository.dart';
import 'package:zovi/presentation/chat/model/chat_detail_exit_store.dart';
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
  static const _messageAnimDuration = Duration(milliseconds: 280);

  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  final _audioRecorder = AudioRecorder();
  final _repo = getIt<ChatRepository>();
  final _messagesCache = getIt<ChatMessagesCache>();
  var _listKey = GlobalKey<AnimatedListState>();

  late final List<_ChatMessage> _messages;
  var _hasText = false;
  var _isRecording = false;
  var _isRecordingPaused = false;
  var _recordingSeconds = 0;
  var _recordedDuration = Duration.zero;
  DateTime? _recordingSegmentStartedAt;
  Timer? _recordingTimer;
  Timer? _poll;
  StreamSubscription<Amplitude>? _amplitudeSub;
  String? _recordingPath;
  final List<double> _waveLevels = List<double>.generate(28, (_) => 0.12);

  String? _conversationId;
  String? _peerUserId;
  String? _myUserId;
  DateTime? _newestRemoteAt;
  var _isRequest = false;
  String? _exitResult;
  var _booting = false;
  late int _memberCount;
  late String _avatarPath;
  late String _headerName;

  /// Only true on cold open (no memory cache) — never when reopening a thread.
  var _showShimmer = false;
  var _sending = false;
  var _requestActionBusy = false;
  _ChatMessage? _replyingTo;

  @override
  void initState() {
    super.initState();
    _myUserId = getIt<AuthRepository>().backendUserId;
    _conversationId = widget.args.conversationId.trim().isEmpty
        ? null
        : widget.args.conversationId.trim();
    _peerUserId = widget.args.userId.trim().isEmpty
        ? null
        : widget.args.userId.trim();
    _isRequest = widget.args.isRequest && !widget.args.isGroup;
    _memberCount = widget.args.memberCount ?? 0;
    _avatarPath = widget.args.avatarPath.trim();
    _headerName = widget.args.name.trim();

    if (widget.args.isGroup) {
      final tribeId = widget.args.tribeId.trim();
      final cached = getIt<TribeRepository>().findCachedTribe(
        tribeId: tribeId,
        conversationId: _conversationId ?? '',
      );
      if (cached != null) {
        if ((_conversationId == null || _conversationId!.isEmpty) &&
            cached.conversationId.isNotEmpty) {
          _conversationId = cached.conversationId;
        }
        if (cached.memberCount > 0) {
          _memberCount = cached.memberCount;
        }
        _applyGroupMetaFromTribe(cached);
      }
    }

    // Profile / connections açılışında conversationId yok — cache'ten çöz.
    if ((_conversationId == null || _conversationId!.isEmpty) &&
        (_peerUserId?.isNotEmpty ?? false)) {
      final known = _repo.peekDm(_peerUserId!);
      if (known != null) {
        _conversationId = known.id;
        if (!widget.args.isRequest) {
          _isRequest = known.isRequest;
        }
      }
    }
    _messages = [];

    // Paint cached bubbles immediately when reopening the same thread.
    final cachedId = _conversationId;
    if (cachedId != null && cachedId.isNotEmpty) {
      _hydrateFromCache(cachedId);
    }
    _showShimmer = _messages.isEmpty;
    if (_messages.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrollToBottom();
      });
    }

    _controller.addListener(_onTextChanged);
    ActiveChatTracker.instance.enter(
      conversationId: _conversationId,
      peerUserId: widget.args.isGroup ? null : _peerUserId,
    );
    if (widget.args.isGroup) {
      unawaited(_bootstrapGroup());
    } else {
      unawaited(_bootstrapDm());
    }
    _poll = Timer.periodic(
      const Duration(seconds: 3),
      (_) => unawaited(_pullMessages(silent: true)),
    );
  }

  void _applyGroupMetaFromTribe(Tribe? tribe) {
    if (!widget.args.isGroup || tribe == null) return;
    var changed = false;
    if (tribe.avatars.isNotEmpty) {
      final nextAvatar = tribe.avatars.first.trim();
      if (nextAvatar.isNotEmpty && nextAvatar != _avatarPath) {
        _avatarPath = nextAvatar;
        changed = true;
      }
    }
    final nextName = tribe.name.trim();
    if (nextName.isNotEmpty && nextName != _headerName) {
      _headerName = nextName;
      changed = true;
    }
    if (changed && mounted) setState(() {});
  }

  @override
  void dispose() {
    ActiveChatTracker.instance.leave(conversationId: _conversationId);
    _persistMessagesToCache();
    _poll?.cancel();
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

  Future<void> _bootstrapDm() async {
    if (_booting) return;
    _booting = true;
    try {
      var conversationId = _conversationId;
      if ((conversationId == null || conversationId.isEmpty) &&
          (_peerUserId?.isNotEmpty ?? false)) {
        final opened = await _repo.openDm(_peerUserId!);
        conversationId = opened.id;
        _peerUserId = opened.peer.userId;
        if (!widget.args.isRequest) {
          _isRequest = opened.isRequest;
        }
      } else if (conversationId != null &&
          conversationId.isNotEmpty &&
          (_peerUserId?.isNotEmpty ?? false)) {
        // Inbox'ten conversationId ile geldiysek peer eşlemesini sakla.
        _repo.rememberConversation(
          ChatConversation(
            id: conversationId,
            folder: _isRequest ? 'request' : 'inbox',
            unreadCount: 0,
            lastMessagePreview: '',
            peer: ChatPeer(
              userId: _peerUserId!,
              name: widget.args.name,
              username: widget.args.username,
              avatarUrl: _avatarPath,
            ),
          ),
        );
      }
      if (conversationId == null || conversationId.isEmpty) {
        if (mounted) setState(() => _showShimmer = false);
        return;
      }
      _conversationId = conversationId;
      ActiveChatTracker.instance.enter(
        conversationId: conversationId,
        peerUserId: _peerUserId,
      );

      final hadCache = _hydrateFromCache(conversationId);
      if (hadCache) {
        if (mounted) {
          setState(() => _showShimmer = false);
          _scrollToBottom();
        }
        // Soft refresh: only newer messages when cursor exists.
        await _pullMessages(silent: true);
      } else {
        if (mounted && !_showShimmer) {
          setState(() => _showShimmer = true);
        }
        await _pullMessages();
      }
      unawaited(_repo.markRead(conversationId));
    } catch (_) {
      if (!mounted) return;
      setState(() => _showShimmer = false);
      AppSnackbar.instance.show(
        context,
        'chat_load_failed'.tr(),
        isError: true,
      );
    } finally {
      _booting = false;
      if (mounted && _showShimmer) {
        setState(() => _showShimmer = false);
      }
    }
  }

  Future<void> _bootstrapGroup() async {
    if (_booting) return;
    _booting = true;
    try {
      var conversationId = _conversationId;
      final tribeId = widget.args.tribeId.trim();
      final tribes = getIt<TribeRepository>();

      Tribe? detail = tribes.findCachedTribe(
        tribeId: tribeId,
        conversationId: conversationId ?? '',
      );
      if ((conversationId == null || conversationId.isEmpty) &&
          detail != null &&
          detail.conversationId.isNotEmpty) {
        conversationId = detail.conversationId;
        if (mounted) setState(() => _memberCount = detail!.memberCount);
        _applyGroupMetaFromTribe(detail);
      }

      if ((conversationId == null || conversationId.isEmpty) &&
          tribeId.isNotEmpty) {
        detail = await tribes.refreshTribeDetail(tribeId);
        if (!mounted) return;
        final resolved = detail?.conversationId.trim() ?? '';
        if (resolved.isNotEmpty) conversationId = resolved;
        if (detail != null && mounted) {
          setState(() => _memberCount = detail!.memberCount);
          _applyGroupMetaFromTribe(detail);
        }
      } else if (tribeId.isNotEmpty) {
        unawaited(
          tribes.refreshTribeDetail(tribeId).then((fresh) {
            if (!mounted || fresh == null) return;
            setState(() => _memberCount = fresh.memberCount);
            _applyGroupMetaFromTribe(fresh);
          }),
        );
      }

      if (conversationId == null || conversationId.isEmpty) {
        if (mounted) setState(() => _showShimmer = false);
        return;
      }
      _conversationId = conversationId;
      ActiveChatTracker.instance.enter(conversationId: conversationId);

      final hadCache = _hydrateFromCache(conversationId);
      if (hadCache) {
        if (mounted) {
          setState(() => _showShimmer = false);
          _scrollToBottom();
        }
        await _pullMessages(silent: true);
      } else {
        if (mounted && !_showShimmer) {
          setState(() => _showShimmer = true);
        }
        await _pullMessages();
      }
      unawaited(_repo.markRead(conversationId));
    } catch (_) {
      if (!mounted) return;
      setState(() => _showShimmer = false);
      AppSnackbar.instance.show(
        context,
        'chat_load_failed'.tr(),
        isError: true,
      );
    } finally {
      _booting = false;
      if (mounted && _showShimmer) {
        setState(() => _showShimmer = false);
      }
    }
  }

  /// Returns true when cache painted at least one message.
  bool _hydrateFromCache(String conversationId) {
    final cached = _messagesCache.peek(conversationId);
    if (cached == null || cached.isEmpty) return false;

    final myId = (_myUserId ?? getIt<AuthRepository>().backendUserId ?? '')
        .trim();
    if (myId.isNotEmpty) _myUserId = myId;

    final mapped = [for (final m in cached) _mapRemote(m, myId)];
    _messages
      ..clear()
      ..addAll(mapped);
    _listKey = GlobalKey<AnimatedListState>();
    _newestRemoteAt = _messagesCache.newestAt(conversationId);
    _updateNewestCursor(mapped);
    _showShimmer = false;
    return true;
  }

  _ChatMessage _mapRemote(ChatMessage m, String myId) {
    bool? replyMine;
    final replyId = m.replyToMessageId?.trim();
    if (replyId != null && replyId.isNotEmpty) {
      for (final existing in _messages) {
        if (existing.id == replyId) {
          replyMine = existing.isMine;
          break;
        }
      }
    }
    Duration? voiceDuration;
    if (m.type == 'voice') {
      final ms = int.tryParse(m.body.trim());
      if (ms != null && ms > 0) {
        voiceDuration = Duration(milliseconds: ms);
      }
    }
    return _ChatMessage(
      id: m.id,
      text: m.type == 'text' ? m.body : null,
      stampPath: m.type == 'stamp'
          ? (m.mediaUrl.isNotEmpty ? m.mediaUrl : m.body)
          : null,
      imagePath: m.type == 'image' ? m.mediaUrl : null,
      voicePath: m.type == 'voice' ? m.mediaUrl : null,
      voiceDuration: voiceDuration,
      isMine: myId.isNotEmpty && m.senderId == myId,
      senderName: myId.isNotEmpty && m.senderId == myId
          ? null
          : (m.senderName.trim().isNotEmpty
                ? m.senderName.trim()
                : (m.senderUsername.trim().isNotEmpty
                      ? m.senderUsername.trim()
                      : (widget.args.isGroup ? null : widget.args.name))),
      senderUsername: myId.isNotEmpty && m.senderId == myId
          ? null
          : (m.senderUsername.trim().isNotEmpty
                ? m.senderUsername.trim()
                : null),
      senderAvatarPath: myId.isNotEmpty && m.senderId == myId
          ? null
          : (m.senderAvatarUrl.trim().isNotEmpty
                ? m.senderAvatarUrl.trim()
                : _avatarPath),
      createdAt: m.createdAt,
      replyToId: m.replyToMessageId,
      replyToText: m.replyPreview.trim().isEmpty ? null : m.replyPreview,
      replyToIsMine: replyMine,
    );
  }

  Future<void> _pullMessages({bool silent = false}) async {
    final conversationId = _conversationId;
    if (conversationId == null || conversationId.isEmpty) return;
    try {
      final myId = (_myUserId ?? getIt<AuthRepository>().backendUserId ?? '')
          .trim();
      if (myId.isNotEmpty) _myUserId = myId;

      // Incremental poll / soft reopen: only fetch messages newer than cache.
      if (silent && _newestRemoteAt != null && _messages.isNotEmpty) {
        final newer = await _repo.listMessages(
          conversationId,
          after: _newestRemoteAt,
        );
        if (!mounted) return;
        if (newer.isEmpty) {
          if (_showShimmer) setState(() => _showShimmer = false);
          return;
        }

        _messagesCache.mergeNewer(conversationId, newer);

        final existingIds = {for (final m in _messages) m.id};
        final toAdd = <_ChatMessage>[];
        for (final m in newer) {
          if (existingIds.contains(m.id)) continue;
          final mapped = _mapRemote(m, myId);
          final localIdx = _messages.indexWhere(
            (local) =>
                (local.id ?? '').startsWith('local-') &&
                local.isMine &&
                mapped.isMine &&
                (local.text?.trim() ?? '') == (mapped.text?.trim() ?? '') &&
                (mapped.text?.trim().isNotEmpty ?? false),
          );
          if (localIdx >= 0) {
            _replaceMessageAt(localIdx, mapped, animate: false);
          } else {
            toAdd.add(mapped);
          }
          final at = m.createdAt;
          if (at != null &&
              (_newestRemoteAt == null || at.isAfter(_newestRemoteAt!))) {
            _newestRemoteAt = at;
          }
        }
        for (final msg in toAdd) {
          _insertMessage(msg, animate: true);
        }
        if (toAdd.isNotEmpty) {
          _scrollToBottom();
          unawaited(_repo.markRead(conversationId));
        }
        if (_showShimmer) setState(() => _showShimmer = false);
        return;
      }

      final remote = await _repo.listMessages(conversationId);
      if (!mounted) return;

      _messagesCache.put(conversationId, remote);

      final mapped = [for (final m in remote) _mapRemote(m, myId)];
      final byId = {
        for (final m in mapped)
          if (m.id != null) m.id!: m,
      };
      final withReplyOwners = [
        for (final m in mapped)
          if (m.replyToId == null ||
              m.replyToIsMine != null ||
              byId[m.replyToId] == null)
            m
          else
            _ChatMessage(
              id: m.id,
              text: m.text,
              stampPath: m.stampPath,
              imagePath: m.imagePath,
              voicePath: m.voicePath,
              voiceDuration: m.voiceDuration,
              senderName: m.senderName,
              senderAvatarPath: m.senderAvatarPath,
              createdAt: m.createdAt,
              replyToId: m.replyToId,
              replyToText: m.replyToText,
              replyToIsMine: byId[m.replyToId]!.isMine,
              isMine: m.isMine,
            ),
      ];

      final pendingLocals = [
        for (final m in _messages)
          if ((m.id ?? '').startsWith('local-')) m,
      ];

      final remoteIds = {for (final m in withReplyOwners) m.id};
      final next = [
        ...withReplyOwners,
        for (final local in pendingLocals)
          if (!remoteIds.contains(local.id) &&
              !_remoteHasSameText(withReplyOwners, local))
            local,
      ];

      if (_sameMessageIds(_messages, next) && silent) {
        _updateNewestCursor(withReplyOwners);
        if (_showShimmer && mounted) {
          setState(() => _showShimmer = false);
        }
        return;
      }

      _replaceAllMessages(next, clearShimmer: !silent || _showShimmer);
      _updateNewestCursor(withReplyOwners);
      if (!silent) _scrollToBottom();
      unawaited(_repo.markRead(conversationId));
    } catch (_) {
      // Keep current paint; next tick retries.
    }
  }

  void _updateNewestCursor(List<_ChatMessage> remote) {
    DateTime? newest = _newestRemoteAt;
    for (final m in remote) {
      final at = m.createdAt;
      if (at == null) continue;
      if (newest == null || at.isAfter(newest)) newest = at;
    }
    _newestRemoteAt = newest;
  }

  void _replaceAllMessages(
    List<_ChatMessage> next, {
    bool clearShimmer = false,
  }) {
    setState(() {
      _messages
        ..clear()
        ..addAll(next);
      _listKey = GlobalKey<AnimatedListState>();
      if (clearShimmer) _showShimmer = false;
    });
  }

  void _persistMessagesToCache() {
    final conversationId = _conversationId;
    if (conversationId == null || conversationId.isEmpty) return;
    final myId = (_myUserId ?? '').trim();
    final remote = <ChatMessage>[
      for (final m in _messages)
        if ((m.id ?? '').isNotEmpty && !(m.id ?? '').startsWith('local-'))
          ChatMessage(
            id: m.id!,
            conversationId: conversationId,
            senderId: m.isMine ? myId : (_peerUserId ?? ''),
            type: m.isStamp
                ? 'stamp'
                : m.isImage
                ? 'image'
                : m.isVoice
                ? 'voice'
                : 'text',
            body: m.isVoice
                ? '${m.voiceDuration?.inMilliseconds ?? 0}'
                : (m.text ?? ''),
            mediaUrl: m.stampPath ?? m.imagePath ?? m.voicePath ?? '',
            createdAt: m.createdAt,
            replyToMessageId: m.replyToId,
            replyPreview: m.replyToText ?? '',
          ),
    ];
    if (remote.isEmpty) return;
    _messagesCache.put(conversationId, remote);
  }

  void _insertMessage(_ChatMessage message, {required bool animate}) {
    final index = _messages.length;
    _messages.add(message);
    if (animate) {
      _listKey.currentState?.insertItem(index, duration: _messageAnimDuration);
    } else {
      setState(() {});
    }
  }

  void _replaceMessageAt(
    int index,
    _ChatMessage message, {
    required bool animate,
  }) {
    if (index < 0 || index >= _messages.length) return;
    setState(() => _messages[index] = message);
  }

  void _removeMessageAt(int index, {required bool animate}) {
    if (index < 0 || index >= _messages.length) return;
    final removed = _messages.removeAt(index);
    if (animate) {
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => _AnimatedMessageTile(
          animation: animation,
          message: removed,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _MessageBubble(
              message: removed,
              avatarPath: _avatarPath,
              username: widget.args.username,
              isGroup: widget.args.isGroup,
              peerName: widget.args.name,
            ),
          ),
        ),
        duration: _messageAnimDuration,
      );
    } else {
      setState(() {});
    }
  }

  bool _remoteHasSameText(List<_ChatMessage> remote, _ChatMessage local) {
    final text = local.text?.trim() ?? '';
    if (text.isEmpty || !local.isMine) return false;
    return remote.any((m) => m.isMine && (m.text?.trim() ?? '') == text);
  }

  bool _sameMessageIds(List<_ChatMessage> a, List<_ChatMessage> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  void _onTextChanged() {
    final next = _controller.text.trim().isNotEmpty;
    if (next == _hasText) return;
    setState(() => _hasText = next);
  }

  void _scrollToBottom({bool forceJump = false}) {
    void jumpIfNeeded() {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      if (forceJump || (_scrollController.offset - max).abs() > 1) {
        _scrollController.jumpTo(max);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      if (forceJump) {
        _scrollController.jumpTo(max);
      } else {
        _scrollController.animateTo(
          max,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
      // Layout can grow after AnimatedList insert / keyboard — settle again.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        jumpIfNeeded();
        Future<void>.delayed(const Duration(milliseconds: 80), () {
          if (!mounted) return;
          jumpIfNeeded();
        });
      });
    });
  }

  void _addMessage(_ChatMessage message) {
    _insertMessage(message, animate: true);
    _scrollToBottom(forceJump: true);
  }

  String _previewForReply(_ChatMessage message) {
    if (message.text?.trim().isNotEmpty ?? false) {
      return message.text!.trim();
    }
    if (message.isImage) return '📷';
    if (message.isVoice) return '🎤';
    if (message.isStamp) return '🏷️';
    return '';
  }

  void _startReply(_ChatMessage message) {
    setState(() => _replyingTo = message);
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    if (_replyingTo == null) return;
    setState(() => _replyingTo = null);
  }

  Future<void> _acceptRequest() async {
    final conversationId = _conversationId;
    if (conversationId == null ||
        conversationId.isEmpty ||
        _requestActionBusy) {
      return;
    }
    _requestActionBusy = true;
    try {
      await _repo.acceptConversation(conversationId);
      if (!mounted) return;
      setState(() {
        _isRequest = false;
        _rememberExitResult('accepted');
      });
      AppSnackbar.instance.show(context, 'chat_request_accepted'.tr());
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.instance.show(
        context,
        'chat_request_accept_failed'.tr(),
        isError: true,
      );
    } finally {
      _requestActionBusy = false;
    }
  }

  Future<void> _blockRequest() async {
    final conversationId = _conversationId;
    if (conversationId == null ||
        conversationId.isEmpty ||
        _requestActionBusy) {
      return;
    }
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'user_profile_block_title'.tr(
        namedArgs: {'username': widget.args.username},
      ),
      subtitle: 'user_profile_block_subtitle'.tr(),
      confirmLabel: 'user_profile_block_confirm'.tr(),
    );
    if (!confirmed || !mounted) return;

    _requestActionBusy = true;
    try {
      await _repo.blockConversation(conversationId);
      if (!mounted) return;
      _rememberExitResult('blocked');
      if (context.canPop()) {
        context.pop(_exitResult);
      }
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.instance.show(
        context,
        'chat_request_block_failed'.tr(),
        isError: true,
      );
    } finally {
      _requestActionBusy = false;
    }
  }

  void _rememberExitResult(String result) {
    _exitResult = result;
    final id = (_conversationId ?? '').trim().isNotEmpty
        ? _conversationId!.trim()
        : widget.args.conversationId.trim();
    ChatDetailExitStore.put(id, result);
  }

  void _popDetail() {
    if (!mounted) return;
    if (context.canPop()) {
      context.pop(_exitResult);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    if (_conversationId == null || _conversationId!.isEmpty) {
      if (widget.args.isGroup) {
        await _bootstrapGroup();
      } else {
        await _bootstrapDm();
      }
    }
    final conversationId = _conversationId;
    if (conversationId == null || conversationId.isEmpty) {
      if (!mounted) return;
      AppSnackbar.instance.show(
        context,
        'chat_send_failed'.tr(),
        isError: true,
      );
      return;
    }

    final reply = _replyingTo;
    final replyPreview = reply == null ? null : _previewForReply(reply);
    final optimistic = _ChatMessage(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      text: text,
      isMine: true,
      replyToId: reply?.id,
      replyToText: replyPreview,
      replyToIsMine: reply?.isMine,
    );
    _addMessage(optimistic);
    _controller.clear();
    setState(() {
      _hasText = false;
      _replyingTo = null;
    });
    _focusNode.requestFocus();

    _sending = true;
    try {
      final saved = await _repo.sendMessage(
        conversationId: conversationId,
        type: 'text',
        body: text,
        replyToMessageId: reply?.id,
        replyPreview: replyPreview,
      );
      if (!mounted) return;
      // Sending a reply accepts the request for this side.
      if (_isRequest) {
        setState(() {
          _isRequest = false;
          _rememberExitResult('accepted');
        });
      }
      final at = saved.createdAt;
      if (at != null &&
          (_newestRemoteAt == null || at.isAfter(_newestRemoteAt!))) {
        _newestRemoteAt = at;
      }
      _messagesCache.mergeNewer(conversationId, [saved]);
      final idx = _messages.indexWhere((m) => m.id == optimistic.id);
      final already = _messages.any((m) => m.id == saved.id);
      if (idx >= 0) {
        if (already) {
          _removeMessageAt(idx, animate: true);
        } else {
          _replaceMessageAt(
            idx,
            _ChatMessage(
              id: saved.id,
              text: saved.body,
              isMine: true,
              createdAt: saved.createdAt,
              replyToId: saved.replyToMessageId ?? optimistic.replyToId,
              replyToText: saved.replyPreview.trim().isNotEmpty
                  ? saved.replyPreview
                  : optimistic.replyToText,
              replyToIsMine: optimistic.replyToIsMine,
            ),
            animate: false,
          );
        }
      } else if (!already) {
        _addMessage(
          _ChatMessage(
            id: saved.id,
            text: saved.body,
            isMine: true,
            createdAt: saved.createdAt,
            replyToId: saved.replyToMessageId ?? optimistic.replyToId,
            replyToText: saved.replyPreview.trim().isNotEmpty
                ? saved.replyPreview
                : optimistic.replyToText,
            replyToIsMine: optimistic.replyToIsMine,
          ),
        );
      }
      _scrollToBottom(forceJump: true);
    } catch (_) {
      if (!mounted) return;
      final idx = _messages.indexWhere((m) => m.id == optimistic.id);
      if (idx >= 0) _removeMessageAt(idx, animate: true);
      AppSnackbar.instance.show(
        context,
        'chat_send_failed'.tr(),
        isError: true,
      );
    } finally {
      _sending = false;
    }
  }

  Future<void> _openStickers() async {
    _focusNode.unfocus();
    final stamp = await showChatStickerSheet(context);
    if (!mounted || stamp == null) return;
    await _sendMediaMessage(
      type: 'stamp',
      mediaPath: stamp.imagePath,
      body: stamp.id.isNotEmpty ? stamp.id : null,
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    _focusNode.unfocus();
    if (!mounted) return;

    try {
      final image = await _pickImageFlow(source);
      if (!mounted || image == null) return;
      await _sendMediaMessage(type: 'image', mediaPath: image.path);
    } on _MediaPermissionDeniedException {
      if (!mounted) return;
      AppSnackbar.instance.show(
        context,
        'chat_permission_denied'.tr(),
        isError: true,
      );
    }
  }

  /// Ensures DM conversation exists, then sends media via API.
  /// Stamp URLs are already on CDN; image/voice are uploaded first.
  Future<void> _sendMediaMessage({
    required String type,
    required String mediaPath,
    String? body,
    Duration? voiceDuration,
  }) async {
    final path = mediaPath.trim();
    if (path.isEmpty) return;

    if (_conversationId == null || _conversationId!.isEmpty) {
      if (widget.args.isGroup) {
        await _bootstrapGroup();
      } else {
        await _bootstrapDm();
      }
    }
    final conversationId = _conversationId;
    if (conversationId == null || conversationId.isEmpty) {
      if (!mounted) return;
      AppSnackbar.instance.show(
        context,
        'chat_send_failed'.tr(),
        isError: true,
      );
      return;
    }

    final reply = _replyingTo;
    final replyPreview = reply == null ? null : _previewForReply(reply);
    final optimistic = _ChatMessage(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      stampPath: type == 'stamp' ? path : null,
      imagePath: type == 'image' ? path : null,
      voicePath: type == 'voice' ? path : null,
      voiceDuration: voiceDuration,
      isMine: true,
      replyToId: reply?.id,
      replyToText: replyPreview,
      replyToIsMine: reply?.isMine,
    );
    _addMessage(optimistic);
    if (_replyingTo != null) {
      setState(() => _replyingTo = null);
    }

    try {
      Future<ChatMessage> send() async {
        var mediaUrl = path;
        if (type == 'image' || type == 'voice') {
          mediaUrl = await _repo.uploadMedia(path);
        }
        return _repo.sendMessage(
          conversationId: conversationId,
          type: type,
          body:
              body ??
              (type == 'voice'
                  ? '${voiceDuration?.inMilliseconds ?? 0}'
                  : null),
          mediaUrl: mediaUrl,
          replyToMessageId: reply?.id,
          replyPreview: replyPreview,
        );
      }

      if (!mounted) return;
      final saved = await send();
      if (!mounted) return;

      if (_isRequest) {
        setState(() {
          _isRequest = false;
          _rememberExitResult('accepted');
        });
      }
      final at = saved.createdAt;
      if (at != null &&
          (_newestRemoteAt == null || at.isAfter(_newestRemoteAt!))) {
        _newestRemoteAt = at;
      }
      _messagesCache.mergeNewer(conversationId, [saved]);

      final mapped = _mapRemote(
        saved,
        (_myUserId ?? getIt<AuthRepository>().backendUserId ?? '').trim(),
      );
      // Keep local duration if server body didn't carry it.
      final resolved = mapped.voiceDuration == null && voiceDuration != null
          ? _ChatMessage(
              id: mapped.id,
              text: mapped.text,
              stampPath: mapped.stampPath,
              imagePath: mapped.imagePath,
              voicePath: mapped.voicePath,
              voiceDuration: voiceDuration,
              senderName: mapped.senderName,
              senderAvatarPath: mapped.senderAvatarPath,
              createdAt: mapped.createdAt,
              replyToId: mapped.replyToId ?? optimistic.replyToId,
              replyToText: mapped.replyToText ?? optimistic.replyToText,
              replyToIsMine: mapped.replyToIsMine ?? optimistic.replyToIsMine,
              isMine: true,
            )
          : _ChatMessage(
              id: mapped.id,
              text: mapped.text,
              stampPath: mapped.stampPath ?? optimistic.stampPath,
              imagePath: mapped.imagePath ?? optimistic.imagePath,
              voicePath: mapped.voicePath ?? optimistic.voicePath,
              voiceDuration: mapped.voiceDuration ?? voiceDuration,
              senderName: mapped.senderName,
              senderAvatarPath: mapped.senderAvatarPath,
              createdAt: mapped.createdAt,
              replyToId: mapped.replyToId ?? optimistic.replyToId,
              replyToText: mapped.replyToText ?? optimistic.replyToText,
              replyToIsMine: mapped.replyToIsMine ?? optimistic.replyToIsMine,
              isMine: true,
            );

      final idx = _messages.indexWhere((m) => m.id == optimistic.id);
      final already = _messages.any((m) => m.id == saved.id);
      if (idx >= 0) {
        if (already) {
          _removeMessageAt(idx, animate: true);
        } else {
          _replaceMessageAt(idx, resolved, animate: false);
        }
      } else if (!already) {
        _addMessage(resolved);
      }
      _scrollToBottom(forceJump: true);
    } catch (_) {
      if (!mounted) return;
      final idx = _messages.indexWhere((m) => m.id == optimistic.id);
      if (idx >= 0) _removeMessageAt(idx, animate: true);
      AppSnackbar.instance.show(
        context,
        'chat_send_failed'.tr(),
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
      await _prepareAndStartRecording();
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
    await _sendMediaMessage(
      type: 'voice',
      mediaPath: path,
      voiceDuration: elapsed,
      body: '${elapsed.inMilliseconds}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      // Scaffold already lifts for the keyboard — do not also add viewInsets.
      body: SafeArea(
        child: Column(
          children: [
            _ChatDetailHeader(
              args: widget.args,
              title: _headerName,
              avatarPath: _avatarPath,
              memberCount: _memberCount,
              conversationId: (_conversationId ?? widget.args.conversationId)
                  .trim(),
              onBack: _popDetail,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: Divider(
                height: 1,
                thickness: 1,
                color: AppColors.borderLight,
              ),
            ),
            if (_isRequest)
              _ChatRequestActionsBanner(
                busy: _requestActionBusy,
                onAccept: _acceptRequest,
                onBlock: _blockRequest,
              ),
            Expanded(
              child: _showShimmer
                  ? const _ChatMessagesShimmer()
                  : AnimatedList(
                      key: _listKey,
                      controller: _scrollController,
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
                      initialItemCount: _messages.length,
                      itemBuilder: (context, index, animation) {
                        if (index < 0 || index >= _messages.length) {
                          return const SizedBox.shrink();
                        }
                        final message = _messages[index];
                        return _AnimatedMessageTile(
                          animation: animation,
                          message: message,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: _SwipeToReply(
                              onReply: () => _startReply(message),
                              child: _MessageBubble(
                                message: message,
                                avatarPath: _avatarPath,
                                username: widget.args.username,
                                isGroup: widget.args.isGroup,
                                peerName: widget.args.name,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_replyingTo != null) ...[
                    _ReplyComposerBar(
                      message: _replyingTo!,
                      peerName: widget.args.name,
                      onCancel: _cancelReply,
                    ),
                    const SizedBox(height: 8),
                  ],
                  _isRecording
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
                ],
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
    this.id,
    this.text,
    this.stampPath,
    this.imagePath,
    this.voicePath,
    this.voiceDuration,
    this.senderName,
    this.senderUsername,
    this.senderAvatarPath,
    this.createdAt,
    this.replyToId,
    this.replyToText,
    this.replyToIsMine,
    required this.isMine,
  });

  final String? id;
  final String? text;
  final String? stampPath;
  final String? imagePath;
  final String? voicePath;
  final Duration? voiceDuration;
  final String? senderName;
  final String? senderUsername;
  final String? senderAvatarPath;
  final DateTime? createdAt;
  final String? replyToId;
  final String? replyToText;
  final bool? replyToIsMine;
  final bool isMine;

  bool get isStamp => stampPath != null;
  bool get isImage => imagePath != null;
  bool get isVoice => voicePath != null;
  bool get hasReply =>
      (replyToText?.trim().isNotEmpty ?? false) ||
      (replyToId?.trim().isNotEmpty ?? false);
}

class _ChatMessagesShimmer extends StatelessWidget {
  const _ChatMessagesShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8E8E8),
      highlightColor: const Color(0xFFF5F5F5),
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        children: const [
          _ChatBubbleShimmer(isMine: false, width: 180),
          _ChatBubbleShimmer(isMine: true, width: 140),
          _ChatBubbleShimmer(isMine: false, width: 220),
          _ChatBubbleShimmer(isMine: true, width: 100),
          _ChatBubbleShimmer(isMine: false, width: 160),
          _ChatBubbleShimmer(isMine: true, width: 190),
        ],
      ),
    );
  }
}

class _ChatBubbleShimmer extends StatelessWidget {
  const _ChatBubbleShimmer({required this.isMine, required this.width});

  final bool isMine;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: width,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

class _SwipeToReply extends StatefulWidget {
  const _SwipeToReply({required this.child, required this.onReply});

  final Widget child;
  final VoidCallback onReply;

  @override
  State<_SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<_SwipeToReply>
    with SingleTickerProviderStateMixin {
  static const _threshold = 56.0;
  static const _maxDrag = 72.0;

  /// Leave the left edge free for iOS / system back gesture.
  static const _edgeBackReserve = 28.0;

  double _dx = 0;
  double _snapFrom = 0;
  bool _ignoreDrag = false;
  late final AnimationController _spring;

  @override
  void initState() {
    super.initState();
    _spring =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 220),
        )..addListener(() {
          setState(() {
            _dx =
                _snapFrom * (1 - Curves.easeOutCubic.transform(_spring.value));
          });
        });
  }

  @override
  void dispose() {
    _spring.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    _ignoreDrag = details.globalPosition.dx < _edgeBackReserve;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_ignoreDrag) return;
    if (_spring.isAnimating) _spring.stop();
    final next = (_dx + details.delta.dx).clamp(-_maxDrag, _maxDrag);
    setState(() => _dx = next);
  }

  void _onDragEnd(DragEndDetails details) {
    if (_ignoreDrag) {
      _ignoreDrag = false;
      return;
    }
    final triggered = _dx.abs() >= _threshold;
    if (triggered) widget.onReply();
    _snapFrom = _dx;
    _spring.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_dx.abs() / _threshold).clamp(0.0, 1.0);
    final iconOnLeft = _dx > 0;

    // Stack’i child boyutuna kilitle — Align ile full-width expand
    // reply bubble’ların avatar’ın altına taşmasına yol açıyordu.
    return GestureDetector(
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (progress > 0)
            Positioned(
              left: iconOnLeft ? 0 : null,
              right: iconOnLeft ? null : 0,
              top: 0,
              bottom: 0,
              child: Opacity(
                opacity: progress,
                child: Align(
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.reply_rounded,
                    size: 22,
                    color: AppColors.zoviOrange.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
          Transform.translate(offset: Offset(_dx, 0), child: widget.child),
        ],
      ),
    );
  }
}

class _ReplyComposerBar extends StatelessWidget {
  const _ReplyComposerBar({
    required this.message,
    required this.peerName,
    required this.onCancel,
  });

  final _ChatMessage message;
  final String peerName;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final label = message.isMine
        ? 'chat_reply_you'.tr()
        : (peerName.trim().isNotEmpty ? peerName : 'chat_replying_to'.tr());
    final preview = message.text?.trim().isNotEmpty == true
        ? message.text!.trim()
        : message.isImage
        ? '📷'
        : message.isVoice
        ? '🎤'
        : message.isStamp
        ? '🏷️'
        : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceGray,
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          left: BorderSide(color: AppColors.zoviOrange, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${'chat_replying_to'.tr()} $label',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    color: AppColors.zoviOrange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.2,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCancel,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close_rounded, size: 20),
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _QuotedReplyBlock extends StatelessWidget {
  const _QuotedReplyBlock({
    required this.preview,
    required this.label,
    required this.isMineBubble,
  });

  final String preview;
  final String label;
  final bool isMineBubble;

  @override
  Widget build(BuildContext context) {
    final barColor = isMineBubble
        ? AppColors.white.withValues(alpha: 0.85)
        : AppColors.zoviOrange;
    final labelColor = isMineBubble
        ? AppColors.white.withValues(alpha: 0.95)
        : AppColors.zoviOrange;
    final textColor = isMineBubble
        ? AppColors.white.withValues(alpha: 0.85)
        : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: isMineBubble
            ? AppColors.black.withValues(alpha: 0.12)
            : AppColors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: barColor, width: 3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.2,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            preview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.25,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedMessageTile extends StatelessWidget {
  const _AnimatedMessageTile({
    required this.animation,
    required this.message,
    required this.child,
  });

  final Animation<double> animation;
  final _ChatMessage message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final begin = Offset(message.isMine ? 0.18 : -0.18, 0.12);
    // Avoid SizeTransition — its ClipRect clips horizontal swipe overflow.
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: begin, end: Offset.zero).animate(curved),
        child: AnimatedBuilder(
          animation: curved,
          builder: (context, child) {
            final t = curved.value.clamp(0.0, 1.0);
            return Align(
              alignment: Alignment.topCenter,
              heightFactor: t <= 0 ? 0.0001 : t,
              child: child,
            );
          },
          child: child,
        ),
      ),
    );
  }
}

class _ChatRequestActionsBanner extends StatelessWidget {
  const _ChatRequestActionsBanner({
    required this.busy,
    required this.onAccept,
    required this.onBlock,
  });

  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onBlock;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceGray,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'chat_request_banner'.tr(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.35,
              letterSpacing: -0.2,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: Material(
                    color: AppColors.white,
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: AppColors.logoutRed.withValues(alpha: 0.35),
                      ),
                    ),
                    child: InkWell(
                      onTap: busy ? null : onBlock,
                      customBorder: const StadiumBorder(),
                      child: Center(
                        child: Text(
                          'chat_request_block'.tr(),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.logoutRed,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: Material(
                    color: AppColors.deepRoast,
                    shape: const StadiumBorder(),
                    child: InkWell(
                      onTap: busy ? null : onAccept,
                      customBorder: const StadiumBorder(),
                      child: Center(
                        child: Text(
                          'chat_request_accept'.tr(),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white.withValues(
                              alpha: busy ? 0.65 : 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChatDetailHeader extends StatelessWidget {
  const _ChatDetailHeader({
    required this.args,
    required this.title,
    required this.avatarPath,
    required this.memberCount,
    required this.conversationId,
    required this.onBack,
  });

  final ChatDetailRouteArgs args;
  final String title;
  final String avatarPath;
  final int memberCount;
  final String conversationId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final subtitle = args.isGroup
        ? 'chat_member_count'.tr(namedArgs: {'count': '$memberCount'})
        : (args.lastActive.trim().isEmpty
              ? ''
              : 'chat_active_ago'.tr(namedArgs: {'time': args.lastActive}));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: const AppIcon(AssetPaths.iconArrowLeft),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: args.isGroup
                  ? null
                  : () => openUserProfile(context, args.username),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  ProfileAvatar(path: avatarPath, size: 40),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.isNotEmpty ? title : args.name,
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
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (args.isGroup) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                context.push(
                  RoutePaths.groupInfo.path,
                  extra: GroupInfoRouteArgs(
                    name: title.isNotEmpty ? title : args.name,
                    avatarPath: avatarPath,
                    memberCount: memberCount,
                    tribeId: args.tribeId,
                    conversationId: conversationId,
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
    required this.username,
    required this.isGroup,
    this.peerName = '',
  });

  final _ChatMessage message;
  final String avatarPath;
  final String username;
  final bool isGroup;
  final String peerName;

  void _openMedia(
    BuildContext context, {
    required String heroTag,
    String? assetPath,
    String? filePath,
    String? networkUrl,
  }) {
    showChatMediaViewer(
      context,
      heroTag: heroTag,
      assetPath: assetPath,
      filePath: filePath,
      networkUrl: networkUrl,
    );
  }

  Widget _wrapIncoming({required BuildContext context, required Widget child}) {
    final senderAvatar = message.senderAvatarPath ?? avatarPath;
    final senderName = message.senderName;
    final profileKey = isGroup
        ? ((message.senderUsername?.trim().isNotEmpty ?? false)
              ? message.senderUsername!.trim()
              : (senderName ?? username))
        : username;

    final avatar = GestureDetector(
      onTap: () => openUserProfile(context, profileKey),
      behavior: HitTestBehavior.opaque,
      child: ProfileAvatar(path: senderAvatar, size: 32),
    );

    if (!isGroup) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          avatar,
          const SizedBox(width: 8),
          Flexible(
            child: Align(alignment: Alignment.centerLeft, child: child),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        avatar,
        const SizedBox(width: 8),
        Flexible(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (senderName != null && senderName.isNotEmpty) ...[
                  GestureDetector(
                    onTap: () => openUserProfile(context, profileKey),
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      senderName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1,
                        letterSpacing: -0.28,
                        color: AppColors.zoviOrange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                child,
              ],
            ),
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
          child: StampImage(
            path: message.stampPath!,
            width: 140,
            height: 140,
            fit: BoxFit.contain,
          ),
        ),
      );
      if (message.isMine) {
        return Align(alignment: Alignment.centerRight, child: stamp);
      }
      return _wrapIncoming(context: context, child: stamp);
    }

    if (message.isImage) {
      final heroTag = 'chat_image_${identityHashCode(message)}';
      final path = message.imagePath!;
      final isNetwork = StampImage.isNetworkPath(path);
      final image = GestureDetector(
        onTap: () => isNetwork
            ? _openMedia(context, heroTag: heroTag, networkUrl: path)
            : _openMedia(context, heroTag: heroTag, filePath: path),
        child: Hero(
          tag: heroTag,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: isNetwork
                ? Image.network(
                    path,
                    width: 220,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 220,
                      height: 220,
                      color: AppColors.surfaceGray,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  )
                : Image.file(
                    File(path),
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
      return _wrapIncoming(context: context, child: image);
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
      return _wrapIncoming(context: context, child: voice);
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.hasReply) ...[
                  _QuotedReplyBlock(
                    preview: message.replyToText ?? '',
                    label: message.replyToIsMine == true
                        ? 'chat_reply_you'.tr()
                        : (peerName.trim().isNotEmpty ? peerName : username),
                    isMineBubble: true,
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  message.text!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 20 / 16,
                    letterSpacing: -0.32,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final bubble = LayoutBuilder(
      builder: (context, constraints) {
        final maxBubbleWidth = math.min(
          constraints.maxWidth,
          MediaQuery.sizeOf(context).width * 0.72,
        );
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxBubbleWidth),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.hasReply) ...[
                  _QuotedReplyBlock(
                    preview: message.replyToText ?? '',
                    label: message.replyToIsMine == true
                        ? 'chat_reply_you'.tr()
                        : (peerName.trim().isNotEmpty ? peerName : username),
                    isMineBubble: false,
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  message.text!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 20 / 16,
                    letterSpacing: -0.32,
                    color: AppColors.deepRoast,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    return _wrapIncoming(context: context, child: bubble);
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
    final path = widget.path;
    final source = path.startsWith('http://') || path.startsWith('https://')
        ? UrlSource(path)
        : DeviceFileSource(path);
    await _player.play(source);
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
