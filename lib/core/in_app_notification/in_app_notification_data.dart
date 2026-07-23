enum InAppNotificationAction {
  none,
  friendRequest,
  followBack,
  openStory,
  openChat,
}

class InAppNotificationData {
  const InAppNotificationData({
    required this.username,
    required this.messageKey,
    required this.avatarPath,
    this.displayName,
    this.time = '',
    this.messageNamedArgs = const {},
    this.subtitleKey,
    this.subtitleNamedArgs = const {},
    this.showGradientRing = false,
    this.action = InAppNotificationAction.none,
    this.storyImagePath,
    this.leadingIconPath,
    this.useFullTitle = false,
  });

  final String username;
  final String messageKey;
  final String avatarPath;
  final String? displayName;
  final String time;
  final Map<String, String> messageNamedArgs;
  final String? subtitleKey;
  final Map<String, String> subtitleNamedArgs;
  final bool showGradientRing;
  final InAppNotificationAction action;
  final String? storyImagePath;

  /// Verilirse avatar yerine bu ikon gösterilir.
  final String? leadingIconPath;

  /// `true` ise başlık olarak `messageKey` (username namedArg ile) kullanılır.
  final bool useFullTitle;
}
