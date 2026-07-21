import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zovi/domain/user/user_repository.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

final class ProfileStarted extends ProfileEvent {
  const ProfileStarted();
}

final class ProfileUserUpdated extends ProfileEvent {
  const ProfileUserUpdated(this.user);

  final UserProfile user;

  @override
  List<Object?> get props => [user];
}

sealed class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

final class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

final class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

final class ProfileLoaded extends ProfileState {
  const ProfileLoaded({
    required this.user,
    required this.checkIns,
    required this.pulses,
    required this.stamps,
    required this.plans,
  });

  final UserProfile user;
  final List<CheckInItem> checkIns;
  final List<PulseItem> pulses;
  final List<StampItem> stamps;
  final List<PlanItem> plans;

  @override
  List<Object?> get props => [user, checkIns, pulses, stamps, plans];
}

final class ProfileError extends ProfileState {
  const ProfileError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc(this._userRepository) : super(const ProfileInitial()) {
    on<ProfileStarted>((event, emit) async {
      emit(const ProfileLoading());
      try {
        final user = await _userRepository.getCurrentUser();
        final checkIns = await _userRepository.getCheckIns();
        final pulses = await _userRepository.getPulses();
        final stamps = await _userRepository.getStamps();
        final plans = await _userRepository.getTodayPlans();
        emit(
          ProfileLoaded(
            user: user,
            checkIns: checkIns,
            pulses: pulses,
            stamps: stamps,
            plans: plans,
          ),
        );
      } catch (e) {
        emit(ProfileError(e.toString()));
      }
    });
    on<ProfileUserUpdated>((event, emit) async {
      await _userRepository.updateCurrentUser(event.user);
      final currentState = state;
      if (currentState is ProfileLoaded) {
        emit(
          ProfileLoaded(
            user: event.user,
            checkIns: currentState.checkIns,
            pulses: currentState.pulses,
            stamps: currentState.stamps,
            plans: currentState.plans,
          ),
        );
      }
    });
  }

  final UserRepository _userRepository;
}
