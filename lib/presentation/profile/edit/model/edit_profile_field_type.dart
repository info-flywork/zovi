import 'package:easy_localization/easy_localization.dart';

enum EditProfileFieldType {
  name,
  username,
  bio;

  String get title => switch (this) {
    EditProfileFieldType.name => 'name'.tr(),
    EditProfileFieldType.username => 'username'.tr(),
    EditProfileFieldType.bio => 'bio'.tr(),
  };

  int get maxLength => switch (this) {
    EditProfileFieldType.name => 50,
    EditProfileFieldType.username => 15,
    EditProfileFieldType.bio => 150,
  };

  String? get footerText => switch (this) {
    EditProfileFieldType.name => 'field_footer_name'.tr(),
    EditProfileFieldType.username => 'field_footer_username'.tr(),
    EditProfileFieldType.bio => 'field_footer_bio'.tr(),
  };

  bool get isMultiline => this == EditProfileFieldType.bio;
}
