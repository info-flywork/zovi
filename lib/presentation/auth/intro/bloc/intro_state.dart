import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class IntroState extends Equatable {
  const IntroState({this.pageIndex = 0});

  final int pageIndex;

  @override
  List<Object?> get props => [pageIndex];
}

@immutable
final class IntroInProgress extends IntroState {
  const IntroInProgress({super.pageIndex});
}

@immutable
final class IntroCompleted extends IntroState {
  const IntroCompleted({required this.navigateTo, super.pageIndex});

  final String navigateTo;

  @override
  List<Object?> get props => [pageIndex, navigateTo];
}
