import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/domain/auth/auth_repository.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/auth/splash/bloc/splash_event.dart';
import 'package:zovi/presentation/auth/splash/bloc/splash_state.dart';

final class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc(this._authRepository, this._userRepository)
    : super(const SplashInitial()) {
    on<SplashStarted>(_onStarted);
  }

  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  static const _minSplashDuration = Duration(milliseconds: 1400);
  static const _expiredSessionSplashDelay = Duration(seconds: 2);

  /// Onboard/login olmuş ama token bitmiş kullanıcı splash'i görmeden
  /// login'e zıplamasın.
  Future<void> _holdSplashForExpiredSession() async {
    await Future<void>.delayed(_expiredSessionSplashDelay);
  }

  Future<void> _holdSplashToMeetMinimum(DateTime startedAt) async {
    final elapsed = DateTime.now().difference(startedAt);
    final remaining = _minSplashDuration - elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
  }

  Future<void> _navigateWithMinimumSplash(
    Emitter<SplashState> emit,
    DateTime startedAt,
    String path, {
    Object? extra,
  }) async {
    await _holdSplashToMeetMinimum(startedAt);
    emit(SplashNavigateTo(path, extra: extra));
  }

  Future<void> _onStarted(
    SplashStarted event,
    Emitter<SplashState> emit,
  ) async {
    final startedAt = DateTime.now();
    emit(const SplashLoading());

    final introDone = await _authRepository.isIntroDone();
    if (!introDone) {
      await _navigateWithMinimumSplash(emit, startedAt, RoutePaths.intro.path);
      return;
    }

    final isAuthenticated = await _authRepository.isAuthenticated();
    if (isAuthenticated) {
      try {
        final session = await _authRepository.resumeSessionForSplash();
        // Push login zaten /auth/sync içinde unawaited çalışıyor.
        final dest = session.destination;
        final goingHome =
            dest.path == RoutePaths.home.path ||
            dest.path.startsWith(RoutePaths.home.path);

        if (goingHome) {
          // Profil + stories + map friends tek Future.wait ile — ana sayfa hazır.
          try {
            await _userRepository.warmHomeBootstrap();
          } catch (_) {}
        } else {
          unawaited(
            _userRepository.getCurrentUser().then<void>(
              (_) {},
              onError: (_) {},
            ),
          );
        }

        await _navigateWithMinimumSplash(
          emit,
          startedAt,
          dest.path,
          extra: dest.extra,
        );
        return;
      } on SessionExpiredException {
        await _authRepository.logout();
        _userRepository.clearSessionCache();
        await _holdSplashForExpiredSession();
        await _navigateWithMinimumSplash(
          emit,
          startedAt,
          RoutePaths.onboarding.path,
        );
        return;
      } catch (_) {
        // Ağ / sync hatası oturumu düşürmesin — onboarding bitmişse home'a git.
        if (await _authRepository.isOnboardingDone()) {
          try {
            await _userRepository.warmHomeBootstrap();
          } catch (_) {}
          await _navigateWithMinimumSplash(
            emit,
            startedAt,
            RoutePaths.home.path,
          );
          return;
        }
        await _navigateWithMinimumSplash(
          emit,
          startedAt,
          RoutePaths.onboarding.path,
        );
        return;
      }
    }

    final returningExpired = await _authRepository.isOnboardingDone();
    await _authRepository.logoutIfStaleSession();
    _userRepository.clearSessionCache();
    if (returningExpired) {
      await _holdSplashForExpiredSession();
    }
    await _navigateWithMinimumSplash(emit, startedAt, RoutePaths.onboarding.path);
  }
}
