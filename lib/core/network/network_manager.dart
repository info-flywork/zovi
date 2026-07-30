import 'package:dio/dio.dart';
import 'package:zovi/core/utils/enum/request_type.dart';

class NetworkManager {
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
  }) async {
    final fields = <String, dynamic>{...?data};
    fields[fieldName] = await MultipartFile.fromFile(
      filePath,
      filename: filename ?? filePath.split('/').last,
    );
    final formData = FormData.fromMap(fields);

    final response = await _dio.post<dynamic>(
      path,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
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
