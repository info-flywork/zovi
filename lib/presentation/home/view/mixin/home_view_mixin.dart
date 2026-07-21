part of '../home_view.dart';

mixin HomeViewMixin on State<HomeView> {
  void showErrorSnackbar(String message) {
    AppSnackbar.instance.show(context, message, isError: true);
  }

  void onStoryTap(StoryPreview story) {
    if (story.isYou) {
      AppSnackbar.instance.show(context, 'Story oluşturma yakında');
      return;
    }
    context.push(RoutePaths.discover.path);
  }

  void onAddTap() {
    AppSnackbar.instance.show(context, 'Check-in yakında');
  }
}
