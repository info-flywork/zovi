part of '../home_view.dart';

mixin HomeViewMixin on State<HomeView> {
  static bool _didShowDemoInAppNotification = false;

  void showErrorSnackbar(String message) {
    AppSnackbar.instance.show(context, message, isError: true);
  }

  void maybeShowDemoInAppNotification() {
    if (_didShowDemoInAppNotification) return;
    _didShowDemoInAppNotification = true;

    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      AppInAppNotification.instance.show(
        const InAppNotificationData(
          username: 'juliaivanova',
          displayName: 'Julia Ivanova',
          messageKey: 'notifications_friend_request',
          avatarPath: AssetPaths.avatarJulia,
          showGradientRing: true,
          action: InAppNotificationAction.friendRequest,
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

  void onAddTap() {
    AppSnackbar.instance.show(context, 'check_in_coming_soon'.tr());
  }
}
