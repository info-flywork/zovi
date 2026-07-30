import 'package:equatable/equatable.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

final class HomeStarted extends HomeEvent {
  const HomeStarted({this.forceLoading = false});

  /// Shows the full-screen loader even when data is already on screen.
  final bool forceLoading;

  @override
  List<Object?> get props => [forceLoading];
}

final class HomeRefreshRequested extends HomeEvent {
  const HomeRefreshRequested();
}

final class HomeStoriesRefreshRequested extends HomeEvent {
  const HomeStoriesRefreshRequested();
}
