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
    context.push(RoutePaths.camera.path);
  }

  void onSendTap() {
    context.go(RoutePaths.chat.path);
  }

  Future<void> onOpenStory(List<StoryMediaItem> items, int index) async {
    await context.push(
      RoutePaths.storyDetail.path,
      extra: StoryDetailRouteArgs(
        items: items,
        initialIndex: index,
      ),
    );
  }
}
