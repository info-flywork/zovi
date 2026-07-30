import 'package:equatable/equatable.dart';

sealed class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object?> get props => [];
}

final class SplashInitial extends SplashState {
  const SplashInitial();
}

final class SplashLoading extends SplashState {
  const SplashLoading();
}

final class SplashNavigateTo extends SplashState {
  const SplashNavigateTo(this.destination, {this.extra});

  final String destination;
  final Object? extra;

  @override
  List<Object?> get props => [destination, extra];
}
