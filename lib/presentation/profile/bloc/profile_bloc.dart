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

final class ProfilePlansRefreshRequested extends ProfileEvent {
  const ProfilePlansRefreshRequested();
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

  ProfileLoaded copyWith({
    UserProfile? user,
    List<CheckInItem>? checkIns,
    List<PulseItem>? pulses,
    List<StampItem>? stamps,
    List<PlanItem>? plans,
  }) {
    return ProfileLoaded(
      user: user ?? this.user,
      checkIns: checkIns ?? this.checkIns,
      pulses: pulses ?? this.pulses,
      stamps: stamps ?? this.stamps,
      plans: plans ?? this.plans,
    );
  }

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
    on<ProfileStarted>(_onStarted);
    on<ProfileUserUpdated>(_onUserUpdated);
    on<ProfilePlansRefreshRequested>(_onPlansRefresh);
  }

  final UserRepository _userRepository;

  Future<void> _onStarted(
    ProfileStarted event,
    Emitter<ProfileState> emit,
  ) async {
    final cached = _userRepository.cachedCurrentUser;
    final hasCache = _userRepository.hasCachedProfile && cached != null;
    final previous = state is ProfileLoaded ? state as ProfileLoaded : null;

    if (hasCache) {
      // Daha önce yüklenmiş section'ları silme — boş "planın yok" flicker'ı olmasın.
      if (previous == null) {
        emit(
          ProfileLoaded(
            user: cached,
            checkIns: const [],
            pulses: const [],
            stamps: const [],
            plans: const [],
          ),
        );
      } else {
        emit(previous.copyWith(user: cached));
      }

      final checkIns = await _userRepository.getCheckIns();
      final pulses = await _userRepository.getPulses();
      final stamps = await _userRepository.getStamps();
      final plans = await _userRepository.getTodayPlans();
      if (!emit.isDone) {
        emit(
          ProfileLoaded(
            user: cached,
            checkIns: checkIns,
            pulses: pulses,
            stamps: stamps,
            plans: plans,
          ),
        );
      }

      try {
        final fresh = await _userRepository.getCurrentUser();
        if (!emit.isDone && state is ProfileLoaded) {
          emit((state as ProfileLoaded).copyWith(user: fresh));
        }
      } catch (_) {}
      return;
    }

    // İlk açılışta önceki loaded state varsa onu koru, loading flicker yok.
    if (previous == null) {
      emit(const ProfileLoading());
    }
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
      if (previous == null) {
        emit(ProfileError(e.toString()));
      }
    }
  }

  Future<void> _onUserUpdated(
    ProfileUserUpdated event,
    Emitter<ProfileState> emit,
  ) async {
    await _userRepository.updateCurrentUser(event.user);
    final currentState = state;
    if (currentState is ProfileLoaded) {
      emit(currentState.copyWith(user: event.user));
    }
  }

  Future<void> _onPlansRefresh(
    ProfilePlansRefreshRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProfileLoaded) return;
    try {
      final plans = await _userRepository.getTodayPlans();
      if (!emit.isDone) {
        emit(currentState.copyWith(plans: plans));
      }
    } catch (_) {}
  }
}
