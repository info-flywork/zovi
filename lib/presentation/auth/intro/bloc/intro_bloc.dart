import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/domain/auth/auth_repository.dart';
import 'package:zovi/presentation/auth/intro/bloc/intro_event.dart';
import 'package:zovi/presentation/auth/intro/bloc/intro_state.dart';

class IntroBloc extends Bloc<IntroEvent, IntroState> {
  IntroBloc(this._authRepository) : super(const IntroInProgress()) {
    on<IntroPageChanged>(_onPageChanged);
    on<IntroContinueTapped>(_onContinue);
    on<IntroGetStartedTapped>(_onGetStarted);
  }

  static const pageCount = 3;

  final AuthRepository _authRepository;

  void _onPageChanged(IntroPageChanged event, Emitter<IntroState> emit) {
    emit(IntroInProgress(pageIndex: event.index));
  }

  void _onContinue(IntroContinueTapped event, Emitter<IntroState> emit) {
    final next = state.pageIndex + 1;
    if (next >= pageCount) {
      add(const IntroGetStartedTapped());
      return;
    }
    emit(IntroInProgress(pageIndex: next));
  }

  Future<void> _onGetStarted(
    IntroGetStartedTapped event,
    Emitter<IntroState> emit,
  ) async {
    await _authRepository.completeIntro();
    emit(
      IntroCompleted(
        navigateTo: RoutePaths.onboarding.path,
        pageIndex: state.pageIndex,
      ),
    );
  }
}
