import 'package:equatable/equatable.dart';
import 'package:zovi/domain/auth/auth_repository.dart';
import 'package:flutter/foundation.dart';

@immutable
final class ProfileConnectionUser extends Equatable {
  const ProfileConnectionUser({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.avatarPath,
  });

  factory ProfileConnectionUser.fromConnection(ConnectionUser user) {
    final username = user.username.trim();
    final fullName = user.fullName.trim();
    return ProfileConnectionUser(
      userId: user.userId,
      username: username,
      displayName: fullName.isNotEmpty ? fullName : username,
      avatarPath: user.avatarUrl,
    );
  }

  final String userId;
  final String username;
  final String displayName;
  final String avatarPath;

  @override
  List<Object?> get props => [userId, username, displayName, avatarPath];
}
