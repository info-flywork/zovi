import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/presentation/discover/bloc/discover_bloc.dart';

part 'mixin/discover_view_mixin.dart';
part 'widgets/discover_loaded_body.dart';

class DiscoverView extends StatefulWidget {
  const DiscoverView({super.key});

  @override
  State<DiscoverView> createState() => _DiscoverViewState();
}

class _DiscoverViewState extends State<DiscoverView> with DiscoverViewMixin {
  @override
  void initState() {
    super.initState();
    context.read<DiscoverBloc>().add(const DiscoverStarted());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0A03),
      body: BlocBuilder<DiscoverBloc, DiscoverState>(
        builder: (context, state) {
          if (state is DiscoverLoaded) {
            return DiscoverLoadedBody(
              name: state.name,
              caption: state.caption,
              onClose: onClose,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
