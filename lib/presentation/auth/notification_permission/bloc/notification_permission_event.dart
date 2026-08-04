import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class NotificationPermissionEvent extends Equatable {
  const NotificationPermissionEvent();

  @override
  List<Object?> get props => [];
}

@immutable
final class NotificationPermissionContinueTapped
    extends NotificationPermissionEvent {
  const NotificationPermissionContinueTapped();
}
