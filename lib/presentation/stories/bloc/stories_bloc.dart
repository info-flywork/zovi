import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/stories/bloc/stories_event.dart';
import 'package:zovi/presentation/stories/bloc/stories_state.dart';

final class StoriesBloc extends Bloc<StoriesEvent, StoriesState> {
  StoriesBloc(this._userRepository) : super(const StoriesInitial()) {
    on<StoriesStarted>(_onStarted);
    on<StoriesRefreshRequested>(_onRefresh);
  }

  final UserRepository _userRepository;

  Future<void> _onStarted(
    StoriesStarted event,
    Emitter<StoriesState> emit,
  ) async {
    final cached = _userRepository.peekStoryFeed();
    if (cached.isNotEmpty) {
      emit(StoriesLoaded(items: cached));
      if (_userRepository.isStoryFeedFresh) return;
    } else {
      emit(const StoriesLoading());
    }

    final items = await _userRepository.getStoryFeed();
    _emitIfGridChanged(emit, items);
  }

  Future<void> _onRefresh(
    StoriesRefreshRequested event,
    Emitter<StoriesState> emit,
  ) async {
    final cached = _userRepository.peekStoryFeed();
    if (cached.isNotEmpty) {
      emit(StoriesLoaded(items: cached));
      if (!event.force && _userRepository.isStoryFeedFresh) return;
    }
    final items = await _userRepository.getStoryFeed(
      forceRefresh: event.force,
    );
    _emitIfGridChanged(emit, items);
  }

  void _emitIfGridChanged(
    Emitter<StoriesState> emit,
    List<StoryMediaItem> items,
  ) {
    final current = state;
    if (current is StoriesLoaded && _sameGrid(current.items, items)) return;
    emit(StoriesLoaded(items: items));
  }

  static bool _sameGrid(List<StoryMediaItem> a, List<StoryMediaItem> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].storyId != b[i].storyId ||
          a[i].imagePath != b[i].imagePath ||
          a[i].isVideo != b[i].isVideo) {
        return false;
      }
    }
    return true;
  }
}
