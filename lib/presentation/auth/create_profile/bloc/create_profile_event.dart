import 'package:equatable/equatable.dart';

sealed class CreateProfileEvent extends Equatable {
  const CreateProfileEvent();

  @override
  List<Object?> get props => [];
}

final class CreateProfileFullNameChanged extends CreateProfileEvent {
  const CreateProfileFullNameChanged(this.fullName);

  final String fullName;

  @override
  List<Object?> get props => [fullName];
}

final class CreateProfileUsernameChanged extends CreateProfileEvent {
  const CreateProfileUsernameChanged(this.username);

  final String username;

  @override
  List<Object?> get props => [username];
}

final class CreateProfileUsernameCheckRequested extends CreateProfileEvent {
  const CreateProfileUsernameCheckRequested(this.username);

  final String username;

  @override
  List<Object?> get props => [username];
}

final class CreateProfileUsernameSuggestionSelected extends CreateProfileEvent {
  const CreateProfileUsernameSuggestionSelected(this.username);

  final String username;

  @override
  List<Object?> get props => [username];
}

final class CreateProfileContinueTapped extends CreateProfileEvent {
  const CreateProfileContinueTapped();
}
