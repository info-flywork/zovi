import 'package:zovi/domain/chat/chat_repository.dart';

/// In-memory DM message cache so reopening a chat paints instantly
/// without a shimmer / full refetch when nothing changed.
class ChatMessagesCache {
  final Map<String, _ChatMessagesEntry> _entries = {};

  List<ChatMessage>? peek(String conversationId) {
    final id = conversationId.trim();
    if (id.isEmpty) return null;
    final entry = _entries[id];
    if (entry == null || entry.messages.isEmpty) return null;
    return List<ChatMessage>.unmodifiable(entry.messages);
  }

  DateTime? newestAt(String conversationId) {
    final id = conversationId.trim();
    if (id.isEmpty) return null;
    return _entries[id]?.newestAt;
  }

  void put(String conversationId, List<ChatMessage> messages) {
    final id = conversationId.trim();
    if (id.isEmpty) return;
    final cleaned = [
      for (final m in messages)
        if (m.id.isNotEmpty && !m.id.startsWith('local-')) m,
    ];
    DateTime? newest;
    for (final m in cleaned) {
      final at = m.createdAt;
      if (at == null) continue;
      if (newest == null || at.isAfter(newest)) newest = at;
    }
    _entries[id] = _ChatMessagesEntry(
      messages: cleaned,
      newestAt: newest,
    );
  }

  void mergeNewer(String conversationId, List<ChatMessage> newer) {
    final id = conversationId.trim();
    if (id.isEmpty || newer.isEmpty) return;
    final existing = _entries[id];
    if (existing == null || existing.messages.isEmpty) {
      put(id, newer);
      return;
    }
    final byId = {for (final m in existing.messages) m.id: m};
    var newest = existing.newestAt;
    for (final m in newer) {
      if (m.id.isEmpty || m.id.startsWith('local-')) continue;
      byId[m.id] = m;
      final at = m.createdAt;
      if (at != null && (newest == null || at.isAfter(newest))) {
        newest = at;
      }
    }
    final merged = byId.values.toList()
      ..sort((a, b) {
        final aAt = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bAt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aAt.compareTo(bAt);
      });
    _entries[id] = _ChatMessagesEntry(messages: merged, newestAt: newest);
  }

  void clear([String? conversationId]) {
    final id = conversationId?.trim() ?? '';
    if (id.isEmpty) {
      _entries.clear();
      return;
    }
    _entries.remove(id);
  }
}

class _ChatMessagesEntry {
  const _ChatMessagesEntry({
    required this.messages,
    required this.newestAt,
  });

  final List<ChatMessage> messages;
  final DateTime? newestAt;
}
