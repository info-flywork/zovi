import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class LocationPermissionState extends Equatable {
  const LocationPermissionState();

  @override
  List<Object?> get props => [];
}

@immutable
final class LocationPermissionInitial extends LocationPermissionState {
  const LocationPermissionInitial();
}

@immutable
final class LocationPermissionLoading extends LocationPermissionState {
  const LocationPermissionLoading();
}

@immutable
final class LocationPermissionSuccess extends LocationPermissionState {
  const LocationPermissionSuccess({required this.navigateTo});

  final String navigateTo;

  @override
  List<Object?> get props => [navigateTo];
}
