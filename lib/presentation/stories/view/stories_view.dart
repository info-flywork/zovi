import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/core/widgets/app_loading.dart';
import 'package:zovi/core/widgets/app_search_field.dart';
import 'package:zovi/core/widgets/bottom_navigation_bar/main_wrapper.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/stories/bloc/stories_bloc.dart';
import 'package:zovi/presentation/stories/bloc/stories_event.dart';
import 'package:zovi/presentation/stories/bloc/stories_state.dart';
import 'package:zovi/presentation/stories/model/story_detail_route_args.dart';

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
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onAddTap,
                    behavior: HitTestBehavior.opaque,
                    child: const AppIcon(AssetPaths.iconAddBlack, size: 28),
                  ),
                  Expanded(
                    child: Text(
                      'stories_title'.tr(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.pacifico(
                        fontSize: 32,
                        fontWeight: FontWeight.w400,
                        height: 36 / 32,
                        color: AppColors.deepRoast,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onSendTap,
                    behavior: HitTestBehavior.opaque,
                    child: const AppIcon(AssetPaths.iconSend, size: 28),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: AppSearchField(
                hintText: 'search_hint'.tr(),
                onDebouncedChanged: onSearchChanged,
              ),
            ),
            Expanded(
              child: BlocBuilder<StoriesBloc, StoriesState>(
                builder: (context, state) {
                  return switch (state) {
                    StoriesLoaded(:final items) => StoriesLoadedBody(
                      items: filteredItems(items),
                      onOpen: onOpenStory,
                    ),
                    _ => const AppLoading(),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
