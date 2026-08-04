import 'package:equatable/equatable.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

@immutable
final class HomeInitial extends HomeState {
  const HomeInitial();
}

@immutable
final class HomeLoading extends HomeState {
  const HomeLoading();
}

@immutable
final class HomeLoaded extends HomeState {
  const HomeLoaded({
    required this.stories,
    required this.mapFriends,
    required this.hasUnreadMessages,
  });

  final List<StoryPreview> stories;
  final List<MapFriend> mapFriends;
  final bool hasUnreadMessages;

  HomeLoaded copyWith({
    List<StoryPreview>? stories,
    List<MapFriend>? mapFriends,
    bool? hasUnreadMessages,
  }) {
    return HomeLoaded(
      stories: stories ?? this.stories,
      mapFriends: mapFriends ?? this.mapFriends,
      hasUnreadMessages: hasUnreadMessages ?? this.hasUnreadMessages,
    );
  }

  @override
  List<Object?> get props => [stories, mapFriends, hasUnreadMessages];
}

@immutable
final class HomeError extends HomeState {
  const HomeError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
