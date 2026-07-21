import 'package:equatable/equatable.dart';

sealed class BirthdayEvent extends Equatable {
  const BirthdayEvent();

  @override
  List<Object?> get props => [];
}

final class BirthdayDateChanged extends BirthdayEvent {
  const BirthdayDateChanged(this.birthDate);

  final DateTime birthDate;

  @override
  List<Object?> get props => [birthDate];
}

final class BirthdayContinueTapped extends BirthdayEvent {
  const BirthdayContinueTapped();
}
