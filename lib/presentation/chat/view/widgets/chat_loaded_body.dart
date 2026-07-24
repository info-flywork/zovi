part of '../chat_view.dart';

class _ChatPreview {
  const _ChatPreview({
    required this.name,
    required this.username,
    required this.avatarPath,
    required this.preview,
    required this.isUnread,
  });

  final String name;
  final String username;
  final String avatarPath;
  final String preview;
  final bool isUnread;

  _ChatPreview copyWith({bool? isUnread}) {
    return _ChatPreview(
      name: name,
      username: username,
      avatarPath: avatarPath,
      preview: preview,
      isUnread: isUnread ?? this.isUnread,
    );
  }
}

class ChatLoadedBody extends StatefulWidget {
  const ChatLoadedBody({super.key});

  @override
  State<ChatLoadedBody> createState() => _ChatLoadedBodyState();
}

class _ChatLoadedBodyState extends State<ChatLoadedBody> {
  static const _removeDuration = Duration(milliseconds: 280);

  late final List<_ChatPreview> _chats = [
    const _ChatPreview(
      name: 'Sona Iglesias',
      username: 'sonaiglesias',
      avatarPath: AssetPaths.avatarSona,
      preview: 'Hey!',
      isUnread: true,
    ),
    const _ChatPreview(
      name: 'Jessica Blues',
      username: 'jessicablues',
      avatarPath: AssetPaths.avatarJessica,
      preview: 'Hey! I was about to explode with boredom.',
      isUnread: false,
    ),
  ];

  late List<ChatRequestItem> _requests = [
    const ChatRequestItem(
      name: 'Julia Ivanova',
      username: 'juliaivanova',
      avatarPath: AssetPaths.avatarJulia,
      preview:
          'Hey! I was about to explode with boredom. Your energy has reached me!',
    ),
  ];

  late List<_ChatPreview> _visibleChats;
  var _listKey = GlobalKey<AnimatedListState>();
  var _query = '';
  String? _openedSwipeUsername;

  @override
  void initState() {
    super.initState();
    _visibleChats = List<_ChatPreview>.from(_chats);
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
      ),
    );
    if (!mounted) return;
    final index = _chats.indexWhere((c) => c.username == chat.username);
    if (index < 0 || !_chats[index].isUnread) return;
    setState(() {
      _chats[index] = _chats[index].copyWith(isUnread: false);
      final visibleIndex = _visibleChats.indexWhere(
        (c) => c.username == chat.username,
      );
      if (visibleIndex >= 0) {
        _visibleChats[visibleIndex] = _chats[index];
      }
    });
  }

  Future<void> _confirmDeleteChat(_ChatPreview chat) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'chat_delete_title'.tr(),
      subtitle: 'chat_delete_subtitle'.tr(),
      confirmLabel: 'chat_delete_confirm'.tr(),
    );
    if (!confirmed || !mounted) return;

    final index = _visibleChats.indexWhere((c) => c.username == chat.username);
    if (index < 0) return;

    final removed = _visibleChats.removeAt(index);
    _chats.removeWhere((c) => c.username == removed.username);
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
    }
  }

  Future<void> _openRequests() async {
    final updated = await context.push<List<ChatRequestItem>>(
      RoutePaths.chatRequests.path,
      extra: ChatRequestsRouteArgs(requests: _requests),
    );
    if (!mounted || updated == null) return;
    setState(() => _requests = updated);
  }

  @override
  Widget build(BuildContext context) {
    final requestCount = _requests.length;
    final hasRequests = requestCount > 0;
    final isEmpty = _visibleChats.isEmpty;

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
          child: isEmpty
              ? _ChatEmptyState(isSearching: _query.trim().isNotEmpty)
              : AnimatedList(
                  key: _listKey,
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    MainWrapper.navBarHeight +
                        MediaQuery.paddingOf(context).bottom,
                  ),
                  initialItemCount: _visibleChats.length,
                  itemBuilder: (context, index, animation) {
                    final chat = _visibleChats[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == _visibleChats.length - 1 ? 0 : 16,
                      ),
                      child: SizeTransition(
                        sizeFactor: animation,
                        alignment: Alignment(-1, 0),
                        child: FadeTransition(
                          opacity: animation,
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
                              onAvatarTap: () =>
                                  openUserProfile(context, chat.username),
                            ),
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

class _ChatRemoveTile extends StatelessWidget {
  const _ChatRemoveTile({required this.chat, required this.animation});

  final _ChatPreview chat;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: animation,
      alignment: Alignment(-1, 0),
      child: FadeTransition(
        opacity: animation,
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
      ),
    );
  }
}

class _ChatEmptyState extends StatelessWidget {
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
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              isSearching ? 'chat_empty_search'.tr() : 'chat_empty'.tr(),
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

class _ChatTile extends StatelessWidget {
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            behavior: HitTestBehavior.opaque,
            child: ClipOval(
              child: Image.asset(
                chat.avatarPath,
                width: 58,
                height: 58,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chat.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1,
                    letterSpacing: -0.32,
                    color: AppColors.deepRoast,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  chat.preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 20 / 16,
                    letterSpacing: -0.32,
                    color: chat.isUnread
                        ? AppColors.black
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (chat.isUnread) ...[
            const SizedBox(width: 10),
            Container(
              width: 9,
              height: 9,
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
