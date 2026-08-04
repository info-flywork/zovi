/// Holds chat-detail pop results when the system/iOS swipe back can't pass a
/// custom result (unlike an explicit [Navigator.pop] with a value).
abstract final class ChatDetailExitStore {
  static final Map<String, String> _byConversationId = {};

  static void put(String conversationId, String result) {
    final id = conversationId.trim();
    if (id.isEmpty) return;
    _byConversationId[id] = result;
  }

  static String? take(String conversationId) {
    final id = conversationId.trim();
    if (id.isEmpty) return null;
    return _byConversationId.remove(id);
  }
}
