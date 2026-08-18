import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/utils/media_kind.dart';
import 'package:zovi/domain/auth/auth_repository.dart';

/// Local helper for story drafts — CDN/DB is source of truth; disk is a cache.
abstract final class CameraDrafts {
  static const folderName = 'camera_drafts';
  static const _cacheExts = [
    '.png',
    '.jpg',
    '.jpeg',
    '.webp',
    '.mp4',
    '.mov',
    '.m4v',
  ];

  static String? _currentUserScope() {
    final uid = getIt<AuthRepository>().currentFirebaseUid?.trim();
    if (uid == null || uid.isEmpty) return null;
    return uid.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  static Future<Directory> directory({String? userId}) async {
    final docs = await getApplicationDocumentsDirectory();
    final scope = userId ?? _currentUserScope() ?? 'anonymous';
    final dir = Directory('${docs.path}/$folderName/$scope');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static String _extFromPath(String path, {required String fallback}) {
    final clean = path.toLowerCase().split('?').first;
    final slash = clean.lastIndexOf('/');
    final dot = clean.lastIndexOf('.');
    if (dot > slash && dot >= 0) {
      return clean.substring(dot);
    }
    return fallback;
  }

  /// Keeps a local copy after a successful CDN upload so reopen is instant.
  static Future<File> cacheRemoteDraft({
    required String draftId,
    required List<int> bytes,
    String ext = '.png',
  }) async {
    final dir = await directory();
    final safeId = draftId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final file = File('${dir.path}/draft_$safeId$ext');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static Future<File> cacheRemoteDraftFile({
    required String draftId,
    required String sourcePath,
  }) async {
    final dir = await directory();
    final safeId = draftId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final ext = _extFromPath(
      sourcePath,
      fallback: isVideoMediaPath(sourcePath) ? '.mp4' : '.png',
    );
    final file = File('${dir.path}/draft_$safeId$ext');
    await File(sourcePath).copy(file.path);
    return file;
  }

  static Future<File?> peekCachedDraft(String draftId) async {
    final dir = await directory();
    final safeId = draftId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    for (final ext in _cacheExts) {
      final file = File('${dir.path}/draft_$safeId$ext');
      if (await file.exists() && await file.length() > 256) return file;
    }
    return null;
  }

  /// Downloads a CDN draft into the per-user cache and returns the local file.
  static Future<File> materializeRemoteDraft(StoryDraftItem draft) async {
    final cached = await peekCachedDraft(draft.id);
    if (cached != null) return cached;

    final dir = await directory();
    final safeId = draft.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final ext = _extFromPath(
      draft.mediaUrl,
      fallback: draft.isVideo ? '.mp4' : '.png',
    );
    final file = File('${dir.path}/draft_$safeId$ext');
    final tmp = File('${file.path}.tmp');

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 45),
        headers: const {'User-Agent': 'zovi-app/1.0'},
      ),
    );
    await dio.download(draft.mediaUrl, tmp.path);
    if (await file.exists()) {
      await file.delete();
    }
    await tmp.rename(file.path);
    return file;
  }

  /// Upload compose bytes to CDN/DB and mirror locally.
  static Future<StoryDraftItem> saveRemote(List<int> bytes) async {
    final dir = await directory();
    final temp = File(
      '${dir.path}/upload_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await temp.writeAsBytes(bytes, flush: true);
    try {
      final draft = await getIt<AuthRepository>().uploadStoryDraft(temp.path);
      await cacheRemoteDraft(draftId: draft.id, bytes: bytes);
      return draft;
    } finally {
      try {
        if (await temp.exists()) await temp.delete();
      } catch (_) {}
    }
  }

  static Future<StoryDraftItem> saveRemoteFromPath(
    String sourcePath, {
    bool isVideo = false,
  }) async {
    final draft = await getIt<AuthRepository>().uploadStoryDraft(
      sourcePath,
      isVideo: isVideo,
    );
    try {
      await cacheRemoteDraftFile(draftId: draft.id, sourcePath: sourcePath);
    } catch (_) {}
    return draft;
  }
}
