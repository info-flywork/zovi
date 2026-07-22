import 'package:equatable/equatable.dart';
import 'package:zovi/domain/user/user_repository.dart';

sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

final class HomeInitial extends HomeState {
  const HomeInitial();
}

final class HomeLoading extends HomeState {
  const HomeLoading();
}

final class HomeLoaded extends HomeState {
  const HomeLoaded({
    required this.stories,
    required this.mapFriends,
    required this.hasUnreadMessages,
  });

  final List<StoryPreview> stories;
  final List<MapFriend> mapFriends;
  final bool hasUnreadMessages;

  @override
  List<Object?> get props => [stories, mapFriends, hasUnreadMessages];
}

final class HomeError extends HomeState {
  const HomeError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
