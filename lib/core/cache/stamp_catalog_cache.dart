import 'package:zovi/domain/auth/auth_repository.dart';

/// In-memory stamp catalog so reopening the sticker sheet doesn't re-hit `/stamps`.
final class StampCatalogCache {
  final Map<String, List<StampCatalogItem>> _byLocale = {};

  List<StampCatalogItem>? peek(String locale) {
    final key = _normalize(locale);
    final items = _byLocale[key];
    if (items == null || items.isEmpty) return null;
    return List<StampCatalogItem>.unmodifiable(items);
  }

  void put(String locale, List<StampCatalogItem> items) {
    _byLocale[_normalize(locale)] = List<StampCatalogItem>.from(items);
  }

  void clear() => _byLocale.clear();

  String _normalize(String locale) {
    final raw = locale.trim().toLowerCase();
    if (raw.isEmpty) return 'en';
    return raw.split('-').first;
  }
}
