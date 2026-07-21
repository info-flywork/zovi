import 'package:zovi/presentation/profile/edit/model/edit_profile_field_type.dart';

class EditProfileFieldRouteArgs {
  const EditProfileFieldRouteArgs({
    required this.field,
    required this.initialValue,
  });

  final EditProfileFieldType field;
  final String initialValue;
}
