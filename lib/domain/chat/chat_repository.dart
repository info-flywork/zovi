import 'package:flutter/foundation.dart';
import 'package:zovi/core/network/network_manager.dart';
import 'package:zovi/core/utils/enum/request_type.dart';

@immutable
final class ChatPeer {
  const ChatPeer({
    required this.userId,
    required this.name,
    required this.username,
    required this.avatarUrl,
    this.isGroup = false,
    this.tribeId = '',
    this.memberCount = 0,
  });

  factory ChatPeer.fromJson(Map<String, dynamic> json) {
    return ChatPeer(
      userId: (json['userId'] as String?)?.trim() ?? '',
      name: (json['name'] as String?)?.trim() ?? '',
      username: (json['username'] as String?)?.trim() ?? '',
      avatarUrl: (json['avatarUrl'] as String?)?.trim() ?? '',
      isGroup: json['isGroup'] == true,
      tribeId: (json['tribeId'] as String?)?.trim() ?? '',
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
    );
  }

  final String userId;
  final String name;
  final String username;
  final String avatarUrl;
  final bool isGroup;
  final String tribeId;
  final int memberCount;
}

@immutable
final class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.folder,
    required this.unreadCount,
    required this.lastMessagePreview,
    required this.peer,
    this.lastMessageAt,
    this.lastMessageSenderId,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final peerRaw = json['peer'];
    return ChatConversation(
      id: (json['id'] as String?)?.trim() ?? '',
      folder: (json['folder'] as String?)?.trim() ?? 'inbox',
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      lastMessagePreview: (json['lastMessagePreview'] as String?)?.trim() ?? '',
      lastMessageAt: DateTime.tryParse(
        '${json['lastMessageAt'] ?? ''}',
      )?.toLocal(),
      lastMessageSenderId: (json['lastMessageSenderId'] as String?)?.trim(),
      peer: peerRaw is Map
          ? ChatPeer.fromJson(Map<String, dynamic>.from(peerRaw))
          : const ChatPeer(
              userId: '',
              name: '',
              username: '',
              avatarUrl: '',
              memberCount: 0,
            ),
    );
  }

  final String id;
  final String folder;
  final int unreadCount;
  final String lastMessagePreview;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;
  final ChatPeer peer;

  bool get isRequest => folder == 'request';
  bool get isUnread => unreadCount > 0;
}

@immutable
final class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.type,
    required this.body,
    required this.mediaUrl,
    required this.createdAt,
    this.replyToMessageId,
    this.replyPreview = '',
    this.senderName = '',
    this.senderUsername = '',
    this.senderAvatarUrl = '',
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['id'] as String?)?.trim() ?? '',
      conversationId: (json['conversationId'] as String?)?.trim() ?? '',
      senderId: (json['senderId'] as String?)?.trim() ?? '',
      type: (json['type'] as String?)?.trim() ?? 'text',
      body: (json['body'] as String?)?.trim() ?? '',
      mediaUrl: (json['mediaUrl'] as String?)?.trim() ?? '',
      replyToMessageId: (json['replyToMessageId'] as String?)?.trim(),
      replyPreview: (json['replyPreview'] as String?)?.trim() ?? '',
      createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}')?.toLocal(),
      senderName: (json['senderName'] as String?)?.trim() ?? '',
      senderUsername: (json['senderUsername'] as String?)?.trim() ?? '',
      senderAvatarUrl: (json['senderAvatarUrl'] as String?)?.trim() ?? '',
    );
  }

  final String id;
  final String conversationId;
  final String senderId;
  final String type;
  final String body;
  final String mediaUrl;
  final String? replyToMessageId;
  final String replyPreview;
  final DateTime? createdAt;
  final String senderName;
  final String senderUsername;
  final String senderAvatarUrl;

  bool get isStoryReply => isStoryReplyPreview(replyPreview);
}

bool isStoryReplyPreview(String? preview) {
  final value = (preview ?? '').trim();
  if (value.isEmpty) return false;
  return value == 'story' ||
      value.startsWith('story:') ||
      value == 'pulse' ||
      value.startsWith('pulse:');
}

String storyReplyPreviewFor({String? storyId, bool isPulse = false}) {
  final id = (storyId ?? '').trim();
  if (isPulse) return id.isEmpty ? 'pulse' : 'pulse:$id';
  return id.isEmpty ? 'story' : 'story:$id';
}

const _stampReplyPrefix = 'stamp:';

String stampReplyPreviewFor(String path) {
  final p = path.trim();
  if (p.isEmpty) return '🏷️';
  final encoded = '$_stampReplyPrefix$p';
  return encoded.length <= 280 ? encoded : '🏷️';
}

String? stampPathFromReplyPreview(String? preview) {
  final value = (preview ?? '').trim();
  if (value.startsWith(_stampReplyPrefix)) {
    final path = value.substring(_stampReplyPrefix.length).trim();
    return path.isEmpty ? null : path;
  }
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }
  return null;
}

String? storyIdFromReplyPreview(String? preview) {
  final value = (preview ?? '').trim();
  if (value.startsWith('story:')) {
    final id = value.substring(6).trim();
    return id.isEmpty ? null : id;
  }
  return null;
}

final class ChatRepository {
  ChatRepository(this._network);

  final NetworkManager _network;

  /// peerUserId → son bilinen DM. Profile "Mesaj gönder" her seferinde
  /// POST /chat/conversations atmasın diye.
  final Map<String, ChatConversation> _dmByPeerId = {};
  final Map<String, Future<ChatConversation>> _openDmInFlight = {};

  ChatConversation? peekDm(String peerUserId) {
    final peer = peerUserId.trim();
    if (peer.isEmpty) return null;
    return _dmByPeerId[peer];
  }

  void rememberConversation(ChatConversation conversation) {
    final peer = conversation.peer.userId.trim();
    final id = conversation.id.trim();
    if (peer.isEmpty || id.isEmpty) return;
    _dmByPeerId[peer] = conversation;
  }

  void forgetConversation(String conversationId) {
    final id = conversationId.trim();
    if (id.isEmpty) return;
    _dmByPeerId.removeWhere((_, c) => c.id == id);
  }

  void clearDmCache() {
    _dmByPeerId.clear();
    _openDmInFlight.clear();
  }

  Future<List<ChatConversation>> listConversations({
    required String folder,
    int limit = 50,
  }) async {
    final result = await _network.send<Map<String, dynamic>>(
      path: '/chat/conversations',
      method: RequestType.get,
      queryParameters: {'folder': folder, 'limit': '$limit'},
      parserModel: (json) => json,
    );
    final raw = result?['conversations'];
    if (raw is! List) return const [];
    final list = [
      for (final item in raw)
        if (item is Map)
          ChatConversation.fromJson(Map<String, dynamic>.from(item)),
    ];
    for (final c in list) {
      rememberConversation(c);
    }
    return list;
  }

  Future<ChatConversation> openDm(String peerUserId) async {
    final peer = peerUserId.trim();
    if (peer.isEmpty) {
      throw StateError('peerUserId is required');
    }

    final cached = _dmByPeerId[peer];
    if (cached != null) return cached;

    final inFlight = _openDmInFlight[peer];
    if (inFlight != null) return inFlight;

    final future = _openDmNetwork(peer);
    _openDmInFlight[peer] = future;
    try {
      final opened = await future;
      rememberConversation(opened);
      return opened;
    } finally {
      _openDmInFlight.remove(peer);
    }
  }

  Future<ChatConversation> _openDmNetwork(String peerUserId) async {
    final result = await _network.send<Map<String, dynamic>>(
      path: '/chat/conversations',
      method: RequestType.post,
      data: {'peerUserId': peerUserId},
      parserModel: (json) => json,
    );
    final raw = result?['conversation'];
    if (raw is! Map) {
      throw StateError('Failed to open conversation');
    }
    return ChatConversation.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<List<ChatMessage>> listMessages(
    String conversationId, {
    int limit = 50,
    DateTime? before,
    DateTime? after,
  }) async {
    final result = await _network.send<Map<String, dynamic>>(
      path:
          '/chat/conversations/${Uri.encodeComponent(conversationId)}/messages',
      method: RequestType.get,
      queryParameters: {
        'limit': '$limit',
        if (before != null) 'before': before.toUtc().toIso8601String(),
        if (after != null) 'after': after.toUtc().toIso8601String(),
      },
      parserModel: (json) => json,
    );
    final raw = result?['messages'];
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map) ChatMessage.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  Future<ChatConversation> acceptConversation(String conversationId) async {
    final result = await _network.send<Map<String, dynamic>>(
      path: '/chat/conversations/${Uri.encodeComponent(conversationId)}/accept',
      method: RequestType.post,
      parserModel: (json) => json,
    );
    final raw = result?['conversation'];
    if (raw is! Map) {
      throw StateError('Failed to accept conversation');
    }
    return ChatConversation.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<void> blockConversation(String conversationId) async {
    await _network.send<Map<String, dynamic>>(
      path: '/chat/conversations/${Uri.encodeComponent(conversationId)}/block',
      method: RequestType.post,
      parserModel: (json) => json,
    );
  }

  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String type,
    String? body,
    String? mediaUrl,
    String? replyToMessageId,
    String? replyPreview,
  }) async {
    final result = await _network.send<Map<String, dynamic>>(
      path:
          '/chat/conversations/${Uri.encodeComponent(conversationId)}/messages',
      method: RequestType.post,
      data: {
        'type': type,
        'body': ?body,
        'mediaUrl': ?mediaUrl,
        if (replyToMessageId != null && replyToMessageId.isNotEmpty)
          'replyToMessageId': replyToMessageId,
        if (replyPreview != null && replyPreview.isNotEmpty)
          'replyPreview': replyPreview,
      },
      parserModel: (json) => json,
    );
    final raw = result?['message'];
    if (raw is! Map) {
      throw StateError('Failed to send message');
    }
    return ChatMessage.fromJson(Map<String, dynamic>.from(raw));
  }

  /// Uploads chat image/voice to Bunny via `POST /chat/media`.
  Future<String> uploadMedia(String filePath) async {
    final result = await _network.uploadFile<Map<String, dynamic>>(
      path: '/chat/media',
      filePath: filePath,
      fieldName: 'file',
      parserModel: (json) => json,
    );
    final url = (result?['mediaUrl'] as String?)?.trim() ?? '';
    if (url.isEmpty) {
      throw StateError('Chat media upload failed');
    }
    return url;
  }

  Future<void> markRead(String conversationId) async {
    await _network.send<Map<String, dynamic>>(
      path: '/chat/conversations/${Uri.encodeComponent(conversationId)}/read',
      method: RequestType.post,
      parserModel: (json) => json,
    );
  }

  Future<void> deleteConversation(String conversationId) async {
    await _network.send<Map<String, dynamic>>(
      path: '/chat/conversations/${Uri.encodeComponent(conversationId)}',
      method: RequestType.delete,
      parserModel: (json) => json,
    );
    forgetConversation(conversationId);
  }

  Future<void> deleteAllRequests() async {
    await _network.send<Map<String, dynamic>>(
      path: '/chat/requests',
      method: RequestType.delete,
      parserModel: (json) => json,
    );
  }

  Future<int> unreadCount() async {
    final result = await _network.send<Map<String, dynamic>>(
      path: '/chat/unread-count',
      method: RequestType.get,
      parserModel: (json) => json,
    );
    return (result?['unreadCount'] as num?)?.toInt() ?? 0;
  }

  Future<List<ChatGalleryMedia>> listConversationMedia(
    String conversationId, {
    int limit = 100,
  }) async {
    final id = conversationId.trim();
    if (id.isEmpty) return const [];
    final result = await _network.send<Map<String, dynamic>>(
      path: '/chat/conversations/${Uri.encodeComponent(id)}/media',
      method: RequestType.get,
      queryParameters: {'limit': '$limit'},
      parserModel: (json) => json,
    );
    final raw = result?['media'];
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map)
          ChatGalleryMedia.fromJson(Map<String, dynamic>.from(item)),
    ];
  }
}

@immutable
final class ChatGalleryMedia {
  const ChatGalleryMedia({
    required this.id,
    required this.type,
    required this.mediaUrl,
  });

  factory ChatGalleryMedia.fromJson(Map<String, dynamic> json) {
    return ChatGalleryMedia(
      id: (json['id'] as String?)?.trim() ?? '',
      type: (json['type'] as String?)?.trim() ?? 'image',
      mediaUrl: (json['mediaUrl'] as String?)?.trim() ?? '',
    );
  }

  final String id;
  final String type;
  final String mediaUrl;
}
