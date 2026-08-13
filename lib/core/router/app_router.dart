import 'package:flutter/cupertino.dart' show CupertinoPage;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/domain/auth/auth_repository.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/widgets/bottom_navigation_bar/main_wrapper.dart';
import 'package:zovi/presentation/auth/intro/bloc/intro_bloc.dart';
import 'package:zovi/presentation/auth/intro/view/intro_view.dart';
import 'package:zovi/presentation/auth/onboarding/bloc/onboarding_bloc.dart';
import 'package:zovi/presentation/auth/onboarding/view/onboarding_view.dart';
import 'package:zovi/presentation/auth/otp/bloc/otp_bloc.dart';
import 'package:zovi/presentation/auth/otp/model/otp_route_args.dart';
import 'package:zovi/presentation/auth/otp/view/otp_view.dart';
import 'package:zovi/presentation/auth/birthday/bloc/birthday_bloc.dart';
import 'package:zovi/presentation/auth/birthday/model/birthday_route_args.dart';
import 'package:zovi/presentation/auth/birthday/view/birthday_view.dart';
import 'package:zovi/presentation/auth/create_profile/bloc/create_profile_bloc.dart';
import 'package:zovi/presentation/auth/create_profile/model/create_profile_route_args.dart';
import 'package:zovi/presentation/auth/create_profile/view/create_profile_view.dart';
import 'package:zovi/presentation/auth/location_permission/bloc/location_permission_bloc.dart';
import 'package:zovi/presentation/auth/location_permission/view/location_permission_view.dart';
import 'package:zovi/presentation/auth/notification_permission/bloc/notification_permission_bloc.dart';
import 'package:zovi/presentation/auth/notification_permission/model/notification_permission_route_args.dart';
import 'package:zovi/presentation/auth/notification_permission/view/notification_permission_view.dart';
import 'package:zovi/presentation/auth/phone_verified/view/phone_verified_view.dart';
import 'package:zovi/presentation/auth/splash/bloc/splash_bloc.dart';
import 'package:zovi/presentation/auth/splash/view/splash_view.dart';
import 'package:zovi/presentation/camera/model/camera_compose_route_args.dart';
import 'package:zovi/presentation/camera/view/camera_compose_view.dart';
import 'package:zovi/presentation/camera/view/camera_view.dart';
import 'package:zovi/presentation/chat/bloc/chat_bloc.dart';
import 'package:zovi/presentation/chat/model/chat_detail_route_args.dart';
import 'package:zovi/presentation/chat/model/chat_request_item.dart';
import 'package:zovi/presentation/chat/model/group_info_route_args.dart';
import 'package:zovi/presentation/chat/view/chat_detail_view.dart';
import 'package:zovi/presentation/chat/view/chat_requests_view.dart';
import 'package:zovi/presentation/chat/view/chat_view.dart';
import 'package:zovi/presentation/chat/view/group_gallery_view.dart';
import 'package:zovi/presentation/chat/view/group_info_view.dart';
import 'package:zovi/presentation/home/bloc/home_bloc.dart';
import 'package:zovi/presentation/home/model/check_in_success_route_args.dart';
import 'package:zovi/presentation/home/view/check_in_success_view.dart';
import 'package:zovi/presentation/home/view/home_view.dart';
import 'package:zovi/presentation/home/view/lifestyle_streak_view.dart';
import 'package:zovi/presentation/home/view/tribe_view.dart';
import 'package:zovi/presentation/notifications/view/notifications_view.dart';
import 'package:zovi/presentation/profile/bloc/profile_bloc.dart';
import 'package:zovi/presentation/profile/connections/model/profile_connections_route_args.dart';
import 'package:zovi/presentation/profile/connections/view/profile_connections_view.dart';
import 'package:zovi/presentation/profile/user_profile/model/user_profile_route_args.dart';
import 'package:zovi/presentation/profile/user_profile/view/user_profile_view.dart';
import 'package:zovi/presentation/profile/user_profile/view/public_profile_loader_view.dart';
import 'package:zovi/presentation/profile/edit/model/edit_profile_field_route_args.dart';
import 'package:zovi/presentation/profile/edit/model/edit_profile_links_route_args.dart';
import 'package:zovi/presentation/profile/edit/model/edit_profile_route_args.dart';
import 'package:zovi/presentation/profile/edit/view/add_profile_link_view.dart';
import 'package:zovi/presentation/profile/edit/view/edit_profile_field_view.dart';
import 'package:zovi/presentation/profile/edit/view/edit_profile_links_view.dart';
import 'package:zovi/presentation/profile/edit/view/edit_profile_view.dart';
import 'package:zovi/presentation/profile/add_plan/model/add_plan_details_route_args.dart';
import 'package:zovi/presentation/profile/add_plan/model/add_plan_success_route_args.dart';
import 'package:zovi/presentation/profile/add_plan/view/add_plan_view.dart';
import 'package:zovi/presentation/profile/add_plan/view/add_plan_details_view.dart';
import 'package:zovi/presentation/profile/add_plan/view/add_plan_success_view.dart';
import 'package:zovi/presentation/profile/settings/view/change_password_view.dart';
import 'package:zovi/presentation/profile/settings/view/personal_info_view.dart';
import 'package:zovi/presentation/profile/settings/view/settings_view.dart';
import 'package:zovi/presentation/profile/stickers/view/create_sticker_success_view.dart';
import 'package:zovi/presentation/profile/stickers/view/create_sticker_view.dart';
import 'package:zovi/presentation/profile/stickers/view/stickers_view.dart';
import 'package:zovi/presentation/profile/view/profile_view.dart';
import 'package:zovi/presentation/stories/bloc/stories_bloc.dart';
import 'package:zovi/presentation/stories/model/story_detail_route_args.dart';
import 'package:zovi/presentation/stories/view/stories_view.dart';
import 'package:zovi/presentation/stories/view/story_detail_view.dart';

abstract final class AppRouter {
  static final GlobalKey<NavigatorState> rootKey = GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> shellKey = GlobalKey<NavigatorState>();

  /// Firebase phone auth reCAPTCHA callback deep link — native SDK handles it.
  static bool _isFirebaseAuthCallback(Uri uri) {
    final raw = uri.toString();
    if (raw.contains('firebaseauth') ||
        raw.contains('recaptchaToken') ||
        raw.contains('__/auth/callback') ||
        uri.host == 'firebaseauth' ||
        uri.scheme.startsWith('com.googleusercontent.apps')) {
      return true;
    }
    // Flutter sometimes strips the custom scheme → `/link?...`
    if (uri.path == '/link' || uri.path.endsWith('/link')) {
      final q = uri.queryParameters;
      if (q.containsKey('deep_link_id') || q.containsKey('recaptchaToken')) {
        return true;
      }
    }
    return false;
  }

  static final GoRouter router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: RoutePaths.splash.path,
    onException: (context, state, router) {
      // Keep current screen; Firebase Auth consumes the URL natively.
      if (_isFirebaseAuthCallback(state.uri)) return;
    },
    routes: [
      GoRoute(
        path: RoutePaths.splash.path,
        name: RoutePaths.splash.name,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<SplashBloc>(),
          child: const SplashView(),
        ),
      ),
      GoRoute(
        path: RoutePaths.intro.path,
        name: RoutePaths.intro.name,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<IntroBloc>(),
          child: const IntroView(),
        ),
      ),
      GoRoute(
        path: RoutePaths.onboarding.path,
        name: RoutePaths.onboarding.name,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<OnboardingBloc>(),
          child: const OnboardingView(),
        ),
      ),
      GoRoute(
        path: RoutePaths.otp.path,
        name: RoutePaths.otp.name,
        redirect: (context, state) {
          if (state.extra is! OtpRouteArgs) {
            return RoutePaths.onboarding.path;
          }
          return null;
        },
        builder: (context, state) {
          final args = state.extra! as OtpRouteArgs;
          return BlocProvider(
            create: (_) => OtpBloc(
              getIt(),
              phone: args.phone,
              selectedCountry: args.selectedCountry,
            ),
            child: const OtpView(),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.phoneVerified.path,
        name: RoutePaths.phoneVerified.name,
        builder: (context, state) => const PhoneVerifiedView(),
      ),
      GoRoute(
        path: RoutePaths.createProfile.path,
        name: RoutePaths.createProfile.name,
        redirect: (context, state) {
          if (state.extra is! CreateProfileRouteArgs) {
            return RoutePaths.onboarding.path;
          }
          return null;
        },
        builder: (context, state) {
          final args = state.extra! as CreateProfileRouteArgs;
          return BlocProvider(
            create: (_) => CreateProfileBloc(
              signupFlow: args.signupFlow,
              authRepository: getIt(),
            ),
            child: CreateProfileView(signupFlow: args.signupFlow),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.birthday.path,
        name: RoutePaths.birthday.name,
        redirect: (context, state) {
          if (state.extra is! BirthdayRouteArgs) {
            return RoutePaths.onboarding.path;
          }
          return null;
        },
        builder: (context, state) {
          final args = state.extra! as BirthdayRouteArgs;
          return BlocProvider(
            create: (_) => BirthdayBloc(
              signupFlow: args.signupFlow,
              authRepository: getIt(),
            ),
            child: BirthdayView(signupFlow: args.signupFlow),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.notificationPermission.path,
        name: RoutePaths.notificationPermission.name,
        redirect: (context, state) {
          if (state.extra is! NotificationPermissionRouteArgs) {
            return RoutePaths.onboarding.path;
          }
          return null;
        },
        builder: (context, state) {
          final args = state.extra! as NotificationPermissionRouteArgs;
          return BlocProvider(
            create: (_) =>
                NotificationPermissionBloc(signupFlow: args.signupFlow),
            child: const NotificationPermissionView(),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.locationPermission.path,
        name: RoutePaths.locationPermission.name,
        builder: (context, state) => BlocProvider(
          create: (_) => LocationPermissionBloc(getIt<AuthRepository>()),
          child: const LocationPermissionView(),
        ),
      ),
      GoRoute(
        path: RoutePaths.checkInSuccess.path,
        name: RoutePaths.checkInSuccess.name,
        redirect: (context, state) {
          if (state.extra is! CheckInSuccessRouteArgs) {
            return RoutePaths.home.path;
          }
          return null;
        },
        builder: (context, state) {
          final args = state.extra! as CheckInSuccessRouteArgs;
          return CheckInSuccessView(args: args);
        },
      ),
      GoRoute(
        path: RoutePaths.lifestyleStreak.path,
        name: RoutePaths.lifestyleStreak.name,
        builder: (context, state) => const LifestyleStreakView(),
      ),
      GoRoute(
        path: RoutePaths.camera.path,
        name: RoutePaths.camera.name,
        builder: (context, state) => const CameraView(),
      ),
      GoRoute(
        path: RoutePaths.cameraCompose.path,
        name: RoutePaths.cameraCompose.name,
        redirect: (context, state) {
          if (state.extra is! CameraComposeRouteArgs) {
            return RoutePaths.camera.path;
          }
          return null;
        },
        builder: (context, state) {
          final args = state.extra! as CameraComposeRouteArgs;
          return CameraComposeView(args: args);
        },
      ),
      // IndexedStack keeps each tab (notably the live map) mounted, so
      // switching tabs never re-initialises it.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainWrapper(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: shellKey,
            routes: [
              GoRoute(
                path: RoutePaths.home.path,
                name: RoutePaths.home.name,
                builder: (context, state) => BlocProvider.value(
                  value: getIt<HomeBloc>(),
                  child: const HomeView(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.stories.path,
                name: RoutePaths.stories.name,
                builder: (context, state) => BlocProvider.value(
                  value: getIt<StoriesBloc>(),
                  child: const StoriesView(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.chat.path,
                name: RoutePaths.chat.name,
                builder: (context, state) => BlocProvider(
                  create: (_) => getIt<ChatBloc>(),
                  child: const ChatView(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.profile.path,
                name: RoutePaths.profile.name,
                builder: (context, state) => BlocProvider.value(
                  value: getIt<ProfileBloc>(),
                  child: const ProfileView(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.storyDetail.path,
        name: RoutePaths.storyDetail.name,
        redirect: (context, state) {
          if (state.extra is! StoryDetailRouteArgs) {
            return RoutePaths.stories.path;
          }
          return null;
        },
        pageBuilder: (context, state) {
          final args = state.extra! as StoryDetailRouteArgs;
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: StoryDetailView(args: args),
            transitionDuration: const Duration(milliseconds: 280),
            reverseTransitionDuration: const Duration(milliseconds: 220),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              final curved = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              );
              return FadeTransition(
                opacity: curved,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.88, end: 1).animate(curved),
                  child: child,
                ),
              );
            },
          );
        },
      ),
      GoRoute(
        path: RoutePaths.profileConnections.path,
        name: RoutePaths.profileConnections.name,
        redirect: (context, state) {
          if (state.extra is! ProfileConnectionsRouteArgs) {
            return RoutePaths.profile.path;
          }
          return null;
        },
        builder: (context, state) {
          final args = state.extra! as ProfileConnectionsRouteArgs;
          return ProfileConnectionsView(args: args);
        },
      ),
      GoRoute(
        path: RoutePaths.userProfile.path,
        name: RoutePaths.userProfile.name,
        redirect: (context, state) {
          if (state.extra is! UserProfileRouteArgs) {
            return RoutePaths.profile.path;
          }
          return null;
        },
        builder: (context, state) {
          final args = state.extra! as UserProfileRouteArgs;
          return UserProfileView(args: args);
        },
      ),
      GoRoute(
        path: '/u/:username',
        name: RoutePaths.publicProfile.name,
        builder: (context, state) {
          final username = state.pathParameters['username'] ?? '';
          return PublicProfileLoaderView(username: username);
        },
      ),
      GoRoute(
        path: RoutePaths.editProfile.path,
        name: RoutePaths.editProfile.name,
        redirect: (context, state) {
          if (state.extra is! EditProfileRouteArgs) {
            return RoutePaths.profile.path;
          }
          return null;
        },
        builder: (context, state) {
          final args = state.extra! as EditProfileRouteArgs;
          return EditProfileView(user: args.user);
        },
      ),
      GoRoute(
        path: RoutePaths.editProfileField.path,
        name: RoutePaths.editProfileField.name,
        redirect: (context, state) {
          if (state.extra is! EditProfileFieldRouteArgs) {
            return RoutePaths.profile.path;
          }
          return null;
        },
        builder: (context, state) {
          final args = state.extra! as EditProfileFieldRouteArgs;
          return EditProfileFieldView(
            field: args.field,
            initialValue: args.initialValue,
          );
        },
      ),
      GoRoute(
        path: RoutePaths.editProfileLinks.path,
        name: RoutePaths.editProfileLinks.name,
        redirect: (context, state) {
          if (state.extra is! EditProfileLinksRouteArgs) {
            return RoutePaths.profile.path;
          }
          return null;
        },
        builder: (context, state) {
          final args = state.extra! as EditProfileLinksRouteArgs;
          return EditProfileLinksView(links: args.links);
        },
      ),
      GoRoute(
        path: RoutePaths.addProfileLink.path,
        name: RoutePaths.addProfileLink.name,
        builder: (context, state) {
          final links = state.extra;
          return AddProfileLinkView(
            existingLinks: links is List<ProfileLink> ? links : const [],
          );
        },
      ),
      GoRoute(
        path: RoutePaths.addPlan.path,
        name: RoutePaths.addPlan.name,
        builder: (context, state) => const AddPlanView(),
      ),
      GoRoute(
        path: RoutePaths.addPlanDetails.path,
        name: RoutePaths.addPlanDetails.name,
        redirect: (context, state) {
          if (state.extra is! AddPlanDetailsRouteArgs) {
            return RoutePaths.addPlan.path;
          }
          return null;
        },
        builder: (context, state) {
          final args = state.extra! as AddPlanDetailsRouteArgs;
          return AddPlanDetailsView(place: args.place);
        },
      ),
      GoRoute(
        path: RoutePaths.addPlanSuccess.path,
        name: RoutePaths.addPlanSuccess.name,
        redirect: (context, state) {
          if (state.extra is! AddPlanSuccessRouteArgs) {
            return RoutePaths.profile.path;
          }
          return null;
        },
        builder: (context, state) {
          final args = state.extra! as AddPlanSuccessRouteArgs;
          return AddPlanSuccessView(
            friendAvatars: args.place.friendAvatars,
            friendsLabel: args.place.friendsLabel,
            showToFriends: args.showToFriends,
            showToNearby: args.showToNearby,
          );
        },
      ),
      GoRoute(
        path: RoutePaths.settings.path,
        name: RoutePaths.settings.name,
        builder: (context, state) => SettingsView(),
      ),
      GoRoute(
        path: RoutePaths.stickers.path,
        name: RoutePaths.stickers.name,
        builder: (context, state) => const StickersView(),
      ),
      GoRoute(
        path: RoutePaths.createSticker.path,
        name: RoutePaths.createSticker.name,
        builder: (context, state) => const CreateStickerView(),
      ),
      GoRoute(
        path: RoutePaths.createStickerSuccess.path,
        name: RoutePaths.createStickerSuccess.name,
        builder: (context, state) => const CreateStickerSuccessView(),
      ),
      GoRoute(
        path: RoutePaths.chatDetail.path,
        name: RoutePaths.chatDetail.name,
        redirect: (context, state) {
          if (state.extra is! ChatDetailRouteArgs) {
            return RoutePaths.chat.path;
          }
          return null;
        },
        pageBuilder: (context, state) {
          final args = state.extra! as ChatDetailRouteArgs;
          return CupertinoPage<String?>(
            key: state.pageKey,
            name: state.name,
            child: ChatDetailView(args: args),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.chatRequests.path,
        name: RoutePaths.chatRequests.name,
        redirect: (context, state) {
          if (state.extra is! ChatRequestsRouteArgs) {
            return RoutePaths.chat.path;
          }
          return null;
        },
        pageBuilder: (context, state) {
          final args = state.extra! as ChatRequestsRouteArgs;
          return CupertinoPage<List<ChatRequestItem>>(
            key: state.pageKey,
            name: state.name,
            child: ChatRequestsView(requests: args.requests),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.groupInfo.path,
        name: RoutePaths.groupInfo.name,
        redirect: (context, state) {
          if (state.extra is! GroupInfoRouteArgs) {
            return RoutePaths.chat.path;
          }
          return null;
        },
        builder: (context, state) {
          final args = state.extra! as GroupInfoRouteArgs;
          return GroupInfoView(args: args);
        },
      ),
      GoRoute(
        path: RoutePaths.groupGallery.path,
        name: RoutePaths.groupGallery.name,
        redirect: (context, state) {
          if (state.extra is! GroupInfoRouteArgs) {
            return RoutePaths.chat.path;
          }
          return null;
        },
        builder: (context, state) {
          final args = state.extra! as GroupInfoRouteArgs;
          return GroupGalleryView(args: args);
        },
      ),
      GoRoute(
        path: RoutePaths.personalInfo.path,
        name: RoutePaths.personalInfo.name,
        builder: (context, state) => const PersonalInfoView(),
      ),
      GoRoute(
        path: RoutePaths.changePassword.path,
        name: RoutePaths.changePassword.name,
        builder: (context, state) => const ChangePasswordView(),
      ),
      GoRoute(
        path: RoutePaths.tribe.path,
        name: RoutePaths.tribe.name,
        builder: (context, state) => const TribeView(),
      ),
      GoRoute(
        path: RoutePaths.notifications.path,
        name: RoutePaths.notifications.name,
        builder: (context, state) => const NotificationsView(),
      ),
    ],
  );
}
