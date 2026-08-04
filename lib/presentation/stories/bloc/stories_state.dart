import 'package:equatable/equatable.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class StoriesState extends Equatable {
  const StoriesState();
  @override
  List<Object?> get props => [];
}

@immutable
final class StoriesInitial extends StoriesState {
  const StoriesInitial();
}

@immutable
final class StoriesLoading extends StoriesState {
  const StoriesLoading();
}

@immutable
final class StoriesLoaded extends StoriesState {
  const StoriesLoaded({required this.items});

  final List<StoryMediaItem> items;

  @override
  List<Object?> get props => [items];
}
