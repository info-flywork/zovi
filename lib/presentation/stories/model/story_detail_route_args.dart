import 'package:zovi/domain/user/user_repository.dart';

class StoryDetailRouteArgs {
  const StoryDetailRouteArgs({
    required this.items,
    required this.initialIndex,
  });

  final List<StoryMediaItem> items;
  final int initialIndex;
}
