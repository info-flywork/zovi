import 'package:equatable/equatable.dart';
import 'package:zovi/domain/user/user_repository.dart';

sealed class StoriesState extends Equatable {
  const StoriesState();
  @override
  List<Object?> get props => [];
}

final class StoriesInitial extends StoriesState {
  const StoriesInitial();
}

final class StoriesLoading extends StoriesState {
  const StoriesLoading();
}

final class StoriesLoaded extends StoriesState {
  const StoriesLoaded({required this.stories});
  final List<StoryPreview> stories;
  @override
  List<Object?> get props => [stories];
}
