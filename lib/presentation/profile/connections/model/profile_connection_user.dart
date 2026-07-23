import 'package:equatable/equatable.dart';

class ProfileConnectionUser extends Equatable {
  const ProfileConnectionUser({
    required this.username,
    required this.displayName,
    required this.avatarPath,
  });

  final String username;
  final String displayName;
  final String avatarPath;

  @override
  List<Object?> get props => [username, displayName, avatarPath];
}
