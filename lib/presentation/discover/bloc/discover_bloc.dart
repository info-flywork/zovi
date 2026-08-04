import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class DiscoverEvent extends Equatable {
  const DiscoverEvent();
  @override
  List<Object?> get props => [];
}

@immutable
final class DiscoverStarted extends DiscoverEvent {
  const DiscoverStarted();
}

@immutable
sealed class DiscoverState extends Equatable {
  const DiscoverState();
  @override
  List<Object?> get props => [];
}

@immutable
final class DiscoverInitial extends DiscoverState {
  const DiscoverInitial();
}

@immutable
final class DiscoverLoaded extends DiscoverState {
  const DiscoverLoaded({
    required this.name,
    required this.caption,
  });

  final String name;
  final String caption;

  @override
  List<Object?> get props => [name, caption];
}

final class DiscoverBloc extends Bloc<DiscoverEvent, DiscoverState> {
  DiscoverBloc() : super(const DiscoverInitial()) {
    on<DiscoverStarted>((event, emit) {
      emit(
        const DiscoverLoaded(
          name: 'Julia Ivanova',
          caption:
              'Lorem Ipsum is simply dummy text of the printing and typesetting industry...',
        ),
      );
    });
  }
}
