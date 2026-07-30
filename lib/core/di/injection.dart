import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zovi/core/cache/music_audio_cache.dart';
import 'package:zovi/core/cache/music_catalog_cache.dart';
import 'package:zovi/core/cache/stamp_catalog_cache.dart';
import 'package:zovi/core/cache/stamp_image_cache.dart';
import 'package:zovi/core/cache/story_catalog_cache.dart';
import 'package:zovi/core/cache/story_draft_cache.dart';
import 'package:zovi/core/deep_link/deep_link_service.dart';
import 'package:zovi/core/managers/auth_cache_manager.dart';
import 'package:zovi/core/managers/shared_pref_manager.dart';
import 'package:zovi/core/network/dio_client.dart';
import 'package:zovi/core/network/network_manager.dart';
import 'package:zovi/domain/auth/auth_repository.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/auth/create_profile/bloc/create_profile_bloc.dart';
import 'package:zovi/presentation/auth/intro/bloc/intro_bloc.dart';
import 'package:zovi/presentation/auth/onboarding/bloc/onboarding_bloc.dart';
import 'package:zovi/presentation/auth/splash/bloc/splash_bloc.dart';
import 'package:zovi/presentation/chat/bloc/chat_bloc.dart';
import 'package:zovi/presentation/discover/bloc/discover_bloc.dart';
import 'package:zovi/presentation/home/bloc/home_bloc.dart';
import 'package:zovi/presentation/profile/bloc/profile_bloc.dart';
import 'package:zovi/presentation/stories/bloc/stories_bloc.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  if (getIt.isRegistered<CreateProfileBloc>()) {
    await getIt.unregister<CreateProfileBloc>();
  }

  if (getIt.isRegistered<AuthRepository>()) return;

  final prefs = await SharedPreferences.getInstance();

  getIt
    ..registerLazySingleton(
      () => AuthCacheManager(const FlutterSecureStorage()),
    )
    ..registerLazySingleton(() => DioClient.create(getIt()))
    ..registerLazySingleton(() => NetworkManager(getIt()))
    ..registerLazySingleton(() => SharedPrefManager(prefs))
    ..registerLazySingleton(MusicCatalogCache.new)
    ..registerLazySingleton(() => MusicAudioCache(getIt()))
    ..registerLazySingleton(StampCatalogCache.new)
    ..registerLazySingleton(StampImageCache.new)
    ..registerLazySingleton(StoryCatalogCache.new)
    ..registerLazySingleton(StoryDraftCache.new)
    ..registerLazySingleton(
      () => AuthRepository(
        getIt(),
        getIt(),
        getIt(),
        musicCatalogCache: getIt(),
        stampCatalogCache: getIt(),
        storyCatalogCache: getIt(),
        stampImageCache: getIt(),
        storyDraftCache: getIt(),
      ),
    )
    ..registerLazySingleton(() => UserRepository(getIt()))
    ..registerLazySingleton(() => DeepLinkService(getIt()))
    ..registerFactory(() => SplashBloc(getIt(), getIt()))
    ..registerFactory(() => IntroBloc(getIt()))
    ..registerFactory(() => OnboardingBloc(getIt()))
    ..registerLazySingleton(() => HomeBloc(getIt()))
    ..registerLazySingleton(() => StoriesBloc(getIt()))
    ..registerFactory(() => ChatBloc())
    ..registerLazySingleton(() => ProfileBloc(getIt()))
    ..registerFactory(() => DiscoverBloc());
}

/// Blocs kept as singletons hold the signed-in user's data — drop them on
/// logout so the next account starts from a clean state.
Future<void> resetUserScopedSingletons() async {
  if (getIt.isRegistered<HomeBloc>()) {
    await getIt.resetLazySingleton<HomeBloc>();
  }
  if (getIt.isRegistered<StoriesBloc>()) {
    await getIt.resetLazySingleton<StoriesBloc>();
  }
  if (getIt.isRegistered<ProfileBloc>()) {
    await getIt.resetLazySingleton<ProfileBloc>();
  }
}
