import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/stories/bloc/stories_event.dart';
import 'package:zovi/presentation/stories/bloc/stories_state.dart';

class StoriesBloc extends Bloc<StoriesEvent, StoriesState> {
  StoriesBloc(this._userRepository) : super(const StoriesInitial()) {
    on<StoriesStarted>((event, emit) async {
      emit(const StoriesLoading());
      final stories = await _userRepository.getStories();
      emit(StoriesLoaded(stories: stories.where((s) => !s.isYou).toList()));
    });
  }

  final UserRepository _userRepository;
}
