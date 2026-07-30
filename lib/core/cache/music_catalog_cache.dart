import 'package:zovi/domain/auth/auth_repository.dart';

/// In-memory catalog cache so reopening the music sheet doesn't re-hit the API
/// for pages already loaded.
class MusicCatalogCache {
  final List<MusicTrackItem> _browse = [];
  var _browseHasMore = true;
  final Map<String, _SearchCache> _search = {};

  bool get hasBrowseData => _browse.isNotEmpty;

  MusicTracksPage? peek({
    required String query,
    required int offset,
    required int limit,
  }) {
    final q = query.trim();
    if (q.isEmpty) {
      return _peekList(
        items: _browse,
        hasMore: _browseHasMore,
        offset: offset,
        limit: limit,
      );
    }
    final cached = _search[q.toLowerCase()];
    if (cached == null) return null;
    return _peekList(
      items: cached.items,
      hasMore: cached.hasMore,
      offset: offset,
      limit: limit,
    );
  }

  void put({
    required String query,
    required int offset,
    required MusicTracksPage page,
  }) {
    final q = query.trim();
    if (q.isEmpty) {
      _merge(_browse, offset: offset, page: page);
      _browseHasMore = page.hasMore;
      return;
    }

    final key = q.toLowerCase();
    final existing = _search[key] ?? _SearchCache();
    _merge(existing.items, offset: offset, page: page);
    existing.hasMore = page.hasMore;
    _search[key] = existing;
  }

  void clear() {
    _browse.clear();
    _browseHasMore = true;
    _search.clear();
  }

  MusicTracksPage? _peekList({
    required List<MusicTrackItem> items,
    required bool hasMore,
    required int offset,
    required int limit,
  }) {
    if (items.isEmpty && offset == 0) return null;
    if (offset > items.length) return null;
    if (offset == items.length) {
      // End of known cache — only valid if API said no more.
      if (!hasMore) {
        return MusicTracksPage(
          tracks: const [],
          hasMore: false,
          nextOffset: offset,
        );
      }
      return null;
    }

    final slice = items.skip(offset).take(limit).toList(growable: false);
    // Incomplete window and server may still have more → force network fill.
    if (slice.length < limit && hasMore) return null;

    return MusicTracksPage(
      tracks: slice,
      hasMore: offset + slice.length < items.length || hasMore,
      nextOffset: offset + slice.length,
    );
  }

  void _merge(
    List<MusicTrackItem> items, {
    required int offset,
    required MusicTracksPage page,
  }) {
    if (offset == 0) {
      items
        ..clear()
        ..addAll(page.tracks);
      return;
    }

    if (offset > items.length) {
      items.addAll(page.tracks);
      return;
    }

    // Replace/append from offset without duplicating by id.
    final known = {for (final t in items) t.id};
    final merged = items.take(offset).toList();
    for (final track in page.tracks) {
      if (known.contains(track.id) &&
          merged.any((e) => e.id == track.id)) {
        continue;
      }
      merged.add(track);
      known.add(track.id);
    }
    items
      ..clear()
      ..addAll(merged);
  }
}

class _SearchCache {
  final List<MusicTrackItem> items = [];
  var hasMore = true;
}
