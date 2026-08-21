import 'package:zovi/domain/auth/auth_repository.dart';

/// In-memory explore feed so reopening Stories doesn't blank the grid.
final class StoryCatalogCache {
  List<PublishedStory>? _items;

  List<PublishedStory>? peek() {
    final items = _items;
    if (items == null || items.isEmpty) return null;
    return List<PublishedStory>.unmodifiable(items);
  }

  void put(List<PublishedStory> items) {
    _items = List<PublishedStory>.from(items);
  }

  void patchLike({
    required String storyId,
    required bool likedByMe,
    required int likeCount,
  }) {
    final items = _items;
    final id = storyId.trim();
    if (items == null || id.isEmpty) return;
    var changed = false;
    final next = <PublishedStory>[];
    for (final story in items) {
      if (story.id == id) {
        changed = true;
        next.add(story.copyWith(likedByMe: likedByMe, likeCount: likeCount));
      } else {
        next.add(story);
      }
    }
    if (changed) _items = next;
  }

  void clear() => _items = null;
}
