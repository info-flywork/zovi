import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class BirthdayEvent extends Equatable {
  const BirthdayEvent();

  @override
  List<Object?> get props => [];
}

@immutable
final class BirthdayDateChanged extends BirthdayEvent {
  const BirthdayDateChanged(this.birthDate);

  final DateTime birthDate;

  @override
  List<Object?> get props => [birthDate];
}

@immutable
final class BirthdayContinueTapped extends BirthdayEvent {
  const BirthdayContinueTapped();
}
