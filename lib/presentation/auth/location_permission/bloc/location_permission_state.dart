import 'package:equatable/equatable.dart';

sealed class LocationPermissionState extends Equatable {
  const LocationPermissionState();

  @override
  List<Object?> get props => [];
}

final class LocationPermissionInitial extends LocationPermissionState {
  const LocationPermissionInitial();
}

final class LocationPermissionLoading extends LocationPermissionState {
  const LocationPermissionLoading();
}

final class LocationPermissionSuccess extends LocationPermissionState {
  const LocationPermissionSuccess({required this.navigateTo});

  final String navigateTo;

  @override
  List<Object?> get props => [navigateTo];
}
