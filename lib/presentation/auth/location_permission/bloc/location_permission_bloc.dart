import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/domain/auth/auth_repository.dart';
import 'package:zovi/presentation/auth/location_permission/bloc/location_permission_event.dart';
import 'package:zovi/presentation/auth/location_permission/bloc/location_permission_state.dart';

class LocationPermissionBloc
    extends Bloc<LocationPermissionEvent, LocationPermissionState> {
  LocationPermissionBloc(this._authRepository)
    : super(const LocationPermissionInitial()) {
    on<LocationPermissionContinueTapped>(_onContinue);
  }

  final AuthRepository _authRepository;

  Future<void> _onContinue(
    LocationPermissionContinueTapped event,
    Emitter<LocationPermissionState> emit,
  ) async {
    emit(const LocationPermissionLoading());

    await Permission.locationWhenInUse.request();
    await _authRepository.completeOnboarding();

    emit(LocationPermissionSuccess(navigateTo: RoutePaths.home.path));
  }
}
