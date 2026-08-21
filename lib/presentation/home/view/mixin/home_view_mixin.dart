part of '../home_view.dart';

mixin HomeViewMixin on State<HomeView> {
  void showErrorSnackbar(String message) {
    AppSnackbar.instance.show(context, message, isError: true);
  }

  Future<void> onStoryTap(StoryPreview story) async {
    if (story.isYou && !story.hasStory) {
      context.push(RoutePaths.camera.path);
      return;
    }

    if (story.isYou && story.hasStory) {
      final repo = getIt<UserRepository>();
      var items = repo.peekMyActiveStoryItems();
      if (items.isEmpty) {
        items = await repo.getMyActiveStoryItems();
        if (!mounted) return;
      } else {
        // Keep cache warm without blocking open.
        unawaited(repo.getMyActiveStoryItems(forceRefresh: true));
      }
      if (items.isEmpty) {
        context.push(RoutePaths.camera.path);
        return;
      }
      await context.push(
        RoutePaths.storyDetail.path,
        extra: StoryDetailRouteArgs(
          items: repo.hydrateStoryLikeState(items),
          initialIndex: 0,
        ),
      );
      if (!mounted) return;
      context.read<HomeBloc>().add(const HomeStoriesRefreshRequested());
      return;
    }

    final items = getIt<UserRepository>().peekStoryItemsForUser(story.userId);
    if (items.isEmpty) return;

    await context.push(
      RoutePaths.storyDetail.path,
      extra: StoryDetailRouteArgs(
        items: getIt<UserRepository>().hydrateStoryLikeState(items),
        initialIndex: 0,
      ),
    );
    if (!mounted) return;
    context.read<HomeBloc>().add(const HomeStoriesRefreshRequested());
  }

  Future<void> onAddTap() async {
    final type = await showShareContentSheet(context);
    if (!mounted || type == null) return;

    if (type == ShareContentType.checkIn) {
      final user = getIt<UserRepository>().currentUserListenable.value;
      final isFirstCheckIn = (user?.checkIns ?? 0) <= 0;

      if (isFirstCheckIn) {
        final continued = await showFirstCheckInSheet(context);
        if (continued != true || !mounted) return;
      }

      await showCheckInCreateSheet(context);
      return;
    }

    await context.push(
      RoutePaths.camera.path,
      extra: type == ShareContentType.pulse
          ? CameraPublishIntent.pulse
          : CameraPublishIntent.story,
    );
  }
}
