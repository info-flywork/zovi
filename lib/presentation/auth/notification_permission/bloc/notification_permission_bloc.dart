import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/presentation/auth/model/signup_flow.dart';
import 'package:zovi/presentation/auth/notification_permission/bloc/notification_permission_event.dart';
import 'package:zovi/presentation/auth/notification_permission/bloc/notification_permission_state.dart';

final class NotificationPermissionBloc
    extends Bloc<NotificationPermissionEvent, NotificationPermissionState> {
  NotificationPermissionBloc({required SignupFlow signupFlow})
    : super(NotificationPermissionInitial(signupFlow: signupFlow)) {
    on<NotificationPermissionContinueTapped>(_onContinue);
  }

  Future<void> _onContinue(
    NotificationPermissionContinueTapped event,
    Emitter<NotificationPermissionState> emit,
  ) async {
    emit(NotificationPermissionLoading(signupFlow: state.signupFlow));

    await Permission.notification.request();

    final navigateTo = RoutePaths.locationPermission.path;

    emit(
      NotificationPermissionSuccess(
        navigateTo: navigateTo,
        signupFlow: state.signupFlow,
      ),
    );
  }
}
