import 'package:dio/dio.dart';
import 'package:zovi/core/managers/auth_cache_manager.dart';
import 'package:zovi/core/utils/constants/string_constants.dart';

abstract final class DioClient {
  static Dio create(AuthCacheManager authCache) {
    final dio = Dio(
      BaseOptions(
        baseUrl: StringConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await authCache.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );

    return dio;
  }
}
