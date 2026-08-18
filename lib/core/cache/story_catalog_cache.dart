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

  void clear() => _items = null;
}
