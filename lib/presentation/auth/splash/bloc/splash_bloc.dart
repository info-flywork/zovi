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

  Future<void> _onStarted(
    SplashStarted event,
    Emitter<SplashState> emit,
  ) async {
    emit(const SplashLoading());

    final introDone = await _authRepository.isIntroDone();
    if (!introDone) {
      emit(SplashNavigateTo(RoutePaths.intro.path));
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

        emit(SplashNavigateTo(dest.path, extra: dest.extra));
        return;
      } catch (_) {
        _userRepository.clearSessionCache();
        emit(SplashNavigateTo(RoutePaths.onboarding.path));
        return;
      }
    }

    _userRepository.clearSessionCache();
    emit(SplashNavigateTo(RoutePaths.onboarding.path));
  }
}
