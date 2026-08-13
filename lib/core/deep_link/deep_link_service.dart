import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/router/app_router.dart';
import 'package:zovi/core/utils/constants/string_constants.dart';
import 'package:zovi/domain/auth/auth_repository.dart';

/// Handles Universal / App Links for profile share URLs:
/// `https://zovi.fly-work.com/u/{handle}`
class DeepLinkService {
  DeepLinkService(this._authRepository);

  final AuthRepository _authRepository;
  final AppLinks _appLinks = AppLinks();

  StreamSubscription<Uri>? _sub;
  Uri? _pending;
  var _ready = false;
  var _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        _handleUri(initial, fromColdStart: true);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('DeepLinkService initial link failed: $e');
    }

    _sub = _appLinks.uriLinkStream.listen(
      (uri) => _handleUri(uri, fromColdStart: false),
      onError: (Object e) {
        if (kDebugMode) debugPrint('DeepLinkService stream error: $e');
      },
    );
  }

  /// Call after splash navigates to an authenticated destination.
  Future<void> markReadyAndFlush() async {
    _ready = true;
    await flushPending();
  }

  Future<void> flushPending() async {
    final pending = _pending;
    if (pending == null) return;
    if (!await _canOpenProfileLinks()) return;
    _pending = null;
    _navigateProfileUri(pending);
  }

  void dispose() {
    unawaited(_sub?.cancel());
    _sub = null;
  }

  void _handleUri(Uri uri, {required bool fromColdStart}) {
    if (isFirebaseAuthCallback(uri)) return;
    final handle = parseProfileHandle(uri);
    if (handle == null || handle.isEmpty) return;

    if (!_ready || fromColdStart) {
      _pending = uri;
      if (_ready) unawaited(flushPending());
      return;
    }

    unawaited(_openIfAuthenticated(uri));
  }

  Future<void> _openIfAuthenticated(Uri uri) async {
    if (!await _canOpenProfileLinks()) {
      _pending = uri;
      return;
    }
    _navigateProfileUri(uri);
  }

  Future<bool> _canOpenProfileLinks() async {
    try {
      return await _authRepository.isAuthenticated();
    } catch (_) {
      return false;
    }
  }

  void _navigateProfileUri(Uri uri) {
    final handle = parseProfileHandle(uri);
    if (handle == null || handle.isEmpty) return;
    final router = AppRouter.router;
    final path = '/u/${Uri.encodeComponent(handle)}';
    final ctx = AppRouter.rootKey.currentContext;
    if (ctx != null && GoRouter.of(ctx).canPop()) {
      router.push(path);
    } else {
      router.go(path);
    }
  }

  /// Accepts `https://zovi.fly-work.com/u/{handle}` (and www) plus `zovi://u/{handle}`.
  static String? parseProfileHandle(Uri uri) {
    final host = uri.host.toLowerCase();
    final scheme = uri.scheme.toLowerCase();
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

    String? rawHandle;
    if ((scheme == 'https' || scheme == 'http') &&
        (host == StringConstants.profileShareHost ||
            host == 'www.${StringConstants.profileShareHost}')) {
      if (segments.length >= 2 && segments.first.toLowerCase() == 'u') {
        rawHandle = segments[1];
      }
    } else if (scheme == 'zovi') {
      // zovi://u/{handle} → host=u, path=/{handle}
      if (host == 'u' && segments.isNotEmpty) {
        rawHandle = segments.first;
      } else if (segments.length >= 2 && segments.first.toLowerCase() == 'u') {
        rawHandle = segments[1];
      }
    }

    if (rawHandle == null) return null;
    final handle = rawHandle.trim().replaceFirst(RegExp(r'^@'), '').toLowerCase();
    if (handle.isEmpty) return null;
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(handle)) return null;
    return handle;
  }

  static bool isFirebaseAuthCallback(Uri uri) {
    final raw = uri.toString();
    if (raw.contains('firebaseauth') ||
        raw.contains('recaptchaToken') ||
        raw.contains('__/auth/callback') ||
        uri.host == 'firebaseauth' ||
        uri.scheme.startsWith('com.googleusercontent.apps')) {
      return true;
    }
    if (uri.path == '/link' || uri.path.endsWith('/link')) {
      final q = uri.queryParameters;
      if (q.containsKey('deep_link_id') || q.containsKey('recaptchaToken')) {
        return true;
      }
    }
    return false;
  }
}
