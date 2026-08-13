import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zovi/core/managers/auth_cache_manager.dart';
import 'package:zovi/core/utils/constants/string_constants.dart';

abstract final class DioClient {
  static Future<void> Function()? onSessionExpired;

  static Dio create(AuthCacheManager authCache) {
    late final Dio dio;
    var endingSession = false;

    Future<void> expireSession() async {
      if (endingSession) return;
      endingSession = true;
      try {
        await onSessionExpired?.call();
      } finally {
        endingSession = false;
      }
    }

    Future<String?> readFreshToken({required bool forceRefresh}) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return authCache.getAccessToken();
      try {
        final token = await user.getIdToken(forceRefresh);
        if (token != null && token.isNotEmpty) {
          await authCache.saveAccessToken(token);
          return token;
        }
      } catch (_) {}
      return authCache.getAccessToken();
    }

    dio = Dio(
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
          if (await authCache.isSessionExpired()) {
            unawaited(expireSession());
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.cancel,
                error: 'session_expired',
              ),
            );
            return;
          }

          if (options.extra['authRetried'] != true) {
            final token = await readFreshToken(forceRefresh: false);
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final status = error.response?.statusCode;
          final alreadyRetried = error.requestOptions.extra['authRetried'] == true;
          if (status != 401 || alreadyRetried) {
            handler.next(error);
            return;
          }

          final token = await readFreshToken(forceRefresh: true);
          if (token == null || token.isEmpty) {
            unawaited(expireSession());
            handler.next(error);
            return;
          }

          try {
            final req = error.requestOptions;
            req.extra['authRetried'] = true;
            req.headers['Authorization'] = 'Bearer $token';
            final response = await dio.fetch<dynamic>(req);
            handler.resolve(response);
          } catch (_) {
            unawaited(expireSession());
            handler.next(error);
          }
        },
      ),
    );

    return dio;
  }
}
