enum EditProfileFieldType {
  name,
  username,
  bio;

  String get title => switch (this) {
    EditProfileFieldType.name => 'Name',
    EditProfileFieldType.username => 'Username',
    EditProfileFieldType.bio => 'Bio',
  };

  int get maxLength => switch (this) {
    EditProfileFieldType.name => 25,
    EditProfileFieldType.username => 25,
    EditProfileFieldType.bio => 150,
  };

  String? get footerText => switch (this) {
    EditProfileFieldType.name =>
      'Your name is visible to everyone\non and of Zovi.',
    EditProfileFieldType.username =>
      'Your username is visible to everyone\non and of Zovi.',
    EditProfileFieldType.bio =>
      'Your bio is visible to everyone\non and of Zovi.',
  };

  bool get isMultiline => this == EditProfileFieldType.bio;
}
