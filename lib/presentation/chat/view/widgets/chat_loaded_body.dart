part of '../chat_view.dart';

@immutable
final class _ChatPreview {
  const _ChatPreview({
    required this.conversationId,
    required this.userId,
    required this.name,
    required this.username,
    required this.avatarPath,
    required this.preview,
    required this.isUnread,
    required this.isGroup,
    required this.tribeId,
    this.memberCount = 0,
  });

  factory _ChatPreview.fromConversation(ChatConversation c) {
    final name = c.peer.name.trim().isNotEmpty
        ? c.peer.name.trim()
        : (c.peer.username.trim().isNotEmpty ? c.peer.username : 'user');
    var avatarPath = c.peer.avatarUrl.trim();
    var memberCount = c.peer.memberCount;
    if (c.peer.isGroup && c.peer.tribeId.isNotEmpty) {
      final tribe = getIt<TribeRepository>().findCachedTribe(
        tribeId: c.peer.tribeId,
        conversationId: c.id,
      );
      if (tribe != null) {
        if (avatarPath.isEmpty && tribe.photoUrl.isEmpty) {
          avatarPath = tribe.displayAvatarPath;
        } else if (tribe.photoUrl.isNotEmpty) {
          avatarPath = tribe.photoUrl;
        }
        if (memberCount <= 0 && tribe.memberCount > 0) {
          memberCount = tribe.memberCount;
        }
      }
    }
    if (c.peer.isGroup && avatarPath.isEmpty) {
      avatarPath = AssetPaths.iconTribeNonamePhoto;
    }
    return _ChatPreview(
      conversationId: c.id,
      userId: c.peer.userId,
      name: name,
      username: c.peer.username,
      avatarPath: avatarPath,
      preview: c.lastMessagePreview,
      isUnread: c.isUnread,
      isGroup: c.peer.isGroup,
      tribeId: c.peer.tribeId,
      memberCount: memberCount,
    );
  }

  final String conversationId;
  final String userId;
  final String name;
  final String username;
  final String avatarPath;
  final String preview;
  final bool isUnread;
  final bool isGroup;
  final String tribeId;
  final int memberCount;

  _ChatPreview copyWith({bool? isUnread, String? preview}) {
    return _ChatPreview(
      conversationId: conversationId,
      userId: userId,
      name: name,
      username: username,
      avatarPath: avatarPath,
      preview: preview ?? this.preview,
      isUnread: isUnread ?? this.isUnread,
      isGroup: isGroup,
      tribeId: tribeId,
      memberCount: memberCount,
    );
  }
}

@immutable
final class ChatLoadedBody extends StatefulWidget {
  const ChatLoadedBody({super.key});

  @override
  State<ChatLoadedBody> createState() => _ChatLoadedBodyState();
}

final class _ChatLoadedBodyState extends State<ChatLoadedBody>
    with WidgetsBindingObserver {
  static const _removeDuration = Duration(milliseconds: 280);
  static const _pollInterval = Duration(seconds: 8);

  final _repo = getIt<ChatRepository>();
  final List<_ChatPreview> _chats = [];
  List<ChatRequestItem> _requests = [];
  late List<_ChatPreview> _visibleChats;
  var _listKey = GlobalKey<AnimatedListState>();
  var _query = '';
  var _loading = false;
  String? _openedSwipeUsername;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _hydrateFromCache();
    unawaited(_refresh(silent: true));
    _poll = Timer.periodic(
      _pollInterval,
      (_) => unawaited(_refresh(silent: true)),
    );
  }

  void _hydrateFromCache() {
    final inbox = _repo.peekConversations(folder: 'inbox');
    final requests = _repo.peekConversations(folder: 'request');
    if (inbox == null && requests == null) {
      _visibleChats = [];
      _loading = false;
      return;
    }
    _chats
      ..clear()
      ..addAll((inbox ?? const []).map(_ChatPreview.fromConversation));
    _requests = [
      for (final c in requests ?? const <ChatConversation>[])
        ChatRequestItem(
          conversationId: c.id,
          userId: c.peer.userId,
          name: c.peer.name.trim().isNotEmpty
              ? c.peer.name.trim()
              : c.peer.username,
          username: c.peer.username,
          avatarPath: c.peer.avatarUrl,
          preview: c.lastMessagePreview,
          isUnread: c.isUnread,
        ),
    ];
    _visibleChats = _filter(_query);
    _loading = false;
  }

  @override
  void dispose() {
    _poll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh(silent: true));
  }

  Future<void> _refresh({bool silent = false}) async {
    try {
      final results = await Future.wait([
        _repo.listConversations(folder: 'inbox'),
        _repo.listConversations(folder: 'request'),
      ]);
      if (!mounted) return;
      final inbox = results[0];
      final requests = results[1];
      setState(() {
        _chats
          ..clear()
          ..addAll(inbox.map(_ChatPreview.fromConversation));
        _requests = [
          for (final c in requests)
            ChatRequestItem(
              conversationId: c.id,
              userId: c.peer.userId,
              name: c.peer.name.trim().isNotEmpty
                  ? c.peer.name.trim()
                  : c.peer.username,
              username: c.peer.username,
              avatarPath: c.peer.avatarUrl,
              preview: c.lastMessagePreview,
              isUnread: c.isUnread,
            ),
        ];
        _visibleChats = _filter(_query);
        if (!silent) _listKey = GlobalKey<AnimatedListState>();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (!silent) setState(() => _loading = false);
    }
  }

  List<_ChatPreview> _filter(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return List<_ChatPreview>.from(_chats);
    return _chats
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.username.toLowerCase().contains(q),
        )
        .toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _query = value;
      _visibleChats = _filter(_query);
      _openedSwipeUsername = null;
      _listKey = GlobalKey<AnimatedListState>();
    });
  }

  Future<void> _openChat(_ChatPreview chat) async {
    if (_openedSwipeUsername != null) {
      setState(() => _openedSwipeUsername = null);
      return;
    }
    await context.push(
      RoutePaths.chatDetail.path,
      extra: ChatDetailRouteArgs(
        name: chat.name,
        username: chat.username,
        avatarPath: chat.avatarPath,
        userId: chat.userId,
        conversationId: chat.conversationId,
        isGroup: chat.isGroup,
        tribeId: chat.tribeId,
        memberCount: chat.isGroup && chat.memberCount > 0
            ? chat.memberCount
            : null,
      ),
    );
    if (!mounted) return;
    unawaited(_refresh(silent: true));
  }

  Future<void> _confirmDeleteChat(_ChatPreview chat) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'chat_delete_title'.tr(),
      subtitle: 'chat_delete_subtitle'.tr(),
      confirmLabel: 'chat_delete_confirm'.tr(),
    );
    if (!confirmed || !mounted) return;

    final index = _visibleChats.indexWhere(
      (c) => c.conversationId == chat.conversationId,
    );
    if (index < 0) return;

    final removed = _visibleChats.removeAt(index);
    _chats.removeWhere((c) => c.conversationId == removed.conversationId);
    _openedSwipeUsername = null;

    _listKey.currentState?.removeItem(
      index,
      (context, animation) =>
          _ChatRemoveTile(chat: removed, animation: animation),
      duration: _removeDuration,
    );

    if (_visibleChats.isEmpty) {
      Future<void>.delayed(_removeDuration, () {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }

    try {
      await _repo.deleteConversation(chat.conversationId);
    } catch (_) {
      unawaited(_refresh());
    }
  }

  Future<void> _openRequests() async {
    final updated = await context.push<List<ChatRequestItem>>(
      RoutePaths.chatRequests.path,
      extra: ChatRequestsRouteArgs(requests: _requests),
    );
    if (!mounted) return;
    if (updated != null) {
      setState(() => _requests = updated);
    }
    unawaited(_refresh(silent: true));
  }

  @override
  Widget build(BuildContext context) {
    final requestCount = _requests.length;
    final hasRequests = requestCount > 0;
    final isEmpty = !_loading && _visibleChats.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Text(
            'chat_title'.tr(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1,
              letterSpacing: -0.32,
              color: AppColors.black,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AppSearchField(
            hintText: 'chat_search_friends'.tr(),
            onDebouncedChanged: _onSearchChanged,
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'chat_messages'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1,
                  letterSpacing: -0.32,
                  color: AppColors.black,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _openRequests,
                behavior: HitTestBehavior.opaque,
                child: Text(
                  hasRequests
                      ? 'chat_request_count'.tr(
                          namedArgs: {'count': '$requestCount'},
                        )
                      : 'chat_request'.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1,
                    letterSpacing: -0.28,
                    color: hasRequests
                        ? AppColors.zoviOrange
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _loading
              ? const AppLoading(size: 28)
              : isEmpty
              ? _ChatEmptyState(isSearching: _query.trim().isNotEmpty)
              : AnimatedList(
                  key: _listKey,
                  clipBehavior: Clip.none,
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom:
                        MainWrapper.navBarHeight +
                        MediaQuery.paddingOf(context).bottom,
                  ),
                  initialItemCount: _visibleChats.length,
                  itemBuilder: (context, index, animation) {
                    final chat = _visibleChats[index];
                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        index == _visibleChats.length - 1 ? 0 : 16,
                      ),
                      child: ChatListItemTransition(
                        animation: animation,
                        child: ChatSwipeDeleteTile(
                          isOpen: _openedSwipeUsername == chat.username,
                          onOpenChanged: (open) {
                            setState(() {
                              _openedSwipeUsername = open
                                  ? chat.username
                                  : null;
                            });
                          },
                          onDeleteTap: () => _confirmDeleteChat(chat),
                          child: _ChatTile(
                            chat: chat,
                            onTap: () => _openChat(chat),
                            onAvatarTap: () {
                              if (chat.isGroup) return;
                              openUserProfile(context, chat.username);
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

@immutable
final class _ChatRemoveTile extends StatelessWidget {
  const _ChatRemoveTile({required this.chat, required this.animation});

  final _ChatPreview chat;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return ChatListItemTransition(
      animation: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-0.12, 0),
          end: Offset.zero,
        ).animate(animation),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _ChatTile(chat: chat, onTap: () {}, onAvatarTap: () {}),
        ),
      ),
    );
  }
}

@immutable
final class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState({required this.isSearching});

  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              isSearching ? AssetPaths.iconSearch : AssetPaths.iconChat,
              size: 40,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              isSearching ? 'chat_empty_search'.tr() : 'chat_empty'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@immutable
final class _ChatTile extends StatelessWidget {
  const _ChatTile({
    required this.chat,
    required this.onTap,
    required this.onAvatarTap,
  });

  final _ChatPreview chat;
  final VoidCallback onTap;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: ProfileAvatar(path: chat.avatarPath, size: 56),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chat.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    letterSpacing: -0.32,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                ChatLastMessagePreview(
                  preview: chat.preview,
                  isUnread: chat.isUnread,
                ),
              ],
            ),
          ),
          if (chat.isUnread) ...[
            const SizedBox(width: 10),
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.zoviOrange,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
