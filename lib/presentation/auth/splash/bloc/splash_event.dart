import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class SplashEvent extends Equatable {
  const SplashEvent();

  @override
  List<Object?> get props => [];
}

@immutable
final class SplashStarted extends SplashEvent {
  const SplashStarted();
}
