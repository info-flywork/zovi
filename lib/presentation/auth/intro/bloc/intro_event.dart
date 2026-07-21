import 'package:equatable/equatable.dart';

sealed class IntroEvent extends Equatable {
  const IntroEvent();

  @override
  List<Object?> get props => [];
}

final class IntroPageChanged extends IntroEvent {
  const IntroPageChanged(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}

final class IntroContinueTapped extends IntroEvent {
  const IntroContinueTapped();
}

final class IntroGetStartedTapped extends IntroEvent {
  const IntroGetStartedTapped();
}
