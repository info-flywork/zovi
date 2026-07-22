import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/stories/bloc/stories_event.dart';
import 'package:zovi/presentation/stories/bloc/stories_state.dart';

class StoriesBloc extends Bloc<StoriesEvent, StoriesState> {
  StoriesBloc(this._userRepository) : super(const StoriesInitial()) {
    on<StoriesStarted>((event, emit) async {
      emit(const StoriesLoading());
      final items = await _userRepository.getStoryFeed();
      emit(StoriesLoaded(items: items));
    });
  }

  final UserRepository _userRepository;
}
