import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

@immutable
final class ChatStarted extends ChatEvent {
  const ChatStarted();
}

@immutable
sealed class ChatState extends Equatable {
  const ChatState();
  @override
  List<Object?> get props => [];
}

@immutable
final class ChatInitial extends ChatState {
  const ChatInitial();
}

@immutable
final class ChatLoaded extends ChatState {
  const ChatLoaded();
}

final class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc() : super(const ChatInitial()) {
    on<ChatStarted>((event, emit) => emit(const ChatLoaded()));
  }
}
