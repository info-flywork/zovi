import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Kamera compose taslakları — app documents altında saklanır.
abstract final class CameraDrafts {
  static const folderName = 'camera_drafts';
  static const legacyFileName = 'camera_compose_draft.png';
  static const thumbFileName = 'camera_last_thumb.jpg';

  static Future<Directory> directory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$folderName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<File> saveBytes(List<int> bytes) async {
    final dir = await directory();
    final file = File(
      '${dir.path}/draft_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes, flush: true);

    final docs = await getApplicationDocumentsDirectory();
    await File('${docs.path}/$thumbFileName').writeAsBytes(bytes, flush: true);
    return file;
  }

  static Future<List<File>> list() async {
    final files = <File>[];

    final dir = await directory();
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final path = entity.path.toLowerCase();
        if (path.endsWith('.png') ||
            path.endsWith('.jpg') ||
            path.endsWith('.jpeg')) {
          files.add(entity);
        }
      }
    }

    // Eski tek-dosya taslağı da dahil et.
    final docs = await getApplicationDocumentsDirectory();
    final legacy = File('${docs.path}/$legacyFileName');
    if (await legacy.exists()) {
      files.add(legacy);
    }

    files.sort(
      (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
    );
    return files;
  }
}
