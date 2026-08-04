import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class LocationPermissionEvent extends Equatable {
  const LocationPermissionEvent();

  @override
  List<Object?> get props => [];
}

@immutable
final class LocationPermissionContinueTapped extends LocationPermissionEvent {
  const LocationPermissionContinueTapped();
}
