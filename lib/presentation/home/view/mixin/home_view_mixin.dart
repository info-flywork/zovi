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
      AppSnackbar.instance.show(context, 'story_create_coming_soon'.tr());
      return;
    }

    final state = context.read<HomeBloc>().state;
    if (state is! HomeLoaded) return;

    final viewable = state.stories.where((s) => s.hasStory).toList();
    if (viewable.isEmpty) return;

    final feed = await getIt<UserRepository>().getStoryFeed();
    final items = viewable.map((preview) {
      final match = feed.where((f) => f.avatarPath == preview.avatarPath);
      if (match.isNotEmpty) return match.first;
      return StoryMediaItem(
        imagePath: preview.avatarPath,
        label: preview.name,
        avatarPath: preview.avatarPath,
      );
    }).toList();

    final initialIndex = viewable.indexWhere(
      (s) => s.avatarPath == story.avatarPath && s.name == story.name,
    );

    if (!mounted) return;
    context.push(
      RoutePaths.storyDetail.path,
      extra: StoryDetailRouteArgs(
        items: items,
        initialIndex: initialIndex < 0 ? 0 : initialIndex,
      ),
    );
  }

  void onAddTap() async {
    final continued = await showFirstCheckInSheet(context);
    if (continued != true || !mounted) return;

    await showCheckInCreateSheet(context);
  }
}
