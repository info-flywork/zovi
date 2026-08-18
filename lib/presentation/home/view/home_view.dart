import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:shimmer/shimmer.dart';
import 'package:zovi/core/deep_link/deep_link_service.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/in_app_notification/app_in_app_notification.dart';
import 'package:zovi/core/in_app_notification/in_app_notification_data.dart';
import 'package:zovi/core/snackbar/app_snackbar.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/theme/app_theme.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/utils/navigation/open_user_profile.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/core/widgets/app_loading.dart';
import 'package:zovi/core/widgets/bottom_navigation_bar/main_wrapper.dart';
import 'package:zovi/core/widgets/profile_avatar.dart';
import 'package:zovi/core/widgets/stamp_image.dart';
import 'package:zovi/domain/chat/chat_repository.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/home/bloc/home_bloc.dart';
import 'package:zovi/presentation/home/bloc/home_event.dart';
import 'package:zovi/presentation/home/bloc/home_state.dart';
import 'package:zovi/presentation/camera/model/camera_compose_route_args.dart';
import 'package:zovi/presentation/home/view/widgets/check_in_create_sheet.dart';
import 'package:zovi/presentation/home/view/widgets/first_check_in_sheet.dart';
import 'package:zovi/presentation/home/view/widgets/share_content_sheet.dart';
import 'package:zovi/presentation/stories/model/story_detail_route_args.dart';

part 'mixin/home_view_mixin.dart';
part 'widgets/home_error_body.dart';
part 'widgets/home_header_section.dart';
part 'widgets/home_loaded_body.dart';
part 'widgets/home_loading_body.dart';
part 'widgets/home_map_anon_marker.dart';
part 'widgets/home_map_check_in_marker.dart';
part 'widgets/home_map_cluster_marker.dart';
part 'widgets/home_map_friend_sheet.dart';
part 'widgets/home_map_last_check_in_sheet.dart';
part 'widgets/home_map_marker.dart';
part 'widgets/home_map_section.dart';
part 'widgets/home_map_venue_marker.dart';
part 'widgets/home_map_venue_sheet.dart';
part 'widgets/home_stories_row.dart';

@immutable
final class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

final class _HomeViewState extends State<HomeView>
    with HomeViewMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(const HomeStarted());
    unawaited(getIt<DeepLinkService>().markReadyAndFlush());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.white,
      resizeToAvoidBottomInset: false,
      body: BlocConsumer<HomeBloc, HomeState>(
        listener: (context, state) {
          if (state is HomeError) showErrorSnackbar(state.message);
        },
        buildWhen: (prev, next) {
          // Avoid full rebuild when only unread flips during background refresh.
          if (prev is HomeLoaded && next is HomeLoaded) {
            return prev.stories != next.stories ||
                prev.mapFriends != next.mapFriends ||
                prev.hasUnreadMessages != next.hasUnreadMessages;
          }
          return prev.runtimeType != next.runtimeType || prev != next;
        },
        builder: (context, state) {
          return switch (state) {
            HomeInitial() || HomeLoading() => const HomeLoadingBody(),
            HomeLoaded(
              :final stories,
              :final mapFriends,
              :final hasUnreadMessages,
            ) =>
              HomeLoadedBody(
                stories: stories,
                mapFriends: mapFriends,
                hasUnreadMessages: hasUnreadMessages,
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

