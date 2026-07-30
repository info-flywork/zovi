import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/// Downloads remote music once and reuses the local file for later playback.
class MusicAudioCache {
  MusicAudioCache(this._dio);

  final Dio _dio;
  Directory? _dir;
  final _inFlight = <String, Future<File>>{};

  Future<Directory> _ensureDir() async {
    final existing = _dir;
    if (existing != null) return existing;
    final root = await getApplicationSupportDirectory();
    final dir = Directory('${root.path}/music_audio_cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _dir = dir;
    return dir;
  }

  String _fileKey(String trackId, String url) {
    final raw = trackId.trim().isNotEmpty ? trackId.trim() : url.trim();
    return sha1.convert(utf8.encode(raw)).toString();
  }

  Future<File> _fileFor(String trackId, String url) async {
    final dir = await _ensureDir();
    return File('${dir.path}/${_fileKey(trackId, url)}.mp3');
  }

  /// Returns a playable [Source]. Prefers disk cache; downloads on miss.
  Future<Source> resolveSource({
    required String trackId,
    required String url,
  }) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('audio url is empty');
    }

    final file = await _fileFor(trackId, trimmed);
    if (await file.exists() && await file.length() > 1024) {
      return DeviceFileSource(file.path);
    }

    final downloaded = await _download(trackId: trackId, url: trimmed, file: file);
    return DeviceFileSource(downloaded.path);
  }

  Future<File> _download({
    required String trackId,
    required String url,
    required File file,
  }) {
    final key = _fileKey(trackId, url);
    final existing = _inFlight[key];
    if (existing != null) return existing;

    final future = () async {
      final tmp = File('${file.path}.tmp');
      try {
        if (await tmp.exists()) {
          await tmp.delete();
        }
        await _dio.download(
          url,
          tmp.path,
          options: Options(
            receiveTimeout: const Duration(minutes: 2),
            sendTimeout: const Duration(seconds: 30),
          ),
        );
        if (await file.exists()) {
          await file.delete();
        }
        await tmp.rename(file.path);
        return file;
      } catch (_) {
        if (await tmp.exists()) {
          try {
            await tmp.delete();
          } catch (_) {}
        }
        rethrow;
      } finally {
        _inFlight.remove(key);
      }
    }();

    _inFlight[key] = future;
    return future;
  }

  /// Best-effort prefetch so trim/save playback is instant next time.
  Future<void> prefetch({required String trackId, required String url}) async {
    try {
      await resolveSource(trackId: trackId, url: url);
    } catch (_) {
      // ignore prefetch failures
    }
  }
}
