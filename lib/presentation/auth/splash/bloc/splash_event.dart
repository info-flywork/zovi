import 'package:equatable/equatable.dart';

sealed class SplashEvent extends Equatable {
  const SplashEvent();

  @override
  List<Object?> get props => [];
}

final class SplashStarted extends SplashEvent {
  const SplashStarted();
}
