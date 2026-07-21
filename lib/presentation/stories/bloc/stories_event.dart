import 'package:equatable/equatable.dart';

sealed class StoriesEvent extends Equatable {
  const StoriesEvent();
  @override
  List<Object?> get props => [];
}

final class StoriesStarted extends StoriesEvent {
  const StoriesStarted();
}
