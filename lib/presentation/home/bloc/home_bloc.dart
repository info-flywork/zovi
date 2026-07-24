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
    emit(const HomeLoading());
    try {
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
    } catch (e) {
      emit(HomeError(message: e.toString()));
    }
  }

  Future<void> _onRefresh(
    HomeRefreshRequested event,
    Emitter<HomeState> emit,
  ) async {
    add(const HomeStarted());
  }

  Future<void> _onStoriesRefresh(
    HomeStoriesRefreshRequested event,
    Emitter<HomeState> emit,
  ) async {
    final current = state;
    if (current is! HomeLoaded) return;
    final stories = await _userRepository.getStories();
    emit(current.copyWith(stories: stories));
  }
}
