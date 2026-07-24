import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/presentation/auth/model/signup_flow.dart';
import 'package:zovi/presentation/auth/create_profile/bloc/create_profile_event.dart';
import 'package:zovi/presentation/auth/create_profile/bloc/create_profile_state.dart';

class CreateProfileBloc extends Bloc<CreateProfileEvent, CreateProfileState> {
  CreateProfileBloc({required SignupFlow signupFlow})
      : super(CreateProfileInitial(signupFlow: signupFlow)) {
    on<CreateProfileFullNameChanged>(_onFullNameChanged);
    on<CreateProfileUsernameChanged>(_onUsernameChanged);
    on<CreateProfileContinueTapped>(_onContinue);
  }

  static const _singleNameMax = 25;
  static const _fullNameMax = 50;
  static const _usernameMax = 15;

  static String _limitFullName(String text) {
    final maxLen = text.contains(RegExp(r'\s')) ? _fullNameMax : _singleNameMax;
    if (text.length <= maxLen) return text;
    return text.substring(0, maxLen);
  }

  static String _limitUsername(String text) {
    if (text.length <= _usernameMax) return text;
    return text.substring(0, _usernameMax);
  }

  void _onFullNameChanged(
    CreateProfileFullNameChanged event,
    Emitter<CreateProfileState> emit,
  ) {
    emit(
      CreateProfileInitial(
        fullName: _limitFullName(event.fullName),
        username: state.username,
        signupFlow: state.signupFlow,
      ),
    );
  }

  void _onUsernameChanged(
    CreateProfileUsernameChanged event,
    Emitter<CreateProfileState> emit,
  ) {
    emit(
      CreateProfileInitial(
        fullName: state.fullName,
        username: _limitUsername(event.username),
        signupFlow: state.signupFlow,
      ),
    );
  }

  Future<void> _onContinue(
    CreateProfileContinueTapped event,
    Emitter<CreateProfileState> emit,
  ) async {
    if (!state.isFormComplete) {
      emit(
        CreateProfileError(
          message: 'error_enter_name_username'.tr(),
          fullName: state.fullName,
          username: state.username,
          signupFlow: state.signupFlow,
        ),
      );
      return;
    }

    emit(
      CreateProfileLoading(
        fullName: state.fullName,
        username: state.username,
        signupFlow: state.signupFlow,
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 600));

    emit(
      CreateProfileSuccess(
        navigateTo: RoutePaths.birthday.path,
        fullName: state.fullName,
        username: state.username,
        signupFlow: state.signupFlow,
      ),
    );
  }
}
