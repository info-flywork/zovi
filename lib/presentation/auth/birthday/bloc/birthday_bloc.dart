import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/domain/auth/auth_repository.dart';
import 'package:zovi/presentation/auth/birthday/bloc/birthday_event.dart';
import 'package:zovi/presentation/auth/birthday/bloc/birthday_state.dart';
import 'package:zovi/presentation/auth/model/signup_flow.dart';

class BirthdayBloc extends Bloc<BirthdayEvent, BirthdayState> {
  BirthdayBloc({
    required SignupFlow signupFlow,
    required this._authRepository,
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

  final AuthRepository _authRepository;

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

    try {
      await _authRepository.saveProfile(birthDate: state.birthDate);
      emit(
        BirthdaySuccess(
          navigateTo: RoutePaths.notificationPermission.path,
          signupFlow: state.signupFlow,
          birthDate: state.birthDate,
        ),
      );
    } catch (_) {
      emit(
        BirthdayError(
          message: 'error_save_birthdate_failed'.tr(),
          signupFlow: state.signupFlow,
          birthDate: state.birthDate,
        ),
      );
    }
  }
}
