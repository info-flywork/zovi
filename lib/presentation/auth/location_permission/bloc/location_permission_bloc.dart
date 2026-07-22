import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
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

    final granted = await _requestLocationPermission();

    if (!granted) {
      await Geolocator.openAppSettings();
      // İzin yokken home'a geçme; tekrar deneyebilsin.
      emit(const LocationPermissionInitial());
      return;
    }

    await _authRepository.completeOnboarding();
    emit(LocationPermissionSuccess(navigateTo: RoutePaths.home.path));
  }

  Future<bool> _requestLocationPermission() async {
    var permission = await Geolocator.checkPermission();

    // İlk kez veya reddedildiyse native dialog.
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }
}
