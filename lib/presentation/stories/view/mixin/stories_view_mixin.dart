part of '../stories_view.dart';

mixin StoriesViewMixin on State<StoriesView> {
  void onOpenStory(StoryPreview story) {
    context.push(RoutePaths.discover.path);
  }
}
