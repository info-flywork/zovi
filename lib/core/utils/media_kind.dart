bool isVideoMimeType(String? mimeType) {
  final mime = mimeType?.trim().toLowerCase() ?? '';
  return mime.startsWith('video/');
}

bool isVideoMediaPath(String path) {
  final lower = path.toLowerCase().split('?').first;
  return lower.endsWith('.mp4') ||
      lower.endsWith('.mov') ||
      lower.endsWith('.m4v') ||
      lower.endsWith('.webm') ||
      lower.endsWith('.avi') ||
      lower.endsWith('.mkv');
}

bool isVideoMedia({String? mediaType, String? mimeType, String path = ''}) {
  final type = mediaType?.trim().toLowerCase() ?? '';
  if (type == 'video' || type.startsWith('video/')) return true;
  if (isVideoMimeType(mimeType)) return true;
  return isVideoMediaPath(path);
}
