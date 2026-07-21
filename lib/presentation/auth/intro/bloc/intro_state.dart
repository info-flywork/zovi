import 'package:equatable/equatable.dart';

sealed class IntroState extends Equatable {
  const IntroState({this.pageIndex = 0});

  final int pageIndex;

  @override
  List<Object?> get props => [pageIndex];
}

final class IntroInProgress extends IntroState {
  const IntroInProgress({super.pageIndex});
}

final class IntroCompleted extends IntroState {
  const IntroCompleted({required this.navigateTo, super.pageIndex});

  final String navigateTo;

  @override
  List<Object?> get props => [pageIndex, navigateTo];
}
