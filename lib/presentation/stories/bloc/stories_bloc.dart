import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zovi/core/cache/stamp_image_cache.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/stories/bloc/stories_event.dart';
import 'package:zovi/presentation/stories/bloc/stories_state.dart';

class StoriesBloc extends Bloc<StoriesEvent, StoriesState> {
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
      // Soft refresh in place — keep tiles on screen.
      final items = await _userRepository.getStoryFeed(forceRefresh: true);
      emit(StoriesLoaded(items: items));
      _prefetchThumbnails(items);
      return;
    }

    emit(const StoriesLoading());
    final items = await _userRepository.getStoryFeed();
    emit(StoriesLoaded(items: items));
    _prefetchThumbnails(items);
  }

  Future<void> _onRefresh(
    StoriesRefreshRequested event,
    Emitter<StoriesState> emit,
  ) async {
    final cached = _userRepository.peekStoryFeed();
    if (cached.isNotEmpty) {
      emit(StoriesLoaded(items: cached));
    }
    final items = await _userRepository.getStoryFeed(forceRefresh: true);
    emit(StoriesLoaded(items: items));
    _prefetchThumbnails(items);
  }

  void _prefetchThumbnails(List<StoryMediaItem> items) {
    final cache = getIt<StampImageCache>();
    for (final item in items.take(30)) {
      if (!item.isNetworkImage) continue;
      unawaited(
        cache.prefetch(
          stampId: item.storyId ?? item.imagePath,
          url: item.imagePath,
        ),
      );
    }
  }
}
