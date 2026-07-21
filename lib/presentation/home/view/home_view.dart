import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/snackbar/app_snackbar.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/theme/app_theme.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/core/widgets/app_loading.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/home/bloc/home_bloc.dart';
import 'package:zovi/presentation/home/bloc/home_event.dart';
import 'package:zovi/presentation/home/bloc/home_state.dart';

part 'mixin/home_view_mixin.dart';
part 'widgets/home_loading_body.dart';
part 'widgets/home_loaded_body.dart';
part 'widgets/home_error_body.dart';
part 'widgets/home_header_section.dart';
part 'widgets/home_stories_row.dart';
part 'widgets/home_map_section.dart';
part 'widgets/home_map_marker.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with HomeViewMixin {
  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(const HomeStarted());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: BlocConsumer<HomeBloc, HomeState>(
        listener: (context, state) {
          if (state is HomeError) showErrorSnackbar(state.message);
        },
        builder: (context, state) {
          return switch (state) {
            HomeInitial() || HomeLoading() => const HomeLoadingBody(),
            HomeLoaded(:final stories, :final mapFriends, :final city) =>
              HomeLoadedBody(
                stories: stories,
                mapFriends: mapFriends,
                city: city,
                onStoryTap: onStoryTap,
                onAddTap: onAddTap,
              ),
            HomeError(:final message) => HomeErrorBody(message: message),
          };
        },
      ),
    );
  }
}
