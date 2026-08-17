import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/domain/auth/auth_repository.dart';
import 'package:zovi/domain/auth/models/username_taken_exception.dart';
import 'package:zovi/presentation/auth/create_profile/bloc/create_profile_event.dart';
import 'package:zovi/presentation/auth/create_profile/bloc/create_profile_state.dart';
import 'package:zovi/presentation/auth/model/signup_flow.dart';

final class CreateProfileBloc
    extends Bloc<CreateProfileEvent, CreateProfileState> {
  CreateProfileBloc({
    required SignupFlow signupFlow,
    required this._authRepository,
  }) : super(CreateProfileInitial(signupFlow: signupFlow)) {
    on<CreateProfileFullNameChanged>(_onFullNameChanged);
    on<CreateProfileUsernameChanged>(_onUsernameChanged);
    on<CreateProfileUsernameCheckRequested>(_onUsernameCheck);
    on<CreateProfileUsernameSuggestionSelected>(_onSuggestionSelected);
    on<CreateProfileContinueTapped>(_onContinue);
  }

  final AuthRepository _authRepository;
  Timer? _usernameDebounce;

  static const _singleNameMax = 25;
  static const _fullNameMax = 50;
  static const _usernameMax = 15;

  static String _limitFullName(String text) {
    final maxLen = text.contains(RegExp(r'\s')) ? _fullNameMax : _singleNameMax;
    if (text.length <= maxLen) return text;
    return text.substring(0, maxLen);
  }

  static String _sanitizeUsername(String text) {
    final cleaned = text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
    if (cleaned.length <= _usernameMax) return cleaned;
    return cleaned.substring(0, _usernameMax);
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
        usernameStatus: state.usernameStatus,
        usernameSuggestions: state.usernameSuggestions,
      ),
    );
  }

  void _onUsernameChanged(
    CreateProfileUsernameChanged event,
    Emitter<CreateProfileState> emit,
  ) {
    final username = _sanitizeUsername(event.username);
    emit(
      CreateProfileInitial(
        fullName: state.fullName,
        username: username,
        signupFlow: state.signupFlow,
        usernameStatus: username.isEmpty
            ? UsernameAvailabilityStatus.idle
            : UsernameAvailabilityStatus.checking,
        usernameSuggestions: const [],
      ),
    );

    _usernameDebounce?.cancel();
    if (username.isEmpty) return;
    _usernameDebounce = Timer(const Duration(milliseconds: 450), () {
      add(CreateProfileUsernameCheckRequested(username));
    });
  }

  Future<void> _onUsernameCheck(
    CreateProfileUsernameCheckRequested event,
    Emitter<CreateProfileState> emit,
  ) async {
    final username = _sanitizeUsername(event.username);
    if (username != state.username) return;

    if (username.length < 3) {
      emit(
        CreateProfileInitial(
          fullName: state.fullName,
          username: username,
          signupFlow: state.signupFlow,
          usernameStatus: UsernameAvailabilityStatus.invalid,
          usernameSuggestions: const [],
        ),
      );
      return;
    }

    emit(
      CreateProfileInitial(
        fullName: state.fullName,
        username: username,
        signupFlow: state.signupFlow,
        usernameStatus: UsernameAvailabilityStatus.checking,
        usernameSuggestions: const [],
      ),
    );

    try {
      final result = await _authRepository.checkUsernameAvailability(username);
      if (username != state.username) return;

      if (!result.valid) {
        emit(
          CreateProfileInitial(
            fullName: state.fullName,
            username: username,
            signupFlow: state.signupFlow,
            usernameStatus: UsernameAvailabilityStatus.invalid,
            usernameSuggestions: const [],
          ),
        );
        return;
      }

      emit(
        CreateProfileInitial(
          fullName: state.fullName,
          username: username,
          signupFlow: state.signupFlow,
          usernameStatus: result.available
              ? UsernameAvailabilityStatus.available
              : UsernameAvailabilityStatus.taken,
          usernameSuggestions: result.available ? const [] : result.suggestions,
        ),
      );
    } catch (_) {
      if (username != state.username) return;
      emit(
        CreateProfileError(
          message: 'error_username_check_failed'.tr(),
          fullName: state.fullName,
          username: username,
          signupFlow: state.signupFlow,
          usernameStatus: UsernameAvailabilityStatus.idle,
          usernameSuggestions: const [],
        ),
      );
    }
  }

  void _onSuggestionSelected(
    CreateProfileUsernameSuggestionSelected event,
    Emitter<CreateProfileState> emit,
  ) {
    final username = _sanitizeUsername(event.username);
    emit(
      CreateProfileInitial(
        fullName: state.fullName,
        username: username,
        signupFlow: state.signupFlow,
        usernameStatus: UsernameAvailabilityStatus.checking,
        usernameSuggestions: const [],
      ),
    );
    add(CreateProfileUsernameCheckRequested(username));
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
          usernameStatus: state.usernameStatus,
          usernameSuggestions: state.usernameSuggestions,
        ),
      );
      return;
    }

    emit(
      CreateProfileLoading(
        fullName: state.fullName,
        username: state.username,
        signupFlow: state.signupFlow,
        usernameStatus: state.usernameStatus,
        usernameSuggestions: state.usernameSuggestions,
      ),
    );

    try {
      final availability = await _authRepository.checkUsernameAvailability(
        state.username,
      );
      if (!availability.available) {
        emit(
          CreateProfileInitial(
            fullName: state.fullName,
            username: state.username,
            signupFlow: state.signupFlow,
            usernameStatus: availability.valid
                ? UsernameAvailabilityStatus.taken
                : UsernameAvailabilityStatus.invalid,
            usernameSuggestions: availability.suggestions,
          ),
        );
        return;
      }

      await _authRepository.saveProfile(
        fullName: state.fullName,
        username: state.username,
      );

      emit(
        CreateProfileSuccess(
          navigateTo: RoutePaths.birthday.path,
          fullName: state.fullName,
          username: state.username,
          signupFlow: state.signupFlow,
          usernameStatus: UsernameAvailabilityStatus.available,
        ),
      );
    } on UsernameTakenException catch (e) {
      emit(
        CreateProfileInitial(
          fullName: state.fullName,
          username: state.username,
          signupFlow: state.signupFlow,
          usernameStatus: UsernameAvailabilityStatus.taken,
          usernameSuggestions: e.suggestions,
        ),
      );
    } catch (_) {
      emit(
        CreateProfileError(
          message: 'error_save_profile_failed'.tr(),
          fullName: state.fullName,
          username: state.username,
          signupFlow: state.signupFlow,
          usernameStatus: state.usernameStatus,
          usernameSuggestions: state.usernameSuggestions,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _usernameDebounce?.cancel();
    return super.close();
  }
}
