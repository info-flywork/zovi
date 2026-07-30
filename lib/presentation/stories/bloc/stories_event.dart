import 'package:equatable/equatable.dart';

sealed class StoriesEvent extends Equatable {
  const StoriesEvent();
  @override
  List<Object?> get props => [];
}

final class StoriesStarted extends StoriesEvent {
  const StoriesStarted();
}

/// Re-reads the feed without blanking the grid — used after the viewer closes
/// so like/viewed changes are reflected.
final class StoriesRefreshRequested extends StoriesEvent {
  const StoriesRefreshRequested();
}
