import 'package:equatable/equatable.dart';

sealed class NotificationPermissionEvent extends Equatable {
  const NotificationPermissionEvent();

  @override
  List<Object?> get props => [];
}

final class NotificationPermissionContinueTapped
    extends NotificationPermissionEvent {
  const NotificationPermissionContinueTapped();
}
