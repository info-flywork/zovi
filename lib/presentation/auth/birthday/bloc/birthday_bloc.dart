import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/presentation/auth/birthday/bloc/birthday_event.dart';
import 'package:zovi/presentation/auth/birthday/bloc/birthday_state.dart';
import 'package:zovi/presentation/auth/model/signup_flow.dart';

class BirthdayBloc extends Bloc<BirthdayEvent, BirthdayState> {
  BirthdayBloc(
    {
    required SignupFlow signupFlow,
    DateTime? initialBirthDate,
  }) : super(
          BirthdayInitial(
            signupFlow: signupFlow,
            birthDate: initialBirthDate ?? DateTime(1996, 2, 18),
          ),
        ) {
    on<BirthdayDateChanged>(_onDateChanged);
    on<BirthdayContinueTapped>(_onContinue);
  }

  void _onDateChanged(BirthdayDateChanged event, Emitter<BirthdayState> emit) {
    emit(
      BirthdayInitial(
        signupFlow: state.signupFlow,
        birthDate: event.birthDate,
      ),
    );
  }

  Future<void> _onContinue(
    BirthdayContinueTapped event,
    Emitter<BirthdayState> emit,
  ) async {
    emit(
      BirthdayLoading(
        signupFlow: state.signupFlow,
        birthDate: state.birthDate,
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 600));

    emit(
      BirthdaySuccess(
        navigateTo: RoutePaths.notificationPermission.path,
        signupFlow: state.signupFlow,
        birthDate: state.birthDate,
      ),
    );
  }
}
