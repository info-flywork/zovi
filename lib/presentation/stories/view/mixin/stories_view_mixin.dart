part of '../stories_view.dart';

mixin StoriesViewMixin on State<StoriesView> {
  var _query = '';

  List<StoryMediaItem> filteredItems(List<StoryMediaItem> items) {
    final normalized = _query.trim().toLowerCase();
    if (normalized.isEmpty) return items;
    return items
        .where((item) => item.label.toLowerCase().contains(normalized))
        .toList();
  }

  void onSearchChanged(String value) {
    setState(() => _query = value);
  }

  void onAddTap() {
    // Story create flow — placeholder
  }

  void onSendTap() {
    context.push(RoutePaths.chat.path);
  }

  void onOpenStory(List<StoryMediaItem> items, int index) {
    context.push(
      RoutePaths.storyDetail.path,
      extra: StoryDetailRouteArgs(
        items: items,
        initialIndex: index,
      ),
    );
  }
}
