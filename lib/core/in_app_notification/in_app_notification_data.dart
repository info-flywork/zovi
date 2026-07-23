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
}
