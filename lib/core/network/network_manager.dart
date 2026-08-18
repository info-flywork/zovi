import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:zovi/core/utils/enum/request_type.dart';
import 'package:zovi/core/utils/media_kind.dart';

final class NetworkManager {
  NetworkManager(this._dio);

  final Dio _dio;

  Future<T?> send<T>({
    required String path,
    required RequestType method,
    required T Function(Map<String, dynamic> json) parserModel,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Duration? receiveTimeout,
  }) async {
    final response = await _dio.request<dynamic>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: Options(
        method: method.name.toUpperCase(),
        receiveTimeout: receiveTimeout,
      ),
    );

    final body = response.data;
    if (body is! Map<String, dynamic>) return null;

    final payload = body['data'];
    if (payload is Map<String, dynamic>) {
      return parserModel(payload);
    }
    return parserModel(body);
  }

  Future<T?> uploadFile<T>({
    required String path,
    required String filePath,
    required String fieldName,
    required T Function(Map<String, dynamic> json) parserModel,
    String? filename,
    Map<String, dynamic>? data,
    Duration sendTimeout = const Duration(seconds: 60),
    Duration receiveTimeout = const Duration(seconds: 60),
  }) async {
    final fields = <String, dynamic>{...?data};
    final name = filename ?? filePath.split('/').last;
    fields[fieldName] = await MultipartFile.fromFile(
      filePath,
      filename: name,
      contentType: _contentTypeFor(filePath, name),
    );
    final formData = FormData.fromMap(fields);

    final response = await _dio.post<dynamic>(
      path,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: sendTimeout,
        receiveTimeout: receiveTimeout,
      ),
    );

    final body = response.data;
    if (body is! Map<String, dynamic>) return null;
    final payload = body['data'];
    if (payload is Map<String, dynamic>) {
      return parserModel(payload);
    }
    return parserModel(body);
  }
}

MediaType? _contentTypeFor(String filePath, String filename) {
  final lower = '${filePath.toLowerCase()} ${filename.toLowerCase()}';
  if (isVideoMediaPath(filePath) || isVideoMediaPath(filename)) {
    if (lower.contains('.mov')) return MediaType('video', 'quicktime');
    if (lower.contains('.webm')) return MediaType('video', 'webm');
    return MediaType('video', 'mp4');
  }
  if (lower.contains('.jpg') || lower.contains('.jpeg')) {
    return MediaType('image', 'jpeg');
  }
  if (lower.contains('.webp')) return MediaType('image', 'webp');
  if (lower.contains('.gif')) return MediaType('image', 'gif');
  if (lower.contains('.png')) return MediaType('image', 'png');
  return null;
}
