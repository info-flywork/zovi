import 'package:equatable/equatable.dart';

sealed class LocationPermissionEvent extends Equatable {
  const LocationPermissionEvent();

  @override
  List<Object?> get props => [];
}

final class LocationPermissionContinueTapped extends LocationPermissionEvent {
  const LocationPermissionContinueTapped();
}
