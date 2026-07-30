import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/home/bloc/home_event.dart';
import 'package:zovi/presentation/home/bloc/home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(this._userRepository) : super(const HomeInitial()) {
    on<HomeStarted>(_onStarted);
    on<HomeRefreshRequested>(_onRefresh);
    on<HomeStoriesRefreshRequested>(_onStoriesRefresh);
  }

  final UserRepository _userRepository;

  Future<void> _onStarted(
    HomeStarted event,
    Emitter<HomeState> emit,
  ) async {
    // Re-entering the tab must not blank the map — refresh in place instead.
    final current = state;
    if (current is HomeLoaded && !event.forceLoading) {
      await _refreshInPlace(current, emit);
      return;
    }

    emit(const HomeLoading());
    try {
      try {
        await _userRepository.getCurrentUser();
      } catch (_) {}
      final stories = await _userRepository.getStories();
      final mapFriends = await _userRepository.getMapFriends();
      final hasUnreadMessages = await _userRepository.hasUnreadMessages();
      emit(
        HomeLoaded(
          stories: stories,
          mapFriends: mapFriends,
          hasUnreadMessages: hasUnreadMessages,
        ),
      );
      _userRepository.warmStampCaches();
    } catch (e) {
      emit(HomeError(message: e.toString()));
    }
  }

  Future<void> _refreshInPlace(
    HomeLoaded current,
    Emitter<HomeState> emit,
  ) async {
    try {
      final stories = await _userRepository.getStories();
      final mapFriends = await _userRepository.getMapFriends();
      final hasUnreadMessages = await _userRepository.hasUnreadMessages();
      emit(
        current.copyWith(
          stories: stories,
          mapFriends: mapFriends,
          hasUnreadMessages: hasUnreadMessages,
        ),
      );
    } catch (_) {
      // Keep showing the last good state.
    }
  }

  Future<void> _onRefresh(
    HomeRefreshRequested event,
    Emitter<HomeState> emit,
  ) async {
    add(const HomeStarted(forceLoading: true));
  }

  Future<void> _onStoriesRefresh(
    HomeStoriesRefreshRequested event,
    Emitter<HomeState> emit,
  ) async {
    var current = state;
    if (current is! HomeLoaded) return;

    // Paint the local viewed state first, then reconcile with the server.
    final cached = _userRepository.peekStories();
    if (cached.isNotEmpty) {
      current = current.copyWith(stories: cached);
      emit(current);
    }

    final stories = await _userRepository.getStories();
    emit(current.copyWith(stories: stories));
  }
}
