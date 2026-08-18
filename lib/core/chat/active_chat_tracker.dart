/// Tracks which DM the user is currently viewing so chat pushes/banners
/// can stay quiet for that thread.
final class ActiveChatTracker {
  ActiveChatTracker._();
  static final ActiveChatTracker instance = ActiveChatTracker._();

  String? _conversationId;
  String? _peerUserId;

  String? get conversationId => _conversationId;
  String? get peerUserId => _peerUserId;

  void enter({String? conversationId, String? peerUserId}) {
    final c = conversationId?.trim();
    final p = peerUserId?.trim();
    if (c != null && c.isNotEmpty) _conversationId = c;
    if (p != null && p.isNotEmpty) _peerUserId = p;
  }

  void leave({String? conversationId}) {
    final c = conversationId?.trim();
    if (c == null || c.isEmpty || _conversationId == c) {
      _conversationId = null;
      _peerUserId = null;
    }
  }

  bool isViewing({String? conversationId, String? peerUserId}) {
    final c = conversationId?.trim() ?? '';
    final p = peerUserId?.trim() ?? '';
    if (c.isNotEmpty && _conversationId == c) return true;
    if (p.isNotEmpty && _peerUserId == p) return true;
    return false;
  }
}
