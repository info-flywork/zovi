import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class IntroEvent extends Equatable {
  const IntroEvent();

  @override
  List<Object?> get props => [];
}

@immutable
final class IntroPageChanged extends IntroEvent {
  const IntroPageChanged(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}

@immutable
final class IntroContinueTapped extends IntroEvent {
  const IntroContinueTapped();
}

@immutable
final class IntroGetStartedTapped extends IntroEvent {
  const IntroGetStartedTapped();
}
