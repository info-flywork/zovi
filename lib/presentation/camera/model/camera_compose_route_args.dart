import 'package:flutter/foundation.dart';

enum CameraPublishIntent { story, pulse }

@immutable
final class CameraComposeRouteArgs {
  const CameraComposeRouteArgs({
    required this.imagePath,
    this.fromDraft = false,
    this.draftId,
    this.intent = CameraPublishIntent.story,
    this.isVideo = false,
  });

  final String imagePath;

  /// Opened from the drafts sheet — skip "save draft?" if nothing changed.
  final bool fromDraft;

  /// Remote draft id when [fromDraft] came from CDN/DB.
  final String? draftId;

  /// Pulse posts to `/pulses`; story posts to `/stories`.
  final CameraPublishIntent intent;

  final bool isVideo;

  bool get isAsset => imagePath.startsWith('assets/');
}
