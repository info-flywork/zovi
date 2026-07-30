part of '../home_view.dart';

mixin HomeViewMixin on State<HomeView> {
  static bool _didShowDemoFriendCheckIn = false;

  void showErrorSnackbar(String message) {
    AppSnackbar.instance.show(context, message, isError: true);
  }

  void maybeShowDemoFriendCheckIn() {
    if (_didShowDemoFriendCheckIn) return;
    _didShowDemoFriendCheckIn = true;

    Future<void>.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      final repo = getIt<UserRepository>();
      final updated = repo.applyFriendCheckIn(
        name: 'Sona',
        checkIn: const FriendMapCheckIn(
          photoPaths: [AssetPaths.mapSecond, AssetPaths.pulse2],
          stampImagePath: AssetPaths.stamp7,
          placeName: 'Babylon Istanbul',
        ),
        distanceMeters: 800,
        etaMinutes: 12,
      );
      if (updated == null) return;

      AppInAppNotification.instance.show(
        InAppNotificationData(
          username: updated.name,
          displayName: updated.name,
          messageKey: 'in_app_checked_in_at',
          messageNamedArgs: {'place': updated.checkIn!.placeName},
          subtitleKey: 'in_app_meters_away',
          subtitleNamedArgs: {
            'meters': '${updated.distanceMeters ?? 800}',
          },
          avatarPath: updated.avatarPath,
          showGradientRing: true,
        ),
      );
    });
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
        extra: StoryDetailRouteArgs(items: items, initialIndex: 0),
      );
      if (!mounted) return;
      context.read<HomeBloc>().add(const HomeStoriesRefreshRequested());
      return;
    }

    final items = getIt<UserRepository>().peekStoryItemsForUser(story.userId);
    if (items.isEmpty) return;

    await context.push(
      RoutePaths.storyDetail.path,
      extra: StoryDetailRouteArgs(items: items, initialIndex: 0),
    );
    if (!mounted) return;
    context.read<HomeBloc>().add(const HomeStoriesRefreshRequested());
  }

  void onAddTap() async {
    final continued = await showFirstCheckInSheet(context);
    if (continued != true || !mounted) return;

    await showCheckInCreateSheet(context);
  }
}
