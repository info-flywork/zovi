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
  }) async {
    final response = await _dio.request<dynamic>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: Options(method: method.name.toUpperCase()),
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
