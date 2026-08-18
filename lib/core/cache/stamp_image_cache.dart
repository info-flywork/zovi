import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/// Downloads CDN stamp/sticker images once and reuses local files.
final class StampImageCache {
  StampImageCache([Dio? dio])
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 45),
                headers: const {'User-Agent': 'zovi-app/1.0'},
              ),
            );

  final Dio _dio;
  Directory? _dir;
  final _inFlight = <String, Future<File>>{};
  final _resolved = <String, File>{};

  Future<Directory> _ensureDir() async {
    final existing = _dir;
    if (existing != null) return existing;
    final root = await getApplicationSupportDirectory();
    final dir = Directory('${root.path}/stamp_image_cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _dir = dir;
    return dir;
  }

  String _fileKey(String stampId, String url) {
    final raw = stampId.trim().isNotEmpty ? stampId.trim() : url.trim();
    return sha1.convert(utf8.encode(raw)).toString();
  }

  String _extension(String url) {
    final path = Uri.tryParse(url)?.path ?? url;
    final lower = path.toLowerCase();
    if (lower.endsWith('.webp')) return 'webp';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'jpg';
    if (lower.endsWith('.gif')) return 'gif';
    return 'png';
  }

  Future<File> _fileFor(String stampId, String url) async {
    final dir = await _ensureDir();
    return File('${dir.path}/${_fileKey(stampId, url)}.${_extension(url)}');
  }

  /// Instant hit when this process already resolved the file.
  File? peekFile({required String stampId, required String url}) {
    return _resolved[_fileKey(stampId, url)];
  }

  /// Returns a local file for [url], downloading on cache miss.
  Future<File> resolveFile({
    required String stampId,
    required String url,
  }) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('stamp url is empty');
    }

    final key = _fileKey(stampId, trimmed);
    final remembered = _resolved[key];
    if (remembered != null) return remembered;

    final file = await _fileFor(stampId, trimmed);
    if (await file.exists() && await file.length() > 256) {
      _resolved[key] = file;
      return file;
    }

    return _download(stampId: stampId, url: trimmed, file: file, key: key);
  }

  Future<File> _download({
    required String stampId,
    required String url,
    required File file,
    required String key,
  }) {
    final existing = _inFlight[key];
    if (existing != null) return existing;

    final future = () async {
      final tmp = File('${file.path}.tmp');
      try {
        if (await tmp.exists()) {
          await tmp.delete();
        }
        await _dio.download(url, tmp.path);
        if (await file.exists()) {
          await file.delete();
        }
        await tmp.rename(file.path);
        _resolved[key] = file;
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

  Future<void> prefetch({required String stampId, required String url}) async {
    try {
      await resolveFile(stampId: stampId, url: url);
    } catch (_) {
      // ignore prefetch failures
    }
  }

  /// Downloads many images with a small concurrency pool so grids fill fast
  /// without flooding the network.
  Future<void> prefetchAll(
    Iterable<({String id, String url})> items, {
    int concurrency = 8,
  }) async {
    final queue = items
        .where((item) => item.url.trim().isNotEmpty)
        .toList(growable: false);
    if (queue.isEmpty) return;

    final limit = concurrency.clamp(1, 16);
    var next = 0;

    Future<void> worker() async {
      while (true) {
        final index = next++;
        if (index >= queue.length) return;
        final item = queue[index];
        await prefetch(stampId: item.id, url: item.url);
      }
    }

    await Future.wait(List.generate(limit, (_) => worker()));
  }
}
