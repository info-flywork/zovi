import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class StoriesEvent extends Equatable {
  const StoriesEvent();
  @override
  List<Object?> get props => [];
}

@immutable
final class StoriesStarted extends StoriesEvent {
  const StoriesStarted();
}

/// Re-reads the feed without blanking the grid — used after the viewer closes
/// so like/viewed changes are reflected.
@immutable
final class StoriesRefreshRequested extends StoriesEvent {
  const StoriesRefreshRequested();
}
