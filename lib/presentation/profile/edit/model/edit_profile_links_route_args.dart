import 'package:zovi/domain/user/user_repository.dart';
import 'package:flutter/foundation.dart';

@immutable
final class EditProfileLinksRouteArgs {
  const EditProfileLinksRouteArgs({required this.links});

  final List<ProfileLink> links;
}
