import 'package:dio/dio.dart';
import 'package:zovi/core/utils/constants/string_constants.dart';

abstract final class DioClient {
  static Dio create() {
    return Dio(
      BaseOptions(
        baseUrl: StringConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }
}
