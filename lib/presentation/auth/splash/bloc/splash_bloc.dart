import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/domain/auth/auth_repository.dart';
import 'package:zovi/presentation/auth/splash/bloc/splash_event.dart';
import 'package:zovi/presentation/auth/splash/bloc/splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc(this._authRepository) : super(const SplashInitial()) {
    on<SplashStarted>(_onStarted);
  }

  final AuthRepository _authRepository;

  Future<void> _onStarted(
    SplashStarted event,
    Emitter<SplashState> emit,
  ) async {
    emit(const SplashLoading());
    await Future<void>.delayed(const Duration(milliseconds: 1800));

    final introDone = await _authRepository.isIntroDone();
    if (!introDone) {
      emit(SplashNavigateTo(RoutePaths.intro.path));
      return;
    }

    final onboardingDone = await _authRepository.isOnboardingDone();
    if (!onboardingDone) {
      emit(SplashNavigateTo(RoutePaths.onboarding.path));
      return;
    }

    final isAuthenticated = await _authRepository.isAuthenticated();
    emit(
      SplashNavigateTo(
        isAuthenticated ? RoutePaths.home.path : RoutePaths.onboarding.path,
      ),
    );
  }
}
