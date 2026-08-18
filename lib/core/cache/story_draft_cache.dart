import 'package:zovi/domain/auth/models/story_draft_item.dart';

/// In-memory story drafts list. Refetch only when [dirty] after a new upload.
final class StoryDraftCache {
  List<StoryDraftItem>? _items;
  var _dirty = true;

  bool get dirty => _dirty;
  bool get hasCache => _items != null;

  List<StoryDraftItem>? peek() {
    final items = _items;
    if (items == null) return null;
    return List<StoryDraftItem>.unmodifiable(items);
  }

  void put(List<StoryDraftItem> items) {
    _items = List<StoryDraftItem>.from(items);
    _dirty = false;
  }

  /// Call after a new draft is uploaded so the next open refreshes from API.
  void markDirty() => _dirty = true;

  void clear() {
    _items = null;
    _dirty = true;
  }
}
