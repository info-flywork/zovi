import 'package:flutter/foundation.dart';
@immutable
final class CameraComposeRouteArgs {
  const CameraComposeRouteArgs({
    required this.imagePath,
    this.fromDraft = false,
    this.draftId,
  });

  final String imagePath;

  /// Opened from the drafts sheet — skip "save draft?" if nothing changed.
  final bool fromDraft;

  /// Remote draft id when [fromDraft] came from CDN/DB.
  final String? draftId;

  bool get isAsset => imagePath.startsWith('assets/');
}
