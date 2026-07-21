import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class DiscoverEvent extends Equatable {
  const DiscoverEvent();
  @override
  List<Object?> get props => [];
}

final class DiscoverStarted extends DiscoverEvent {
  const DiscoverStarted();
}

sealed class DiscoverState extends Equatable {
  const DiscoverState();
  @override
  List<Object?> get props => [];
}

final class DiscoverInitial extends DiscoverState {
  const DiscoverInitial();
}

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

class DiscoverBloc extends Bloc<DiscoverEvent, DiscoverState> {
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
