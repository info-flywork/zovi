import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object?> get props => [];
}

@immutable
final class SplashInitial extends SplashState {
  const SplashInitial();
}

@immutable
final class SplashLoading extends SplashState {
  const SplashLoading();
}

@immutable
final class SplashNavigateTo extends SplashState {
  const SplashNavigateTo(this.destination, {this.extra});

  final String destination;
  final Object? extra;

  @override
  List<Object?> get props => [destination, extra];
}
