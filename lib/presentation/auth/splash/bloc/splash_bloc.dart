import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/domain/auth/auth_repository.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/auth/splash/bloc/splash_event.dart';
import 'package:zovi/presentation/auth/splash/bloc/splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
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
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final introDone = await _authRepository.isIntroDone();
    if (!introDone) {
      emit(SplashNavigateTo(RoutePaths.intro.path));
      return;
    }

    final isAuthenticated = await _authRepository.isAuthenticated();
    if (isAuthenticated) {
      try {
        final session = await _authRepository.syncSession();
        // Login ise profili splash'te çek — profil tab'ı loading göstermesin.
        try {
          await _userRepository.getCurrentUser();
        } catch (_) {
          // Profil fail olsa da auth akışı devam etsin.
        }
        final dest = session.destination;
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
