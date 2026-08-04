import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class CreateProfileEvent extends Equatable {
  const CreateProfileEvent();

  @override
  List<Object?> get props => [];
}

@immutable
final class CreateProfileFullNameChanged extends CreateProfileEvent {
  const CreateProfileFullNameChanged(this.fullName);

  final String fullName;

  @override
  List<Object?> get props => [fullName];
}

@immutable
final class CreateProfileUsernameChanged extends CreateProfileEvent {
  const CreateProfileUsernameChanged(this.username);

  final String username;

  @override
  List<Object?> get props => [username];
}

@immutable
final class CreateProfileUsernameCheckRequested extends CreateProfileEvent {
  const CreateProfileUsernameCheckRequested(this.username);

  final String username;

  @override
  List<Object?> get props => [username];
}

@immutable
final class CreateProfileUsernameSuggestionSelected extends CreateProfileEvent {
  const CreateProfileUsernameSuggestionSelected(this.username);

  final String username;

  @override
  List<Object?> get props => [username];
}

@immutable
final class CreateProfileContinueTapped extends CreateProfileEvent {
  const CreateProfileContinueTapped();
}
