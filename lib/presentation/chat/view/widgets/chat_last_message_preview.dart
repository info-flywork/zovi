import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';

enum ChatMediaPreviewKind { image, voice, stamp }

ChatMediaPreviewKind? resolveChatMediaPreviewKind(String preview) {
  final t = preview.trim();
  if (t.isEmpty) return null;

  if (t == '📷' ||
      t == 'Fotoğraf' ||
      t.toLowerCase() == 'photo' ||
      t.toLowerCase() == 'photograph' ||
      t.startsWith('📷')) {
    return ChatMediaPreviewKind.image;
  }
  if (t == '🎤' ||
      t == 'Sesli mesaj' ||
      t == 'Ses' ||
      t.toLowerCase() == 'voice' ||
      t.toLowerCase() == 'voice message' ||
      t.startsWith('🎤')) {
    return ChatMediaPreviewKind.voice;
  }
  if (t == '🏷️' ||
      t == 'Sticker' ||
      t == 'Stamp' ||
      t.toLowerCase() == 'sticker' ||
      t.toLowerCase() == 'stamp' ||
      t.startsWith('🏷️')) {
    return ChatMediaPreviewKind.stamp;
  }
  return null;
}

/// Last-message row for chat / request lists (icon + label for media).
class ChatLastMessagePreview extends StatelessWidget {
  const ChatLastMessagePreview({
    super.key,
    required this.preview,
    required this.isUnread,
    this.maxLines = 2,
  });

  final String preview;
  final bool isUnread;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final kind = resolveChatMediaPreviewKind(preview);
    final color = isUnread ? AppColors.black : AppColors.textSecondary;
    final textStyle = TextStyle(
      fontSize: 15,
      fontWeight: isUnread ? FontWeight.w500 : FontWeight.w400,
      height: 20 / 15,
      letterSpacing: -0.32,
      color: color,
    );

    if (kind == null) {
      return Text(
        preview,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: textStyle,
      );
    }

    final (icon, labelKey) = switch (kind) {
      ChatMediaPreviewKind.image => (
          AssetPaths.iconChatGallery,
          'chat_preview_photo',
        ),
      ChatMediaPreviewKind.voice => (
          AssetPaths.iconChatMicrophone,
          'chat_preview_voice',
        ),
      ChatMediaPreviewKind.stamp => (
          AssetPaths.iconChatSticker,
          'chat_preview_sticker',
        ),
    };

    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.zoviOrange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: AppIcon(icon, size: 14, color: AppColors.zoviOrange),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            labelKey.tr(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
        ),
      ],
    );
  }
}
