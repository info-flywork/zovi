import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zovi/domain/chat/chat_repository.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/home/bloc/home_event.dart';
import 'package:zovi/presentation/home/bloc/home_state.dart';

final class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(this._userRepository, this._chatRepository)
    : super(const HomeInitial()) {
    on<HomeStarted>(_onStarted);
    on<HomeRefreshRequested>(_onRefresh);
    on<HomeStoriesRefreshRequested>(_onStoriesRefresh);
  }

  final UserRepository _userRepository;
  final ChatRepository _chatRepository;

  Future<bool> _unread() async {
    try {
      return (await _chatRepository.unreadCount()) > 0;
    } catch (_) {
      return false;
    }
  }

  Future<void> _hydrateProfile() async {
    try {
      await _userRepository.getCurrentUser();
    } catch (_) {}
  }

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    // Re-entering the tab must not blank the map — refresh in place instead.
    final current = state;
    if (current is HomeLoaded && !event.forceLoading) {
      await _refreshInPlace(current, emit);
      return;
    }

    final cachedStories = _userRepository.peekStories();
    final cachedFriends = _userRepository.mapFriendsListenable.value;
    // Splash `warmHomeBootstrap` leaves at least the "Your story" ring.
    final hasCache = cachedStories.isNotEmpty || cachedFriends.isNotEmpty;

    if (hasCache) {
      emit(
        HomeLoaded(
          stories: cachedStories,
          mapFriends: cachedFriends,
          hasUnreadMessages: current is HomeLoaded
              ? current.hasUnreadMessages
              : false,
        ),
      );
      // Splash az önce ısıttıysa tüm feed'i tekrar çekme — sadece unread.
      if (_userRepository.isHomeBootstrapFresh) {
        try {
          final hasUnreadMessages = await _unread();
          final loaded = state;
          if (loaded is HomeLoaded) {
            emit(loaded.copyWith(hasUnreadMessages: hasUnreadMessages));
          }
        } catch (_) {}
        return;
      }
      // Soft refresh — UI already painted from splash cache.
      await _refreshInPlace(
        state is HomeLoaded
            ? state as HomeLoaded
            : HomeLoaded(
                stories: cachedStories,
                mapFriends: cachedFriends,
                hasUnreadMessages: false,
              ),
        emit,
      );
      return;
    }

    emit(const HomeLoading());

    try {
      if (!_userRepository.hasCachedProfile) {
        await _hydrateProfile();
      }
      final results = await Future.wait<Object?>([
        _userRepository.getStories(),
        _userRepository.getMapFriends(),
        _unread(),
        _userRepository.restoreActiveMapCheckIn(),
      ]);

      final stories = results[0]! as List<StoryPreview>;
      final mapFriends = results[1]! as List<MapFriend>;
      final hasUnreadMessages = results[2]! as bool;

      emit(
        HomeLoaded(
          stories: stories,
          mapFriends: mapFriends,
          hasUnreadMessages: hasUnreadMessages,
        ),
      );
      _userRepository.warmStampCaches();
      _userRepository.warmMyPulsesCache();
    } catch (e) {
      if (state is! HomeLoaded) {
        emit(HomeError(message: e.toString()));
      }
    }
  }

  Future<void> _refreshInPlace(
    HomeLoaded current,
    Emitter<HomeState> emit,
  ) async {
    try {
      final results = await Future.wait<Object?>([
        _userRepository.getStories(),
        _userRepository.getMapFriends(),
        _unread(),
        _userRepository.restoreActiveMapCheckIn(),
      ]);
      emit(
        current.copyWith(
          stories: results[0]! as List<StoryPreview>,
          mapFriends: results[1]! as List<MapFriend>,
          hasUnreadMessages: results[2]! as bool,
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
