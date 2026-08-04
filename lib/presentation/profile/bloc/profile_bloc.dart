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

/// Re-fetches `/auth/me` so counters (followers/following) reflect actions
/// taken elsewhere — including by other users.
final class ProfileRefreshRequested extends ProfileEvent {
  const ProfileRefreshRequested();
}

/// Emitted from the repository cache listener; must not write back to the
/// repository or the notifier would loop.
final class _ProfileCacheChanged extends ProfileEvent {
  const _ProfileCacheChanged(this.user);

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
    this.sectionsReady = true,
  });

  final UserProfile user;
  final List<CheckInItem> checkIns;
  final List<PulseItem> pulses;
  final List<StampItem> stamps;
  final List<PlanItem> plans;

  /// False while first section fetch is in flight — show shimmer, not empty.
  final bool sectionsReady;

  ProfileLoaded copyWith({
    UserProfile? user,
    List<CheckInItem>? checkIns,
    List<PulseItem>? pulses,
    List<StampItem>? stamps,
    List<PlanItem>? plans,
    bool? sectionsReady,
  }) {
    return ProfileLoaded(
      user: user ?? this.user,
      checkIns: checkIns ?? this.checkIns,
      pulses: pulses ?? this.pulses,
      stamps: stamps ?? this.stamps,
      plans: plans ?? this.plans,
      sectionsReady: sectionsReady ?? this.sectionsReady,
    );
  }

  @override
  List<Object?> get props => [
    user,
    checkIns,
    pulses,
    stamps,
    plans,
    sectionsReady,
  ];
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
    on<ProfileRefreshRequested>(_onRefreshRequested);
    on<_ProfileCacheChanged>(_onCacheChanged);
    _userRepository.currentUserListenable.addListener(_onCacheNotify);
  }

  final UserRepository _userRepository;

  void _onCacheNotify() {
    final cached = _userRepository.currentUserListenable.value;
    if (cached == null || isClosed) return;
    add(_ProfileCacheChanged(cached));
  }

  @override
  Future<void> close() {
    _userRepository.currentUserListenable.removeListener(_onCacheNotify);
    return super.close();
  }

  void _onCacheChanged(
    _ProfileCacheChanged event,
    Emitter<ProfileState> emit,
  ) {
    final currentState = state;
    if (currentState is! ProfileLoaded) return;
    if (currentState.user == event.user) return;
    emit(currentState.copyWith(user: event.user));
  }

  Future<void> _onRefreshRequested(
    ProfileRefreshRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final fresh = await _userRepository.getCurrentUser();
      final currentState = state;
      if (!emit.isDone && currentState is ProfileLoaded) {
        emit(currentState.copyWith(user: fresh));
      }
    } catch (_) {}
  }

  Future<void> _onStarted(
    ProfileStarted event,
    Emitter<ProfileState> emit,
  ) async {
    final cached = _userRepository.cachedCurrentUser;
    final hasCache = _userRepository.hasCachedProfile && cached != null;
    final previous = state is ProfileLoaded ? state as ProfileLoaded : null;
    final cachedPulses = _userRepository.peekMyPulses();
    final pulsesReady = _userRepository.hasFetchedMyPulses;

    if (hasCache) {
      // Paint instantly from profile + pulse cache; avoid empty-tab flicker.
      if (previous == null) {
        emit(
          ProfileLoaded(
            user: cached,
            checkIns: const [],
            pulses: cachedPulses,
            stamps: const [],
            plans: const [],
            sectionsReady: pulsesReady,
          ),
        );
      } else {
        emit(
          previous.copyWith(
            user: cached,
            pulses: cachedPulses.isNotEmpty ? cachedPulses : previous.pulses,
          ),
        );
      }

      final results = await Future.wait([
        _userRepository.getCheckIns(),
        _userRepository.getPulses(),
        _userRepository.getStamps(),
        _userRepository.getTodayPlans(),
      ]);
      if (!emit.isDone) {
        emit(
          ProfileLoaded(
            user: cached,
            checkIns: results[0] as List<CheckInItem>,
            pulses: results[1] as List<PulseItem>,
            stamps: results[2] as List<StampItem>,
            plans: results[3] as List<PlanItem>,
            sectionsReady: true,
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
      final results = await Future.wait([
        _userRepository.getCheckIns(),
        _userRepository.getPulses(),
        _userRepository.getStamps(),
        _userRepository.getTodayPlans(),
      ]);
      emit(
        ProfileLoaded(
          user: user,
          checkIns: results[0] as List<CheckInItem>,
          pulses: results[1] as List<PulseItem>,
          stamps: results[2] as List<StampItem>,
          plans: results[3] as List<PlanItem>,
          sectionsReady: true,
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
