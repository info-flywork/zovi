import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/widgets/app_loading.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/stories/bloc/stories_bloc.dart';
import 'package:zovi/presentation/stories/bloc/stories_event.dart';
import 'package:zovi/presentation/stories/bloc/stories_state.dart';

part 'mixin/stories_view_mixin.dart';
part 'widgets/stories_loaded_body.dart';

class StoriesView extends StatefulWidget {
  const StoriesView({super.key});

  @override
  State<StoriesView> createState() => _StoriesViewState();
}

class _StoriesViewState extends State<StoriesView> with StoriesViewMixin {
  @override
  void initState() {
    super.initState();
    context.read<StoriesBloc>().add(const StoriesStarted());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text(
          'Stories',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<StoriesBloc, StoriesState>(
        builder: (context, state) {
          return switch (state) {
            StoriesLoaded(:final stories) => StoriesLoadedBody(
                stories: stories,
                onOpen: onOpenStory,
              ),
            _ => const AppLoading(),
          };
        },
      ),
    );
  }
}
