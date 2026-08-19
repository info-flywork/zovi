import 'package:zovi/domain/tribe/tribe_repository.dart';

/// In-memory tribe detail cache so group chat / group info reopen instantly.
final class TribeDetailCache {
  final Map<String, Tribe> _byId = {};

  Tribe? peek(String tribeId) {
    final id = tribeId.trim();
    if (id.isEmpty) return null;
    return _byId[id];
  }

  void put(Tribe tribe) {
    final id = tribe.id.trim();
    if (id.isEmpty) return;
    _byId[id] = tribe;
  }

  /// Keeps full detail (members) when present; otherwise stores list-board rows.
  void mergeFromListItem(Tribe tribe) {
    final id = tribe.id.trim();
    if (id.isEmpty) return;
    final existing = _byId[id];
    if (existing != null && existing.members.isNotEmpty) {
      _byId[id] = existing.copyWith(
        memberCount: tribe.memberCount,
        avatars: tribe.avatars.isNotEmpty ? tribe.avatars : existing.avatars,
        conversationId: existing.conversationId.isNotEmpty
            ? existing.conversationId
            : tribe.conversationId,
        state: tribe.state,
        progress: tribe.progress,
      );
      return;
    }
    _byId[id] = tribe;
  }

  void clear() => _byId.clear();

  void remove(String tribeId) {
    final id = tribeId.trim();
    if (id.isEmpty) return;
    _byId.remove(id);
  }
}
