import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

@immutable
final class HomeStarted extends HomeEvent {
  const HomeStarted({this.forceLoading = false});

  /// Shows the full-screen loader even when data is already on screen.
  final bool forceLoading;

  @override
  List<Object?> get props => [forceLoading];
}

@immutable
final class HomeRefreshRequested extends HomeEvent {
  const HomeRefreshRequested();
}

@immutable
final class HomeStoriesRefreshRequested extends HomeEvent {
  const HomeStoriesRefreshRequested();
}
