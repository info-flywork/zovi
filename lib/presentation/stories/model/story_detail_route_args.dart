import 'package:zovi/domain/user/user_repository.dart';
import 'package:flutter/foundation.dart';

@immutable
final class StoryDetailRouteArgs {
  const StoryDetailRouteArgs({
    required this.items,
    required this.initialIndex,
  });

  final List<StoryMediaItem> items;
  final int initialIndex;
}
